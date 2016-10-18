//
//  RFRoomListTableViewController.swift
//  RoomFinderSwift
//
//  Created by Jing Wang on 3/28/16.
//  Copyright © 2016 Jing Wang. All rights reserved.
//

import UIKit

enum parseType {
    case foundNone
    case foundName
    case foundEmail
    case foundAvailability
}

class RFRoomListTableViewController : UITableViewController, NSXMLParserDelegate {
    private var locations = NSMutableArray()
    private var emails = NSMutableArray()
    var CompletionHandler : (NSData?, NSURLResponse?, NSError?) -> Void = { (data: NSData?,response: NSURLResponse?,error: NSError?) -> Void in }
    var parseFound : parseType = parseType.foundNone
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.topViewController?.title = "Locations"
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if( locations.count == 0 || emails.count == 0 ) {
            locations = NSMutableArray()
            emails = NSMutableArray()
            initCompletionHandler()
            RFSoap.shareInstance.sendRequestGetRoomlist(CompletionHandler)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initCompletionHandler() {
        CompletionHandler = { (data: NSData?,response: NSURLResponse?,error: NSError?) -> Void in
            if( error != nil) {
                RFCredential.shareInstance.setCredential("", pw: "")
                var errorDesc = "some unknown error occured"
                if error?.localizedDescription != nil {
                    errorDesc = (error?.localizedDescription)!
                }
               self.showTryAgainAlert("Error", message:errorDesc)
                
            } else if( (response as! NSHTTPURLResponse).statusCode != 200 ) {
                RFCredential.shareInstance.setCredential("", pw: "")
                let message = NSHTTPURLResponse .localizedStringForStatusCode((response as! NSHTTPURLResponse).statusCode)
                self.showTryAgainAlert("Error", message: message)
            } else {
                NSLog("Get Roomlist Success")
                if let recievedDate = data {
                    NSLog("Start Parser")
                    let parser : NSXMLParser = NSXMLParser.init(data: recievedDate)
                    parser.delegate = self
                    parser.shouldResolveExternalEntities = true
                    parser.parse()
                } else {
                    NSLog("No Data recieved")
                }
            }
        }
    }
    
    func showTryAgainAlert(title:String, message:String) {
        dispatch_async(dispatch_get_main_queue(), {
            
            let alertViewController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Default) { (action) -> Void in
                RFSoap.shareInstance.sendRequestGetRoomlist(self.CompletionHandler)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) -> Void in
                //do nothing
            }
            alertViewController.addAction(okAction)
            alertViewController.addAction(cancelAction)
            self.presentViewController(alertViewController, animated: true, completion: nil)
        })
    }

// MARK: - Table view data source
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CellOfLocations", forIndexPath: indexPath)
        self.configureCell(cell, indexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, indexPath: NSIndexPath ) {
        cell.textLabel?.text = locations.objectAtIndex(indexPath.row) as? String
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        dispatch_async(dispatch_get_main_queue(), {
            let roomsVC = self.storyboard?.instantiateViewControllerWithIdentifier("roomsTableViewController") as! RFRoomsTableViewController
            roomsVC.location = self.emails[indexPath.row] as! String 
            self.showViewController(roomsVC, sender: nil)
        })
    }
    
// MARK: - parser
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if( elementName == "t:Name" ) {
            parseFound = parseType.foundName
        } else if ( elementName == "t:EmailAddress" ) {
            parseFound = parseType.foundEmail
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        switch( parseFound ) {
        case .foundName:
            locations.addObject(string)
            break
        case .foundEmail:
            emails.addObject(string)
            break
        default:
            break
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        parseFound = .foundNone
    }
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        NSLog("parse failed : %s ", parseError.localizedDescription)
    }
    
    func parserDidEndDocument(parser: NSXMLParser) {
        NSLog("parse DONE!")
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        })
    }
}


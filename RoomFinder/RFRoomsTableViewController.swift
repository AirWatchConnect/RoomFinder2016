//
//  RFRoomsTableViewController.swift
//  RoomFinderSwift
//
//  Created by Jing Wang on 3/28/16.
//  Copyright © 2016 Jing Wang. All rights reserved.
//

import UIKit

class RFRoomsTableViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate, NSXMLParserDelegate {
    
    var location = String()
    @IBOutlet weak var tableView: UITableView!
    var CompletionHandler : (NSData?, NSURLResponse?, NSError?) -> Void = { (data: NSData?,response: NSURLResponse?,error: NSError?) -> Void in }
    
    private var rooms = NSMutableArray()
    private var emails = NSMutableArray()
    private var availibilities = NSMutableArray()
    private var waitTime = NSMutableArray()
    
    private var currentDate = NSDate()
    private var startDate = NSDate()
    
    var parseFound : parseType = parseType.foundNone
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self;
        tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.dataSource = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.topViewController?.title = "Rooms"
        
        if ( rooms.count == 0 ) {
            initCompletionHandler()
            RFSoap.shareInstance.sendRequestGetRooms(location, block: CompletionHandler)
        }
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
                NSLog("Get Rooms Success")
                if let recievedDate = data {
                    NSLog("Start Parser")
                    self.availibilities.removeAllObjects()
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
                RFSoap.shareInstance.sendRequestGetRooms(self.location, block: self.CompletionHandler)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) -> Void in
                //do nothing
            }
            alertViewController.addAction(okAction)
            alertViewController.addAction(cancelAction)
            self.presentViewController(alertViewController, animated: true, completion: nil)
        })
    }

    
    // MARK: tableViewDelegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rooms.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView .dequeueReusableCellWithIdentifier("availableRooms", forIndexPath: indexPath) as? RFRoomTableViewCell
        self.configureCell( cell!, cellForRowAtIndexPath : indexPath )
        return cell!
    }
    
    func configureCell( cell : RFRoomTableViewCell, cellForRowAtIndexPath indexPath: NSIndexPath ) {
        cell.roomLable.text = rooms[indexPath.row] as? String
        cell.stateView.alpha = 1.0
        cell.stateView.layer.cornerRadius = 7.5
        
        
        let waitTimeValue:Int = waitTime.objectAtIndex(indexPath.row) as! Int
        if(waitTimeValue == 0)
        {
            cell.stateView.backgroundColor = UIColor.greenColor()
            cell.availability.text = "Available Now"
        }
        else if(waitTimeValue <= 30)
        {
            cell.stateView.backgroundColor = UIColor.orangeColor()
            cell.availability.text = "Available in" + String(waitTime) + "minutes"
        }
        else
        {
            cell.stateView.backgroundColor = UIColor.redColor()
            cell.availability.text = "Available in" + String(waitTime) + "minutes"
        }
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //NSLog("Room...%s", rooms.objectAtIndex(indexPath.row).name)
        print("Room..." + (rooms.objectAtIndex(indexPath.row) as! String))
    }
    
    // MARK: NSXMLParser delegate
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if( elementName == "t:Name" ) {
            parseFound = .foundName
        } else if( elementName == "t:EmailAddress" ) {
            parseFound = .foundEmail
        } else if( elementName == "MergedFreeBusy" ) {
            parseFound = .foundAvailability
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        if( parseFound == .foundName ) {
            rooms.addObject(string)
        } else if( parseFound == .foundEmail ) {
            emails.addObject(string)
        } else if( parseFound == .foundAvailability ) {
            availibilities.addObject(string)
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        parseFound = .foundNone
    }
    
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        NSLog("Parse Error")
    }
    
    func parserDidEndDocument(parser: NSXMLParser) {
        if( availibilities.count != emails.count ) {
            let formatter = NSDateFormatter()
            formatter.timeZone = NSTimeZone.systemTimeZone()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss";
            let st_time = self.getStartTime()
            let sTime_string = formatter.stringFromDate(st_time)
            let endTime = st_time.dateByAddingTimeInterval(5400)
            let eTime_string = formatter.stringFromDate(endTime)
            RFSoap.shareInstance.sendRequestGetUserAvailability(emails, startTime:sTime_string, endTime:eTime_string, block: CompletionHandler)
        } else {
            //print(availibilities)
            dispatch_async(dispatch_get_main_queue(), {
                self.populateWaitTime()
                self.tableView.reloadData()
            })
        }
    }
    
    // MARK: Time
    func getStartTime() -> NSDate {
        
        //test
        let formatter = NSDateFormatter()
        formatter.timeZone = NSTimeZone.systemTimeZone()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss";
        let currentString = formatter.stringFromDate(NSDate())
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss";
        let currentTime = formatter.dateFromString(currentString)!
        
        
        formatter.dateFormat = "yyyy-MM-dd'T'HH:00:00";
        var startString = formatter.stringFromDate(currentTime)
        var startTime = formatter.dateFromString(startString)!
        
        if( currentTime.timeIntervalSinceDate(startTime) < 1800 )
        {
        
            
        } else {
            formatter.dateFormat = "yyyy-MM-dd'T'HH:30:00";
            startString = formatter.stringFromDate(currentTime)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss";
            startTime = formatter.dateFromString(startString)!
        }
        
        currentDate = currentTime
        startDate = startTime
        
        return startTime
    }
    

    func populateWaitTime()
    {
        if(availibilities.count == 0)
        {
            "availabilities is not populated"
            return
        }
        for index in 0...availibilities.count-1 {
            
            let item = availibilities.objectAtIndex(index)
            var wait:Int = 0
            let availability = item as! String
            
            let time:Int =  Int(currentDate.timeIntervalSinceDate(startDate))
            
            if(availability.hasPrefix("0"))
            {
                wait = 0
                waitTime.addObject(wait)
            }
            else if(availability.hasPrefix("20") || availability.hasPrefix("10"))
            {
                wait = 30 - time/60
                waitTime.addObject(wait)
            }
            else if(availability == "220" || availability == "110")
            {
                wait = 60 - time/60
                waitTime.addObject(wait)
            }
            else
            {
                print("no info for room at index" + String(index));
            }
        }
    }
}




// MARK: class RFRoomTableViewCell
class RFRoomTableViewCell : UITableViewCell {
    @IBOutlet weak var stateView: UIView!
    @IBOutlet weak var roomLable: UILabel!
    @IBOutlet weak var availability: UILabel!
    
}


// MARK: class RFRoom
//class RFRoom : NSObject {
//    var name : String = ""
//    var email : String = ""
//    var availibility : String = ""
//    var waitTime : Int = 0
//}
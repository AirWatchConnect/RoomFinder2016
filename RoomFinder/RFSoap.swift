
//
//  RFSoap.swift
//  RoomFinderSwift
//
//  Created by Jing Wang on 3/24/16.
//  Copyright © 2016 Jing Wang. All rights reserved.
//

import Foundation

class RFSoap {
    static let shareInstance = RFSoap()
    var server : String = ""
    
    private func getMessage( s : String ) -> String {
        let path = NSBundle.mainBundle().pathForResource(s, ofType: "txt")
        var soapMessage = ""
        do {
            soapMessage = try String.init(contentsOfFile: path!, encoding: NSUTF8StringEncoding)
        } catch {
            NSLog("Can not get Soap Message!")
        }
        return soapMessage
    }
    
    private func getRoomList() -> String {
        NSLog("Get Soap Message for getRoomList!")
        return getMessage("getRoomList")
    }
    
    private func getRooms( email : String ) -> String {
        NSLog("Get Soap Message for getRooms!")
        let formatter = getMessage("getRooms")
        let message = String.init(format: formatter, email)
        return message as String
    }
    
    private func getUserAvailability( emails : NSArray, startTime : String, endTime : String, duration : Int ) -> String {
         NSLog("Get Soap Message for getUserAvailability!")
        var messageFormat = getMessage("mailBoxData")
        var mailBoxMessage = ""
        for email in emails {
            mailBoxMessage.appendContentsOf( String.init( format: messageFormat, email as! String ) )
        }
        messageFormat = getMessage("getUserAvailability")
        let soapMessage = String.init( format: messageFormat, mailBoxMessage, startTime, endTime, duration )
        return soapMessage
    }
    
    private func sendRequest( soapMessage : String, block : ( NSData?, NSURLResponse?, NSError? ) -> Void ) {
        let url = self.getURL()
        let request = NSMutableURLRequest( URL: url! )
        
        request.addValue("text/xml", forHTTPHeaderField: "Content-Type")
        request.HTTPMethod = "POST"
        request.HTTPBody = soapMessage.dataUsingEncoding(NSUTF8StringEncoding)
        
        let session : RFURLSession = RFURLSession( request: request )
        session.sendAsynchronousRequest(completionHandler: block)
    }
    
    func sendRequest( block : ( NSData?, NSURLResponse?, NSError? ) -> Void ) {
        NSLog("Send Get Request for connection")
        let url = self.getURL()
        let request = NSMutableURLRequest( URL: url! )
        request.HTTPMethod = "GET"
        
        let session : RFURLSession = RFURLSession( request: request )
        session.sendAsynchronousRequest(completionHandler: block)
    }

    func sendRequestGetRoomlist( block : ( NSData?, NSURLResponse?, NSError? ) -> Void ) {
        let soapMessage = getRoomList()
        NSLog("Send Request for RoomList")
        sendRequest(soapMessage, block: block)
    }
    
    func sendRequestGetRooms( email : String, block : ( NSData?, NSURLResponse?, NSError? ) -> Void ) {
        let soapMessage = getRooms(email)
        NSLog("Send Request for Rooms")
        sendRequest(soapMessage, block: block)
    }
    
    func sendRequestGetUserAvailability( emails : NSArray, startTime: String, endTime : String, block : ( NSData?, NSURLResponse?, NSError? ) -> Void ) {
        let start = startTime
        let end = endTime
        
        let soapMessage = getUserAvailability(emails, startTime: start, endTime: end, duration: 30)
        NSLog("Send Request for UserAvailability")
        sendRequest(soapMessage, block: block)
    }
    
    /*replace http with https or if no scheme is found, add https*/
    func getURL() -> NSURL? {
        var newServerString = server.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        if server.hasPrefix("http") {
             newServerString = server.stringByReplacingOccurrencesOfString("http://", withString:"")
        }
        var url = NSURL.init(string:newServerString)
        if(url?.scheme == nil || url?.scheme == "http" || url?.scheme == "" ) {
            url = NSURL.init(string:"https://" + newServerString)
        }
        return url
    }
}

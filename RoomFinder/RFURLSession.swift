//
//  RFURLSession.swift
//  RoomFinderSwift
//
//  Created by Jing Wang on 3/25/16.
//  Copyright © 2016 Jing Wang. All rights reserved.
//

import Foundation
import AWSDK


public enum RFCredentialError : Int {
    case Empty = 1001, Invalid
}

public class RFURLSession : NSObject, NSURLSessionDataDelegate {
    
    private var request = NSMutableURLRequest()
    private var sessionDataTask = NSURLSessionDataTask()
    private var session = NSURLSession()
    
    private var receivedData = NSMutableData()
    private var aSyncCompletionHandler  : (NSData?, NSURLResponse?, NSError?) -> Void = { (data: NSData?,response: NSURLResponse?,error: NSError?) -> Void in }
    private var response : NSURLResponse?
    private var nsError: NSError?
    private var sdkCouldNotHandleChallenge: Bool = false
    public override init() {
        print("init")
    }
    
    public init( request : NSURLRequest ) {
        print("init RFURLSession with request : %s" , request)
        super.init()
        self.request = request.mutableCopy() as! NSMutableURLRequest
    }
    
    public func sendAsynchronousRequest( completionHandler handler : ( NSData?, NSURLResponse?, NSError?) -> Void ) {
        let sesstionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: sesstionConfig, delegate: self, delegateQueue: nil)
        sessionDataTask = session.dataTaskWithRequest(request)
        
        aSyncCompletionHandler = handler
        sessionDataTask.resume()
    }
    
    
    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        if(challenge.previousFailureCount == 0) {
            do {
                try AWController.clientInstance().canHandleProtectionSpace(challenge.protectionSpace)
                if(AWController.clientInstance().handleChallengeForURLSessionChallenge(challenge, completionHandler: completionHandler)) {
                    print("challenge handled successfully")
                    print (" previous failure count" + String(challenge.previousFailureCount))
                }
                else {
                    self.handleURLSessionChallenge(session, didReceiveChallenge: challenge, completionHandler: completionHandler)
                }
            }
            catch {
                self.handleURLSessionChallenge(session, didReceiveChallenge: challenge, completionHandler: completionHandler)
            }
        }
        else {
            sdkCouldNotHandleChallenge = true
            self.handleURLSessionChallenge(session, didReceiveChallenge: challenge, completionHandler: completionHandler)
        }
    }
    
    public func handleURLSessionChallenge(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        
        if(challenge.protectionSpace.authenticationMethod == "NSURLAuthenticationMethodServerTrust")
        {
            completionHandler(NSURLSessionAuthChallengeDisposition.PerformDefaultHandling, nil)
            return
        }
        
        var details = [String: AnyObject]()
        details[NSLocalizedDescriptionKey] = "Invalid credential."
        if(RFCredential.shareInstance.isCredentialsEmpty())
        {
            nsError = NSError(domain: "Warning", code: RFCredentialError.Empty.rawValue, userInfo: details)
            aSyncCompletionHandler( nil, nil, nsError)
            completionHandler( NSURLSessionAuthChallengeDisposition.CancelAuthenticationChallenge, nil)
        }
        else
        {
            var countToConsider = 0
            if(sdkCouldNotHandleChallenge) {
                countToConsider = 1
            }
            if(challenge.previousFailureCount > countToConsider)
            {
                nsError = NSError(domain: "Warning", code: RFCredentialError.Invalid.rawValue, userInfo: details)
                aSyncCompletionHandler( nil, nil, nsError)
                completionHandler( NSURLSessionAuthChallengeDisposition.CancelAuthenticationChallenge, nil )
            }
            else
            {
                let username = RFCredential.shareInstance.getUsername()
                let password = RFCredential.shareInstance.getPassword()
                let credential : NSURLCredential = NSURLCredential.init(user: username, password: password, persistence: NSURLCredentialPersistence.None)
                completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, credential)
            }
            
        }

    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        self.response = response
        completionHandler( NSURLSessionResponseDisposition.Allow)
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        self.receivedData.appendData(data)
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        self.nsError = error
        aSyncCompletionHandler(receivedData, response, error)
    }
    

    
}
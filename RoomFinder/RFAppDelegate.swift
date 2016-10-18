//
//  RFAppDelegate.swift
//  SwiftTakeOff
//
//  Created by Anuj Panwar on 6/17/16.
//  Copyright © 2016 Anuj Panwar. All rights reserved.
//

import UIKit
import AWSDK

@UIApplicationMain
class RFAppDelegate: UIResponder, UIApplicationDelegate, AWSDKDelegate {
    
    var window: UIWindow?
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        //Initialize SDK
        let awc = AWController.clientInstance()
        awc.delegate = self
        awc.callbackScheme = "roomfinder"
        awc.start()
        return true
    }
    
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return AWController.clientInstance().handleOpenURL(url, fromApplication: sourceApplication)
    }
    
    //MARK: AWSDKDelegate Implementation

    
    func initialCheckDoneWithError(error: NSError!) {
        
    }
    
    func receivedProfiles(profiles: [AnyObject]!) {
        print("did receieve profiles called")
        //recieve and parse profiles
        if let allProfiles = profiles {
            for profile in allProfiles {
                if let awProfile = profile as? AWProfile {
                    //this is sdk profile
                    if let customPayloadSettings = awProfile.customPayload?.settings {
                    let rootViewController = self.window?.rootViewController?.childViewControllers[0] as? RFLoginViewController
                        rootViewController?.setURL(customPayloadSettings)
                    }
                }
            }
        }
    }

    func wipe() {
         print("AWSDK wipe callback called!")
    }
    
    func lock() {
         print("AWSDK Lock callback called!")
    }
    
    func unlock() {
         print("AWSDK UnLock callback called!")
    }
    
    func stopNetworkActivity(networkActivityStatus: AWNetworkActivityStatus) {
        
    }
    
    func resumeNetworkActivity() {
        
    }
    
    

}

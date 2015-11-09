//  AppDelegate.swift
//  Smartvoxx
//
//  Created by Sebastien Arbogast on 23/08/2015.
//  Copyright © 2015 Epseelon. All rights reserved.
//

import UIKit
import WatchConnectivity

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, WCSessionDelegate {

    var window: UIWindow?
    var session: WCSession?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        if WCSession.isSupported() {
            session = WCSession.defaultSession()
            session?.delegate = self
            session?.activateSession()
        }
        return true
    }

    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        self.updateLocalNotificationWithMessage(message)
    }
    
    func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        self.updateLocalNotificationWithMessage(userInfo)
    }
    
    private func updateLocalNotificationWithMessage(message:[String:AnyObject]){
        if let talkSlot = message["talkSlot"] as? NSDictionary {
            let id = talkSlot["talkId"] as? String
            
            for notification in UIApplication.sharedApplication().scheduledLocalNotifications! {
                if let userInfo = notification.userInfo {
                    if let talkId = userInfo["id"] as? String {
                        if talkId == id {
                            UIApplication.sharedApplication().cancelLocalNotification(notification)
                        }
                    }
                }
            }
            
            let favorite = talkSlot["favorite"] as? NSNumber
            
            if let fav = favorite?.boolValue where fav {
                DataController.sharedInstance.swapFavoriteStatusForTalkSlotWithId(id!, favorite: true)
                
                let title = talkSlot["title"] as? String
                let room = talkSlot["room"] as? String
                
                let fromTimeMillis = talkSlot["fromTimeMillis"] as? NSNumber
                let fromTime = talkSlot["fromTime"] as? String
                let toTime = talkSlot["toTime"] as? String
                
                let date = NSDate(timeIntervalSince1970: fromTimeMillis!.doubleValue / 1000)
                let notification = UILocalNotification()
                notification.fireDate = date.dateByAddingTimeInterval(-10*60)
                notification.timeZone = NSTimeZone.localTimeZone()
                notification.userInfo = talkSlot as [NSObject : AnyObject]
                notification.alertTitle = title
                notification.alertBody = String(format: NSLocalizedString("From %@ to %@ in %@", comment: ""), arguments: [fromTime!, toTime!, room!])
                UIApplication.sharedApplication().scheduleLocalNotification(notification)
            } else {
                DataController.sharedInstance.swapFavoriteStatusForTalkSlotWithId(id!, favorite: false)
            }
        }
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
}


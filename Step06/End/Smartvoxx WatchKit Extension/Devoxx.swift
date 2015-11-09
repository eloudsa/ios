//
//  Devoxx.swift
//  Smartvoxx
//
//  Created by Sebastien Arbogast on 24/10/2015.
//  Copyright © 2015 Epseelon. All rights reserved.
//

import WatchKit

class Devoxx: NSObject {
    static var sharedInstance = Devoxx()
    var session:NSURLSession
    var cache = DevoxxCache()
    
    override init() {
        //Configure session and disable caching as it fails
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.requestCachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        session = NSURLSession(configuration: configuration)
    }
    
    func loadSchedulesForConference(conference:String, callback: ([Schedule]) -> (Void)) {
        let schedules = cache.getSchedules()
        if schedules.count > 0 {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                callback(schedules)
            })
        }
        
        //Call API
        guard let schedulesURL = NSURL(string: "http://cfp.devoxx.be/api/conferences/\(conference)/schedules/") else {
            print("Error while creating schedules URL")
            return
        }
        let task = session.dataTaskWithURL(schedulesURL) { (data: NSData?, response:NSURLResponse?, error:NSError?) -> Void in
            
            //Treat error
            guard let data = data else {
                print(error)
                return
            }
            
            self.cache.saveSchedulesFromData(data)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                callback(self.cache.getSchedules())
            })
            
        }
        task.resume()
    }
}

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
    
    func loadSchedulesForConference(conference:String, callback: ([NSDictionary]) -> (Void)) {
        //Configure session and disable caching as it fails
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.requestCachePolicy = NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData
        let session = NSURLSession(configuration: configuration)
        
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
            
            do {
                //Parse data
                let schedulesDict = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                guard let schedulesArray = schedulesDict["links"] as? [NSDictionary] else {
                    print("No links array in parsed schedules")
                    return
                }
                //Send back result
                callback(schedulesArray)
            } catch let jsonError {
                print(jsonError)
            }
            
        }
        task.resume()
    }
}

//
//  Schedule.swift
//  Smartvoxx
//
//  Created by Sebastien Arbogast on 24/10/2015.
//  Copyright © 2015 Epseelon. All rights reserved.
//

import WatchKit

class Schedule: NSObject {
    var title:String?
    var href:NSURL?
    
    init(fromDictionary dictionary:NSDictionary){
        guard let title = dictionary["title"] as? String else {
            print("Cannot find title")
            return
        }
        
        guard let href = dictionary["href"] as? String else {
            print("Cannot find href")
            return
        }
        
        self.title = title
        self.href = NSURL(string: href)
    }
    
    override var description:String {
        return self.title!
    }
}

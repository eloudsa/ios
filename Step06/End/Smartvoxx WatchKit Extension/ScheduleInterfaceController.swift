//
//  ScheduleInterfaceController.swift
//  Smartvoxx
//
//  Created by Sebastien Arbogast on 24/10/2015.
//  Copyright © 2015 Epseelon. All rights reserved.
//

import WatchKit
import Foundation


class ScheduleInterfaceController: WKInterfaceController {
    var schedule:Schedule?

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        if let schedule = context as? Schedule {
            self.schedule = schedule
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        if let schedule = self.schedule, title = schedule.title {
            self.setTitle(title.componentsSeparatedByString(",")[0])
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}

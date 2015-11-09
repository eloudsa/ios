//
//  InterfaceController.swift
//  SmartvoxxOnWrist Extension
//
//  Created by Sebastien Arbogast on 23/08/2015.
//  Copyright © 2015 Epseelon. All rights reserved.
//

import WatchKit
import Foundation

class InterfaceController: WKInterfaceController {
    @IBOutlet var activityIndicator: WKInterfaceImage!
    @IBOutlet var table: WKInterfaceTable!
    
    var schedules: [Schedule]?

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        self.activityIndicator.setImageNamed("Activity")
    }
    
    override func willActivate() {
        super.willActivate()
        self.activityIndicator.setHidden(false)
        self.activityIndicator.startAnimatingWithImagesInRange(NSMakeRange(0, 30), duration: 1.0, repeatCount: 0)
        
        DataController.sharedInstance.getSchedules { (schedules:[Schedule]) -> (Void) in
            self.schedules = schedules
            self.activityIndicator.stopAnimating()
            self.activityIndicator.setHidden(true)
                
            self.table.setNumberOfRows(self.schedules!.count, withRowType: "schedule")
            for (index,schedule) in self.schedules!.enumerate() {
                if let row = self.table.rowControllerAtIndex(index) as? ScheduleRowController {
                    row.label.setText(schedule.title!.stringByReplacingOccurrencesOfString(NSLocalizedString("Schedule for ", comment:""), withString: ""))
                }
            }
        }
    }

    override func didDeactivate() {
        super.didDeactivate()
        DataController.sharedInstance.cancelSchedules()
    }

    override func contextForSegueWithIdentifier(segueIdentifier: String, inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
        return self.schedules![rowIndex]
    }
}

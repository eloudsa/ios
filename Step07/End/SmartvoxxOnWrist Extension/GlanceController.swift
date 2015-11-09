//
//  GlanceController.swift
//  SmartvoxxOnWrist Extension
//
//  Created by Sebastien Arbogast on 23/08/2015.
//  Copyright © 2015 Epseelon. All rights reserved.
//

import WatchKit
import Foundation


class GlanceController: WKInterfaceController {

    @IBOutlet var headerLabel: WKInterfaceLabel!
    @IBOutlet var subtitleLabel: WKInterfaceLabel!
    @IBOutlet var titleLabel: WKInterfaceLabel!
    @IBOutlet var roomLabel: WKInterfaceLabel!
    @IBOutlet var dateLabel: WKInterfaceLabel!
    
    var nextFavoriteSlots:[TalkSlot]?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        
        self.headerLabel.setText(NSLocalizedString("Next", comment: ""))
        self.subtitleLabel.setText(NSLocalizedString("in Devoxx 2015", comment: ""))
    }

    override func willActivate() {
        super.willActivate()
        
        self.nextFavoriteSlots = DataController.sharedInstance.getFavoriteTalksAfterDate(NSDate())
        if let nextFavoriteSlots = self.nextFavoriteSlots where nextFavoriteSlots.count > 0 {
            let now = NSDate()
            var nextFavoriteSlot:TalkSlot?
            for talkSlot in nextFavoriteSlots {
                if talkSlot.fromTimeMillis?.doubleValue > now.timeIntervalSince1970 * 1000 {
                    nextFavoriteSlot = talkSlot
                    break
                }
            }
            if let nextFavoriteSlot = nextFavoriteSlot {
                self.titleLabel.setText(nextFavoriteSlot.title)
                
                self.roomLabel.setHidden(false)
                self.dateLabel.setHidden(false)
                self.roomLabel.setText(nextFavoriteSlot.roomName)
                
                let startDate = NSDate(timeIntervalSince1970: nextFavoriteSlot.fromTimeMillis!.doubleValue / 1000)
                let formatter = NSDateFormatter()
                formatter.dateStyle = NSDateFormatterStyle.LongStyle
                formatter.timeStyle = NSDateFormatterStyle.NoStyle
                let day = formatter.stringFromDate(startDate)
                self.dateLabel.setText("\(day), \(nextFavoriteSlot.fromTime!) - \(nextFavoriteSlot.toTime!)")
            } else {
                self.titleLabel.setText(NSLocalizedString("No more upcoming favorite talk.", comment: ""))
                self.roomLabel.setHidden(true)
                self.dateLabel.setHidden(true)
            }
        } else {
            self.titleLabel.setText(NSLocalizedString("No more upcoming favorite talk.", comment: ""))
            self.roomLabel.setHidden(true)
            self.dateLabel.setHidden(true)
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}

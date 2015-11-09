//
//  ScheduleControllerInterfaceController.swift
//  Smartvoxx
//
//  Created by Sebastien Arbogast on 13/09/2015.
//  Copyright © 2015 Epseelon. All rights reserved.
//

import WatchKit
import Foundation


class ScheduleController: WKInterfaceController {
    @IBOutlet var activityIndicator: WKInterfaceImage!
    @IBOutlet var table: WKInterfaceTable!
    var schedule: Schedule?
    var dataSource = [AnyObject]()

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        self.activityIndicator.setImageNamed("Activity")

        if let context = context as? Schedule {
            self.schedule = context
        }
    }

    override func willActivate() {
        super.willActivate()

        if let schedule = self.schedule {
            if let date = schedule.title {
                self.setTitle(date.componentsSeparatedByString(",")[0])
            }
            self.activityIndicator.setHidden(false)
            self.activityIndicator.startAnimatingWithImagesInRange(NSMakeRange(0, 30), duration: 1.0, repeatCount: 0)

            DataController.sharedInstance.getSlotsForSchedule(schedule) {
                (slots: [Slot]) -> (Void) in
                self.schedule?.slots = NSOrderedSet(array: slots)
                self.activityIndicator.stopAnimating()
                self.activityIndicator.setHidden(true)

                var timeRanges = [String]()
                var rowTypes = [String]()
                self.dataSource = [AnyObject]()
                for slot in slots {
                    let timeRange = "\(slot.fromTime!) - \(slot.toTime!)"

                    if !timeRanges.contains(timeRange) {
                        timeRanges.append(timeRange)
                        rowTypes.append("timerange")
                        self.dataSource.append(timeRange)
                    }

                    rowTypes.append("slot")
                    self.dataSource.append(slot)
                }
                self.table.setRowTypes(rowTypes)

                var index = 0
                for item in self.dataSource {
                    if let timeRangeRowController = self.table.rowControllerAtIndex(index) as? TimeRangeRowController {
                        if let timeRange = item as? String {
                            timeRangeRowController.label.setText(timeRange)
                        }
                    } else if let slotRowController = self.table.rowControllerAtIndex(index) as? SlotRowController {
                        if let slot = item as? Slot {
                            slotRowController.roomLabel.setText(slot.roomName!)

                            if let breakSlot = item as? BreakSlot {
                                slotRowController.titleLabel.setText(breakSlot.nameEN!)
                                slotRowController.trackSeparator.setBackgroundColor(UIColor.clearColor())
                                slotRowController.favoriteImage.setHidden(true)
                            } else if let talkSlot = item as? TalkSlot {
                                slotRowController.titleLabel.setText(talkSlot.title!)
                                if talkSlot.track != nil {
                                    slotRowController.trackSeparator.setBackgroundColor(UIColor(rgba: talkSlot.track!.color!))
                                } else {
                                    slotRowController.trackSeparator.setBackgroundColor(UIColor.clearColor())
                                }

                                if let favorite = talkSlot.favorite?.boolValue where favorite {
                                    slotRowController.favoriteImage.setHidden(false)
                                    slotRowController.favoriteImage.setImageNamed("FavoriteOn")
                                } else {
                                    slotRowController.favoriteImage.setHidden(true)
                                }
                            } else {
                                slotRowController.titleLabel.setText(NSLocalizedString("Coming soon...", comment: ""))
                            }
                        }
                    }
                    index++
                }
            }
        }
    }

    override func didDeactivate() {
        if let schedule = self.schedule {
            DataController.sharedInstance.cancelSlotsForSchedule(schedule)
        }

        super.didDeactivate()
    }

    override func contextForSegueWithIdentifier(segueIdentifier: String, inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
        return self.dataSource[rowIndex]
    }
}

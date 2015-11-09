//
//  SlotControllerInterfaceController.swift
//  Smartvoxx
//
//  Created by Sebastien Arbogast on 26/09/2015.
//  Copyright © 2015 Epseelon. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class SlotController: WKInterfaceController, WCSessionDelegate {
    @IBOutlet var titleLabel: WKInterfaceLabel!
    @IBOutlet var trackLabel: WKInterfaceLabel!
    @IBOutlet var roomLabel: WKInterfaceLabel!
    @IBOutlet var dateLabel: WKInterfaceLabel!
    @IBOutlet var timesLabel: WKInterfaceLabel!
    @IBOutlet var summaryLabel: WKInterfaceLabel!
    @IBOutlet var speakersTable: WKInterfaceTable!
    @IBOutlet var summarySeparator: WKInterfaceSeparator!
    @IBOutlet var speakersSeparator: WKInterfaceSeparator!
    @IBOutlet var favoriteImage: WKInterfaceImage!
    
    var slot:Slot?
    var speakers:[Speaker]?
    var session:WCSession?

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        if let talkSlot = context as? TalkSlot {
            self.slot = talkSlot
        } else if let breakSlot = context as? BreakSlot {
            self.slot = breakSlot
        } else {
            self.slot = nil
        }
        
        self.updateMenu()
        startSession()
    }
    
    private func startSession() {
        if WCSession.isSupported() {
            session = WCSession.defaultSession()
            session?.delegate = self
            session?.activateSession()
        }
    }

    override func willActivate() {
        super.willActivate()
                
        if let talkSlot = self.slot as? TalkSlot {
            self.slot = talkSlot
            self.titleLabel.setText(talkSlot.title!)
            self.trackLabel.setHidden(false)
            if let trackName = talkSlot.track?.name {
                self.trackLabel.setText(trackName)
            }
            if let trackColor = talkSlot.track?.color {
                self.trackLabel.setTextColor(UIColor(rgba: trackColor))
            }
            self.roomLabel.setText(talkSlot.roomName!)
            self.dateLabel.setText(talkSlot.day!.capitalizedString)
            self.timesLabel.setText("\(talkSlot.fromTime!) - \(talkSlot.toTime!)")
            self.summaryLabel.setHidden(false)
            self.summaryLabel.setText(talkSlot.summary!)
            self.speakersTable.setHidden(false)
            self.speakersTable.setNumberOfRows(talkSlot.speakers!.count, withRowType: "speaker")
            
            self.speakers = talkSlot.speakers!.allObjects as? [Speaker]
            for (index,speaker) in self.speakers!.enumerate() {
                if let row = self.speakersTable.rowControllerAtIndex(index) as? SpeakerRowController {
                    row.nameLabel.setText(speaker.name!)
                }
            }
            self.summarySeparator.setHidden(false)
            self.speakersSeparator.setHidden(talkSlot.speakers!.count > 0)
        } else if let breakSlot = self.slot as? BreakSlot {
            self.slot = breakSlot
            self.titleLabel.setText(breakSlot.nameEN!)
            self.trackLabel.setHidden(true)
            self.roomLabel.setText(breakSlot.roomName!)
            self.dateLabel.setText(breakSlot.day!.capitalizedString)
            self.timesLabel.setText("\(breakSlot.fromTime!) - \(breakSlot.toTime!)")
            self.summaryLabel.setHidden(true)
            self.speakersTable.setHidden(true)
            self.summarySeparator.setHidden(true)
            self.speakersSeparator.setHidden(true)
        } else {
            self.slot = nil
        }
    }
    
    func updateMenu() {
        self.clearAllMenuItems()
        if let talkSlot = self.slot as? TalkSlot {
            self.favoriteImage.setHidden(false)
            if let favorite = talkSlot.favorite?.boolValue where favorite {
                self.addMenuItemWithImageNamed("FavoriteOffMenu", title: NSLocalizedString("Remove from Favorites", comment: ""), action: "favoriteMenuSelected")
                self.favoriteImage.setImageNamed("FavoriteOn")
            } else {
                self.addMenuItemWithImageNamed("FavoriteOnMenu", title: NSLocalizedString("Add to Favorites", comment: ""), action: "favoriteMenuSelected")
                self.favoriteImage.setImageNamed("FavoriteOff")
            }
            self.addMenuItemWithItemIcon(WKMenuItemIcon.Decline, title: NSLocalizedString("Cancel", comment: ""), action: "cancelMenuSelected")
        } else {
            self.favoriteImage.setHidden(true)
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    override func contextForSegueWithIdentifier(segueIdentifier: String, inTable table: WKInterfaceTable, rowIndex: Int) -> AnyObject? {
        if let speakers = self.speakers {
            return speakers[rowIndex]
        } else {
            return nil
        }
    }
    
    @IBAction func favoriteMenuSelected() {
        if let talkSlot = self.slot as? TalkSlot {
            DataController.sharedInstance.swapFavoriteStatusForTalkSlot(talkSlot, callback: { (talkSlot:TalkSlot) -> Void in
                self.slot = talkSlot
                self.updateMenu()
                self.scheduleNotification()
            })
        }
    }
    
    @IBAction func cancelMenuSelected() {
    }
    
    private func scheduleNotification() {
        if let talkSlot = self.slot as? TalkSlot {
            let talkSlotMessage = [
                "title":talkSlot.title!,
                "room":talkSlot.roomName!,
                "talkId":talkSlot.talkId!,
                "track":talkSlot.track!.name!,
                "favorite":talkSlot.favorite!,
                "fromTimeMillis":talkSlot.fromTimeMillis!,
                "fromTime":talkSlot.fromTime!,
                "toTime":talkSlot.toTime!
            ]
            
            if WCSession.isSupported() {
                if let session = self.session where session.reachable {
                    session.sendMessage(["talkSlot" : talkSlotMessage as NSDictionary], replyHandler: { (reply:[String : AnyObject]) -> Void in
                        
                        }, errorHandler: { (error:NSError) -> Void in
                            print(error)
                    })
                } else {
                    session?.transferUserInfo(["talkSlot" : talkSlotMessage as NSDictionary])
                }
            }
        }
    }
}

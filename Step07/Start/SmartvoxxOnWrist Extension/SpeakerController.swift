//
//  SpeakerController.swift
//  Smartvoxx
//
//  Created by Sebastien Arbogast on 26/09/2015.
//  Copyright © 2015 Epseelon. All rights reserved.
//

import WatchKit
import Foundation


class SpeakerController: WKInterfaceController {
    @IBOutlet var nameLabel: WKInterfaceLabel!
    @IBOutlet var avatarImage: WKInterfaceImage!
    @IBOutlet var companyLabel: WKInterfaceLabel!
    @IBOutlet var bioLabel: WKInterfaceLabel!
    @IBOutlet var activityIndicator: WKInterfaceImage!
    var speaker:Speaker?

    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        self.activityIndicator.setImageNamed("Activity")

        if let speaker = context as? Speaker {
            self.speaker = speaker
        }
    }

    override func willActivate() {
        super.willActivate()

        if let speaker = self.speaker {
            self.activityIndicator.setHidden(false)
            self.activityIndicator.startAnimatingWithImagesInRange(NSMakeRange(0, 30), duration: 1.0, repeatCount: 0)

            DataController.sharedInstance.getSpeaker(speaker) {
                (speaker: Speaker) -> (Void) in
                self.activityIndicator.stopAnimating()
                self.activityIndicator.setHidden(true)

                self.nameLabel.setText("\(speaker.firstName!) \(speaker.lastName!)")
                self.companyLabel.setText(speaker.company!)
                self.bioLabel.setText(speaker.bio!)

                self.avatarImage.setImageNamed("Activity")
                self.avatarImage.startAnimating()

                self.avatarImage.setImageNamed("Activity")
                self.avatarImage.startAnimating()

                DataController.sharedInstance.getAvatarForSpeaker(speaker) {
                    (data: NSData) -> (Void) in
                    dispatch_async(dispatch_get_main_queue(), {
                        () -> Void in
                        self.avatarImage.stopAnimating()
                        self.avatarImage.setImageData(data)
                    })
                }
            }
        }
    }

    override func didDeactivate() {
        super.didDeactivate()
        DataController.sharedInstance.cancelSpeaker(speaker!)
        DataController.sharedInstance.cancelAvatarForSpeaker(speaker!)
    }

}

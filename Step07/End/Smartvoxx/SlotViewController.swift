//
//  SlotViewController.swift
//  Smartvoxx
//
//  Created by Sebastien Arbogast on 27/09/2015.
//  Copyright © 2015 Epseelon. All rights reserved.
//

import UIKit

class SlotViewController: UITableViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var trackLabel: UILabel!
    @IBOutlet weak var summaryText: UITextView!
    @IBOutlet weak var dateTimeLabel: UILabel!
    @IBOutlet weak var roomLabel: UILabel!
    @IBOutlet weak var headerView: UIView!
    
    var slot:Slot?
    var speakers:[Speaker]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let talkSlot = self.slot as? TalkSlot {
            self.title = NSLocalizedString("Talk", comment: "")
            self.speakers = talkSlot.speakers?.allObjects as? [Speaker]
            titleLabel.text = talkSlot.title
            trackLabel.hidden = false
            trackLabel.text = talkSlot.track?.name
            summaryText.text = talkSlot.summary
            summaryText.hidden = false
            dateTimeLabel.text = "\(talkSlot.day!.capitalizedString), \(talkSlot.fromTime!) - \(talkSlot.toTime!)"
            roomLabel.text = talkSlot.roomName
        } else if let breakSlot = self.slot as? BreakSlot {
            self.title = NSLocalizedString("Break", comment: "")
            titleLabel.text = breakSlot.nameEN
            trackLabel.text = ""
            trackLabel.hidden = true
            summaryText.text = ""
            summaryText.hidden = true
            dateTimeLabel.text = "\(breakSlot.day!.capitalizedString), \(breakSlot.fromTime!) - \(breakSlot.toTime!)"
            roomLabel.text = breakSlot.roomName
        } else {
            self.title = ""
            titleLabel.text = ""
            trackLabel.text = ""
            summaryText.text = ""
            dateTimeLabel.text = ""
            roomLabel.text = ""
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let speakers = self.speakers {
            return speakers.count
        } else {
            return 0;
        }
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let speakers = self.speakers where speakers.count > 0 {
            return NSLocalizedString("Speakers", comment: "")
        } else {
            return nil
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("speakerCell", forIndexPath: indexPath)
        
        let speaker = self.speakers![indexPath.row]
        cell.textLabel?.text = speaker.name
        
        return cell
    }
}

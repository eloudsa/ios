//
//  ScheduleViewController.swift
//  DevoxxOnWrist
//
//  Created by Sebastien Arbogast on 16/08/2015.
//  Copyright © 2015 Epseelon. All rights reserved.
//

import UIKit

class ScheduleViewController: UITableViewController {
    var schedule:Schedule?
    var groupedSchedule = [String:[Slot]]()
    var timeRanges = [String]()
    var selectedSlot:Slot?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let schedule = self.schedule {
            self.title = schedule.title?.stringByReplacingOccurrencesOfString(NSLocalizedString("Schedule for ", comment:""), withString: "")
        }
    }
    
    func reloadSchedule() {
        if let schedule = self.schedule {
            DataController.sharedInstance.getSlotsForSchedule(schedule, callback: { (slots:[Slot]) -> (Void) in
                self.groupedSchedule = [String:[Slot]]()
                self.timeRanges = [String]()
                for slot in slots {
                    let timeRange = "\(slot.fromTime!) - \(slot.toTime!)"
                    if self.timeRanges.contains(timeRange) {
                        if self.groupedSchedule[timeRange] != nil {
                            self.groupedSchedule[timeRange]!.append(slot)
                        }
                    } else {
                        self.timeRanges.append(timeRange)
                        self.groupedSchedule[timeRange] = [slot]
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                })
            })
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        groupedSchedule = [String:[Slot]]()
        timeRanges = [String]()
        self.tableView.reloadData()

        self.reloadSchedule()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if let schedule = self.schedule {
            DataController.sharedInstance.cancelSlotsForSchedule(schedule)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.timeRanges.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.groupedSchedule[self.timeRanges[section]]!.count
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.timeRanges[section]
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("slotCell", forIndexPath: indexPath)

        let slot = self.groupedSchedule[self.timeRanges[indexPath.section]]![indexPath.row]
        if let talkSlot = slot as? TalkSlot {
            cell.textLabel?.text = talkSlot.title
            if let fav = talkSlot.favorite?.boolValue where fav {
                cell.textLabel?.textColor = UIColor.redColor()
            } else {
                cell.textLabel?.textColor = UIColor.blackColor()
            }
        } else if slot is BreakSlot {
            cell.textLabel?.text = (slot as! BreakSlot).nameEN
        } else {
            cell.textLabel?.text = ""
        }
        cell.detailTextLabel?.text = slot.roomName

        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let timeRange = self.groupedSchedule[self.timeRanges[indexPath.section]] {
            self.selectedSlot = timeRange[indexPath.row]
            self.performSegueWithIdentifier("showSlot", sender: self)
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showSlot" {
            if let slotViewController = segue.destinationViewController as? SlotViewController {
                slotViewController.slot = self.selectedSlot
            }
        }
    }


}

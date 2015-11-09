//
//  MasterViewController.swift
//  Smartvoxx
//
//  Created by Sebastien Arbogast on 23/08/2015.
//  Copyright © 2015 Epseelon. All rights reserved.
//

import UIKit

class MasterViewController: UITableViewController {
    var schedules:[Schedule]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: "reloadSchedules", forControlEvents: UIControlEvents.ValueChanged)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.reloadSchedules()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        DataController.sharedInstance.cancelSchedules()
    }
    
    func reloadSchedules() {
        self.refreshControl?.beginRefreshing()
        DataController.sharedInstance.getSchedules { (schedules:[Schedule]) -> (Void) in
            self.schedules = schedules
            
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                let schedule = self.schedules![indexPath.row]
                let controller = segue.destinationViewController as! ScheduleViewController
                controller.schedule = schedule
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let schedules = self.schedules {
            return schedules.count
        } else {
            return 0
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        
        let schedule = schedules![indexPath.row]
        cell.textLabel!.text = schedule.title!.stringByReplacingOccurrencesOfString(NSLocalizedString("Schedule for ", comment:""), withString: "")
        return cell
    }
}


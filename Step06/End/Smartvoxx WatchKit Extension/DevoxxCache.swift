//
//  DevoxxCache.swift
//  Smartvoxx
//
//  Created by Sebastien Arbogast on 07/11/2015.
//  Copyright © 2015 Epseelon. All rights reserved.
//

import WatchKit
import CoreData

class DevoxxCache: NSObject {
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count - 1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("Smartvoxx", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Smartvoxx.sqlite")
        do {
            print(url)
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            print(error)
        }
        
        return coordinator
    }()
    
    lazy var mainObjectContext: NSManagedObjectContext = {
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return managedObjectContext
    }()
    
    lazy var privateObjectContext: NSManagedObjectContext = {
        var privateContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        privateContext.parentContext = self.mainObjectContext
        return privateContext
    }()
    
    override init() {
        
    }
    
    func saveContext(context: NSManagedObjectContext) {
        do {
            try context.save()
            if let parentContext = context.parentContext {
                try parentContext.save()
            }
        } catch {
            print(error)
            abort()
        }
    }
    
    func getSchedules() -> [Schedule] {
        return self.getSchedules(fromContext: self.mainObjectContext)
    }
    
    private func getSchedules(fromContext context: NSManagedObjectContext) -> [Schedule] {
        var schedules = [Schedule]()
        
        context.performBlockAndWait { () -> Void in
            let request = NSFetchRequest(entityName: "Conference")
            request.predicate = NSPredicate(format: "eventCode=%@", "DV15")
            do {
                let results = try context.executeFetchRequest(request)
                if results.count > 0 {
                    guard let devoxx15 = results[0] as? Conference, scheduleSet = devoxx15.schedules, scheduleArray = scheduleSet.array as? [Schedule] else {
                        schedules = [Schedule]()
                        return
                    }
                    schedules = scheduleArray
                }
            } catch let error as NSError {
                print(error)
            }
        }        
        return schedules
    }
    
    func saveSchedulesFromData(data: NSData) {
        self.saveSchedulesFromData(data, inContext: self.privateObjectContext)
    }
    
    private func saveSchedulesFromData(data: NSData, inContext context: NSManagedObjectContext) {
        context.performBlockAndWait { () -> Void in
            if data.length > 0 {
                do {
                    let schedulesDict = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                    if let schedulesDict = schedulesDict as? NSDictionary, schedulesArray = schedulesDict["links"] as? NSArray {
                        guard let devoxx15 = self.getOrCreateDevoxx15(inContext: context) else {
                            print("Could not retrieve Devoxx15 conference")
                            return
                        }
                        var schedules = [Schedule]()
                        for scheduleDict in schedulesArray {
                            if let scheduleDict = scheduleDict as? NSDictionary {
                                guard let schedule = self.getOrCreateScheduleForHref(scheduleDict["href"] as! String, inContext: context) else {
                                    print("Could not retrieve or create schedule")
                                    return
                                }
                                schedule.title = scheduleDict["title"] as? String
                                schedule.href = scheduleDict["href"] as? String
                                schedule.conference = devoxx15
                                self.saveContext(context)
                                schedules.append(schedule)
                            }
                        }
                        devoxx15.schedules = NSOrderedSet(array: schedules)
                        self.saveContext(context)
                    }
                } catch let jsonError as NSError {
                    print(jsonError)
                }
            }
        }
    }
    
    private func getOrCreateDevoxx15(inContext context: NSManagedObjectContext) -> Conference? {
        let request = NSFetchRequest(entityName: "Conference")
        request.predicate = NSPredicate(format: "eventCode=%@", "DV15")
        var devoxx15: Conference?
        
        context.performBlockAndWait {
            () -> Void in
            do {
                let results = try context.executeFetchRequest(request)
                if results.count > 0 {
                    devoxx15 = results[0] as? Conference
                } else {
                    devoxx15 = NSEntityDescription.insertNewObjectForEntityForName("Conference", inManagedObjectContext: context) as? Conference
                    devoxx15!.eventCode = "DV15"
                    devoxx15!.label = "Devoxx 2015"
                    devoxx15!.localisation = "Antwerp, Belgium"
                    self.saveContext(context)
                }
            } catch let error as NSError {
                print(error)
            }
        }
        
        return devoxx15
    }
    
    private func getOrCreateScheduleForHref(href: String, inContext context: NSManagedObjectContext) -> Schedule? {
        var schedule: Schedule?
        context.performBlockAndWait {
            () -> Void in
            let request = NSFetchRequest(entityName: "Schedule")
            request.predicate = NSPredicate(format: "href=%@", href)
            do {
                let results = try context.executeFetchRequest(request)
                if results.count > 0 {
                    schedule = results[0] as? Schedule
                } else {
                    schedule = NSEntityDescription.insertNewObjectForEntityForName("Schedule", inManagedObjectContext: context) as? Schedule
                    schedule!.href = href
                    self.saveContext(context)
                }
            } catch let error as NSError {
                print(error)
            }
        }
        return schedule
    }
}

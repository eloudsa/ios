//
//  DevoxxCache.swift
//  Smartvoxx
//
//  Created by Sebastien Arbogast on 26/10/2015.
//  Copyright © 2015 Epseelon. All rights reserved.
//

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
    
    func saveSchedulesFromData(data: NSData) {
        self.saveSchedulesFromData(data, inContext: self.privateObjectContext)
    }
    
    private func getSchedules(fromContext context: NSManagedObjectContext) -> [Schedule] {
        var schedules = [Schedule]()
        
        context.performBlockAndWait {
            () -> Void in
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
    
    private func saveSchedulesFromData(data: NSData, inContext context: NSManagedObjectContext) {
        context.performBlockAndWait {
            () -> Void in
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
    
    func getSlotsForScheduleWithHref(href: String) -> [Slot] {
        return self.getSlotsForScheduleWithHref(href, fromContext: self.mainObjectContext)
    }
    
    private func getSlotsForScheduleWithHref(href: String, fromContext context: NSManagedObjectContext) -> [Slot] {
        var slots = [Slot]()
        
        context.performBlockAndWait {
            () -> Void in
            let request = NSFetchRequest(entityName: "Schedule")
            request.predicate = NSPredicate(format: "href=%@", href)
            do {
                let results = try context.executeFetchRequest(request)
                if results.count > 0 {
                    if let schedule = results[0] as? Schedule {
                        slots = schedule.slots!.array as! [Slot]
                    }
                }
            } catch {
                print(error)
            }
        }
        
        return slots
    }
    
    func saveSlotsFromData(data: NSData, forScheduleWithHref href: String) {
        self.saveSlotsFromData(data, forScheduleWithHref: href, inContext: self.privateObjectContext)
    }
    
    private func configureSlot(slot: Slot, withData slotDict: NSDictionary, inSchedule schedule: Schedule) {
        slot.slotId = slotDict["slotId"] as? String
        slot.roomId = slotDict["roomId"] as? String
        slot.roomName = slotDict["roomName"] as? String
        slot.day = slotDict["day"] as? String
        slot.fromTime = slotDict["fromTime"] as? String
        slot.toTime = slotDict["toTime"] as? String
        slot.fromTimeMillis = slotDict["fromTimeMillis"] as? NSNumber
        slot.toTimeMillis = slotDict["toTimeMillis"] as? NSNumber
        slot.schedule = schedule
    }
    
    private func getOrCreateBreakSlotWithBreakId(breakId: String, inContext context: NSManagedObjectContext) -> BreakSlot? {
        var breakSlot: BreakSlot?
        context.performBlockAndWait {
            () -> Void in
            let request = NSFetchRequest(entityName: "BreakSlot")
            request.predicate = NSPredicate(format: "breakId=%@", breakId)
            do {
                let results = try context.executeFetchRequest(request)
                if results.count > 0 {
                    if let slot = results[0] as? BreakSlot {
                        breakSlot = slot
                    }
                } else {
                    breakSlot = NSEntityDescription.insertNewObjectForEntityForName("BreakSlot", inManagedObjectContext: context) as? BreakSlot
                    breakSlot?.breakId = breakId
                    self.saveContext(context)
                }
            } catch {
                print(error)
            }
        }
        return breakSlot
    }
    
    private func getOrCreateTalkSlotWithTalkId(talkId: String, inContext context: NSManagedObjectContext) -> TalkSlot? {
        var talkSlot: TalkSlot?
        context.performBlockAndWait {
            () -> Void in
            let request = NSFetchRequest(entityName: "TalkSlot")
            request.predicate = NSPredicate(format: "talkId=%@", talkId)
            do {
                let results = try context.executeFetchRequest(request)
                if results.count > 0 {
                    if let slot = results[0] as? TalkSlot {
                        talkSlot = slot
                    }
                } else {
                    talkSlot = NSEntityDescription.insertNewObjectForEntityForName("TalkSlot", inManagedObjectContext: context) as? TalkSlot
                    talkSlot?.talkId = talkId
                    self.saveContext(context)
                }
            } catch {
                print(error)
            }
        }
        return talkSlot
    }
    
    private func getOrCreateSlotWithSlotId(slotId: String, inContext context: NSManagedObjectContext) -> Slot? {
        var slot: Slot?
        context.performBlockAndWait {
            () -> Void in
            let request = NSFetchRequest(entityName: "Slot")
            request.predicate = NSPredicate(format: "slotId=%@", slotId)
            do {
                let results = try context.executeFetchRequest(request)
                if results.count > 0 {
                    if let result = results[0] as? Slot {
                        slot = result
                    }
                } else {
                    slot = NSEntityDescription.insertNewObjectForEntityForName("Slot", inManagedObjectContext: context) as? Slot
                    slot?.slotId = slotId
                    self.saveContext(context)
                }
            } catch {
                print(error)
            }
        }
        return slot
    }
    
    private func getOrCreateTrackWithName(name: String, inContext context: NSManagedObjectContext) -> Track? {
        var track: Track?
        context.performBlockAndWait {
            () -> Void in
            let request = NSFetchRequest(entityName: "Track")
            request.predicate = NSPredicate(format: "name=%@", name)
            do {
                let results = try context.executeFetchRequest(request)
                if results.count > 0 {
                    if let result = results[0] as? Track {
                        track = result
                    }
                } else {
                    var error: NSError?
                    request.predicate = nil
                    let count = context.countForFetchRequest(request, error: &error)
                    
                    track = NSEntityDescription.insertNewObjectForEntityForName("Track", inManagedObjectContext: context) as? Track
                    track?.name = name
                    track?.color = DataController.flatUiColors[count % DataController.flatUiColors.count]
                    self.saveContext(context)
                }
            } catch {
                print(error)
            }
        }
        return track
    }
    
    private func getOrCreateSpeakerWithHref(href: String, inContext context: NSManagedObjectContext) -> Speaker? {
        var speaker: Speaker?
        
        context.performBlockAndWait {
            () -> Void in
            let request = NSFetchRequest(entityName: "Speaker")
            request.predicate = NSPredicate(format: "href=%@", href)
            do {
                let results = try context.executeFetchRequest(request)
                if results.count > 0 {
                    if let result = results[0] as? Speaker {
                        speaker = result
                    }
                } else {
                    speaker = NSEntityDescription.insertNewObjectForEntityForName("Speaker", inManagedObjectContext: context) as? Speaker
                    speaker?.href = href
                    self.saveContext(context)
                }
            } catch {
                print(error)
            }
        }
        
        return speaker
    }
    
    private func saveSlotsFromData(data: NSData, forScheduleWithHref href: String, inContext context: NSManagedObjectContext) {
        context.performBlockAndWait {
            () -> Void in
            if data.length > 0 {
                guard let schedule = self.getOrCreateScheduleForHref(href, inContext: context) else {
                    return
                }
                do {
                    let scheduleDict = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                    if let scheduleDict = scheduleDict as? NSDictionary {
                        if let slotsArray = scheduleDict["slots"] as? NSArray {
                            var slots = [Slot]()
                            for slotDict in slotsArray {
                                if let slotDict = slotDict as? NSDictionary {
                                    if let breakSlotDict = slotDict["break"] as? NSDictionary {
                                        let slot = self.getOrCreateBreakSlotWithBreakId(breakSlotDict["id"] as! String, inContext: context)
                                        self.configureSlot(slot!, withData: slotDict, inSchedule: schedule)
                                        
                                        slot!.breakId = breakSlotDict["id"] as? String
                                        slot!.nameEN = breakSlotDict["nameEN"] as? String
                                        slot!.nameFR = breakSlotDict["nameFR"] as? String
                                        slots.append(slot!)
                                    } else if let talkSlotDict = slotDict["talk"] as? NSDictionary {
                                        let slot = self.getOrCreateTalkSlotWithTalkId(talkSlotDict["id"] as! String, inContext: context)
                                        self.configureSlot(slot!, withData: slotDict, inSchedule: schedule)
                                        
                                        slot!.talkId = talkSlotDict["id"] as? String
                                        slot!.talkType = talkSlotDict["talkType"] as? String
                                        if let track = talkSlotDict["track"] as? String {
                                            slot!.track = self.getOrCreateTrackWithName(track, inContext: context)
                                        }
                                        slot!.summary = talkSlotDict["summary"] as? String
                                        slot!.summaryAsHtml = talkSlotDict["summaryAsHtml"] as? String
                                        slot!.title = talkSlotDict["title"] as? String
                                        slot!.lang = talkSlotDict["lang"] as? String
                                        
                                        for speaker in NSArray(array: slot!.speakers!.allObjects) {
                                            if let speaker = speaker as? Speaker {
                                                speaker.mutableSetValueForKey("talks").removeObject(slot!)
                                            }
                                        }
                                        slot!.setValue(nil, forKey: "speakers")
                                        
                                        if let speakersArray = talkSlotDict["speakers"] as? NSArray {
                                            for speakerDict in speakersArray {
                                                if let speakerDict = speakerDict as? NSDictionary {
                                                    if let linkDict = speakerDict["link"] as? NSDictionary {
                                                        if let href = linkDict["href"] as? String {
                                                            if let speaker = self.getOrCreateSpeakerWithHref(href, inContext: context) {
                                                                speaker.name = speakerDict["name"] as? String
                                                                speaker.href = href
                                                                speaker.mutableSetValueForKey("talks").addObject(slot!)
                                                                slot!.mutableSetValueForKey("speakers").addObject(speaker)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        
                                        slots.append(slot!)
                                    } else {
                                        let slot = self.getOrCreateSlotWithSlotId(slotDict["slotId"] as! String, inContext: context)
                                        self.configureSlot(slot!, withData: slotDict, inSchedule: schedule)
                                        slots.append(slot!)
                                    }
                                }
                            }
                            schedule.slots = NSOrderedSet(array: slots)
                            self.saveContext(context)
                        }
                    }
                } catch let error as NSError {
                    print(error)
                }
            }
        }
    }
    
    func swapFavoriteStatusForTalkSlotWithTalkId(talkId:String) {
        self.swapFavoriteStatusForTalkSlotWithTalkId(talkId, inContext:self.privateObjectContext)
    }
    
    private func swapFavoriteStatusForTalkSlotWithTalkId(talkId:String, inContext context:NSManagedObjectContext) {
        context.performBlockAndWait { () -> Void in
            if let talkSlot = self.getOrCreateTalkSlotWithTalkId(talkId, inContext: context) {
                talkSlot.favorite = NSNumber(bool: !(talkSlot.favorite!.boolValue))
                self.saveContext(context)
            }
        }
    }
    
    func getTalkSlotWithTalkId(talkId:String) -> TalkSlot? {
        return self.getOrCreateTalkSlotWithTalkId(talkId, inContext: self.mainObjectContext)
    }
    
    func getSpeakerWithHref(href:String) -> Speaker? {
        return self.getOrCreateSpeakerWithHref(href, inContext: self.mainObjectContext)
    }
    
    func saveSpeakerFromData(data:NSData, forSpeakerWithHref href:String){
        self.saveSpeakerFromData(data, forSpeakerWithHref:href, inContext:self.privateObjectContext)
    }
    
    private func saveSpeakerFromData(data:NSData, forSpeakerWithHref href:String, inContext context:NSManagedObjectContext) {
        context.performBlockAndWait { () -> Void in
            if data.length > 0 {
                do {
                    let speakerDict = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
                    if let speakerDict = speakerDict as? NSDictionary {
                        if let speaker = self.getOrCreateSpeakerWithHref(href, inContext: context) {
                            speaker.uuid = speakerDict["uuid"] as? String
                            speaker.bioAsHtml = speakerDict["bioAsHtml"] as? String
                            speaker.company = speakerDict["company"] as? String
                            speaker.bio = speakerDict["bio"] as? String
                            speaker.firstName = speakerDict["firstName"] as? String
                            speaker.lastName = speakerDict["lastName"] as? String
                            speaker.avatarURL = speakerDict["avatarURL"] as? String
                            
                            self.saveContext(context)
                        }
                    }
                } catch let error as NSError {
                    print(error)
                }
            }
        }
    }
    
    func saveAvatarFromData(data:NSData, forSpeakerWithHref href:String) {
        self.saveAvatarFromData(data, forSpeakerWithHref: href, inContext:self.privateObjectContext)
    }
    
    private func saveAvatarFromData(data:NSData, forSpeakerWithHref href:String, inContext context:NSManagedObjectContext) {
        context.performBlockAndWait { () -> Void in
            if let speaker = self.getOrCreateSpeakerWithHref(href, inContext: context) {
                speaker.avatar = data
                self.saveContext(context)
            }
        }
    }
    
    func getAvatarForSpeakerWithHref(href:String) -> NSData? {
        if let speaker = self.getSpeakerWithHref(href) {
            return speaker.avatar
        } else {
            return nil
        }
    }
    
    func getFavoriteSlotsAfterDate(date:NSDate) -> [TalkSlot] {
        let request = NSFetchRequest(entityName: "TalkSlot")
        request.predicate = NSPredicate(format: "favorite==1 and fromTimeMillis>%i", date.timeIntervalSince1970 * 1000)
        request.sortDescriptors = [NSSortDescriptor(key: "fromTimeMillis", ascending: true)]
        do {
            let results = try self.mainObjectContext.executeFetchRequest(request)
            return (results as? [TalkSlot])!
        } catch let error as NSError {
            print(error)
            return [TalkSlot]()
        }
    }
    
    func swapFavoriteStatusForTalkSlotWithId(id: String, favorite: Bool) -> Void {
        self.privateObjectContext.performBlockAndWait { () -> Void in
            if let talkSlot = self.getOrCreateTalkSlotWithTalkId(id, inContext: self.privateObjectContext) {
                talkSlot.favorite = NSNumber(bool: favorite)
                self.saveContext(self.privateObjectContext)
            }
        }
    }
}

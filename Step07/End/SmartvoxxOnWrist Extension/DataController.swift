//
//  DataController.swift
//  Smartvoxx
//
//  Created by Sebastien Arbogast on 26/10/2015.
//  Copyright © 2015 Epseelon. All rights reserved.
//

import UIKit

class DataController: NSObject {
    static let flatUiColors = ["#1abc9c", "#2ecc71", "#3498db", "#9b59b6", "#34495e", "#f1c40f", "#e67e22", "#e74c3c", "#ecf0f1", "#95a5a6", "#16a085", "#27ae60", "#2980b9", "#8e44ad", "#2c3e50", "#f39c120", "#d35400", "#c0392b", "#bdc3c7", "#7f8c8d"]
    
    static var sharedInstance = DataController()
    
    private var session:NSURLSession
    private var cache:DevoxxCache
    
    private var schedulesTask:NSURLSessionDataTask?
    private var slotsTasks = [String:NSURLSessionDataTask]()
    private var speakerTasks = [String:NSURLSessionDataTask]()
    private var avatarTasks = [String:NSURLSessionDataTask]()
    
    private override init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.requestCachePolicy = .ReloadIgnoringLocalCacheData
        session = NSURLSession(configuration: configuration)
        
        cache = DevoxxCache()
    }
    
    private func cancelTask(task: NSURLSessionDataTask?) {
        if let task = task {
            if task.state == NSURLSessionTaskState.Running {
                task.cancel()
            }
        }
    }
    
    func getSchedules(callback:([Schedule] -> Void)) {
        let schedules = cache.getSchedules()
        if schedules.count > 0 {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                callback(schedules)
            })
        }
        
        let url = (NSURL(string: "http://cfp.devoxx.be/api/conferences/DV15/schedules/"))!
        self.schedulesTask = self.session.dataTaskWithURL(url) { (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
            
            guard let data = data else {
                print(error)
                return
            }
            self.cache.saveSchedulesFromData(data)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                callback(self.cache.getSchedules())
            })
        }
        self.schedulesTask?.resume()
    }
    
    func cancelSchedules() {
        cancelTask(self.schedulesTask)
    }
    
    func getSlotsForSchedule(schedule:Schedule, callback:([Slot] -> Void)) {
        let slots = cache.getSlotsForScheduleWithHref(schedule.href!)
        if slots.count > 0 {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                callback(slots)
            })
        }
        
        let url = NSURL(string: schedule.href!)!
        let task = self.session.dataTaskWithURL(url) { (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
            
            guard let data = data else {
                print(error)
                return
            }
            self.cache.saveSlotsFromData(data, forScheduleWithHref:schedule.href!)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                callback(self.cache.getSlotsForScheduleWithHref(schedule.href!))
            })
        }
        self.slotsTasks[schedule.href!] = task
        task.resume()
    }
    
    func cancelSlotsForSchedule(schedule:Schedule) {
        if let href = schedule.href, task = self.slotsTasks[href] {
            self.cancelTask(task)
        }
    }
    
    func swapFavoriteStatusForTalkSlot(talkSlot:TalkSlot, callback:(TalkSlot -> Void)){
        cache.swapFavoriteStatusForTalkSlotWithTalkId(talkSlot.talkId!)
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if let talkSlot = self.cache.getTalkSlotWithTalkId(talkSlot.talkId!) {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    callback(talkSlot)
                })
            }
        }
    }

    func getSpeaker(speaker:Speaker, callback:(Speaker -> Void)){
        if let speaker = cache.getSpeakerWithHref(speaker.href!), _ = speaker.firstName {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                callback(speaker)
            })
        }
        
        let url = NSURL(string: speaker.href!)!
        let task = self.session.dataTaskWithURL(url, completionHandler: { (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
            guard let data = data else {
                print(error)
                return
            }
            
            self.cache.saveSpeakerFromData(data, forSpeakerWithHref:speaker.href!)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let speaker = self.cache.getSpeakerWithHref(speaker.href!) {
                    callback(speaker)
                }
            })
        })
        self.speakerTasks[speaker.href!] = task
        task.resume()
    }
    
    func cancelSpeaker(speaker:Speaker){
        if let task = self.speakerTasks[speaker.href!] {
            self.cancelTask(task)
        }
    }
    
    func getAvatarForSpeaker(speaker:Speaker, callback:(NSData -> Void)) {
        if let speaker = cache.getSpeakerWithHref(speaker.href!), avatar = speaker.avatar where avatar.length > 0 {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                callback(avatar)
            })
        }
        
        let url = NSURL(string: speaker.avatarURL!)!
        let task = self.session.dataTaskWithURL(url, completionHandler: { (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
            guard let data = data where data.length > 0 else {
                print(error)
                return
            }
            
            self.cache.saveAvatarFromData(data, forSpeakerWithHref:speaker.href!)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let avatarData = self.cache.getAvatarForSpeakerWithHref(speaker.href!) {
                    callback(avatarData)
                }
            })
        })
        self.avatarTasks[speaker.avatarURL!] = task
        task.resume()
    }
    
    func cancelAvatarForSpeaker(speaker:Speaker){
        if let task = self.avatarTasks[speaker.href!] {
            self.cancelTask(task)
        }
    }
    
    func getFavoriteTalksAfterDate(date: NSDate) -> [TalkSlot] {
        return cache.getFavoriteTalksAfterDate(date)
    }
    
    func getFavoriteTalksBeforeDate(date: NSDate) -> [TalkSlot] {
        return cache.getFavoriteTalksBeforeDate(date)
    }
    
    func getFirstTalk() -> TalkSlot? {
        return cache.getFirstTalk()
    }
    
    func getLastTalk() -> TalkSlot? {
        return cache.getLastTalk()
    }
}

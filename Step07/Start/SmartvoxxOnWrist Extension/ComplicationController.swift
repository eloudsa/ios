//
//  ComplicationController.swift
//  SmartvoxxOnWrist Extension
//
//  Created by Sebastien Arbogast on 23/08/2015.
//  Copyright © 2015 Epseelon. All rights reserved.
//

import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // MARK: - Timeline Configuration
    
    func getSupportedTimeTravelDirectionsForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.Forward, .Backward])
    }
    
    func getTimelineStartDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        if let firstTalk = DataController.sharedInstance.getFirstTalk() {
            handler(NSDate(timeIntervalSince1970: firstTalk.fromTimeMillis!.doubleValue / 1000))
        } else {
            handler(nil)
        }
    }
    
    func getTimelineEndDateForComplication(complication: CLKComplication, withHandler handler: (NSDate?) -> Void) {
        if let lastTalk = DataController.sharedInstance.getLastTalk() {
            handler(NSDate(timeIntervalSince1970: lastTalk.toTimeMillis!.doubleValue / 1000))
        } else {
            handler(nil)
        }
    }
    
    func getPrivacyBehaviorForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.ShowOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntryForComplication(complication: CLKComplication, withHandler handler: ((CLKComplicationTimelineEntry?) -> Void)) {
        // Call the handler with the current timeline entry
        handler(self.timelineEntryForNextFavoriteTalk())
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, beforeDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        var entries = [CLKComplicationTimelineEntry]()
        
        let pastTalks = DataController.sharedInstance.getFavoriteTalksBeforeDate(date)
        var count = 0
        for pastTalk in pastTalks {
            let template = CLKComplicationTemplateModularLargeStandardBody()
            template.headerTextProvider = CLKTimeIntervalTextProvider(startDate: NSDate(timeIntervalSince1970: pastTalk.fromTimeMillis!.doubleValue / 1000), endDate: NSDate(timeIntervalSince1970: pastTalk.toTimeMillis!.doubleValue / 1000))
            template.body1TextProvider = CLKSimpleTextProvider(text: pastTalk.title!)
            template.body2TextProvider = CLKSimpleTextProvider(text: pastTalk.roomName!)
            let entry = CLKComplicationTimelineEntry(date: NSDate(timeIntervalSince1970: pastTalk.toTimeMillis!.doubleValue / 1000), complicationTemplate: template)
            entries.append(entry)
            count++
            if count > limit {
                break
            }
        }
        
        handler(entries)
    }
    
    func getTimelineEntriesForComplication(complication: CLKComplication, afterDate date: NSDate, limit: Int, withHandler handler: (([CLKComplicationTimelineEntry]?) -> Void)) {
        var entries = [CLKComplicationTimelineEntry]()
        
        let futureTalks = DataController.sharedInstance.getFavoriteTalksAfterDate(date)
        var count = 0
        for futureTalk in futureTalks {
            let template = CLKComplicationTemplateModularLargeStandardBody()
            template.headerTextProvider = CLKTimeIntervalTextProvider(startDate: NSDate(timeIntervalSince1970: futureTalk.fromTimeMillis!.doubleValue / 1000), endDate: NSDate(timeIntervalSince1970: futureTalk.toTimeMillis!.doubleValue / 1000))
            template.body1TextProvider = CLKSimpleTextProvider(text: futureTalk.title!)
            template.body2TextProvider = CLKSimpleTextProvider(text: futureTalk.roomName!)
            let entry = CLKComplicationTimelineEntry(date: NSDate(timeIntervalSince1970: futureTalk.fromTimeMillis!.doubleValue / 1000).dateByAddingTimeInterval(-600), complicationTemplate: template)
            entries.append(entry)
            count++
            if count > limit {
                break
            }
        }
        
        handler(entries)
    }
    
    // MARK: - Update Scheduling
    
    func getNextRequestedUpdateDateWithHandler(handler: (NSDate?) -> Void) {
        // Call the handler with the date when you would next like to be given the opportunity to update your complication content
        handler(NSDate().dateByAddingTimeInterval(60));
    }
    
    // MARK: - Placeholder Templates
    
    func getPlaceholderTemplateForComplication(complication: CLKComplication, withHandler handler: (CLKComplicationTemplate?) -> Void) {
        let headerTextProvider = CLKSimpleTextProvider(text: NSLocalizedString("Devoxx 2015", comment:""))
        let bodyTextProvider = CLKSimpleTextProvider(text: NSLocalizedString("20 years of Java, Just the Beginning", comment:""), shortText: NSLocalizedString("20 years of Java", comment:""))
        let template = CLKComplicationTemplateModularLargeStandardBody()
        template.headerTextProvider = headerTextProvider
        template.body1TextProvider = bodyTextProvider
        handler(template)
    }
    
    private func timelineEntryForNextFavoriteTalk() -> CLKComplicationTimelineEntry? {
        let template = CLKComplicationTemplateModularLargeStandardBody()
        let now = NSDate()
        
        if let firstTalk = DataController.sharedInstance.getFirstTalk() {
            //Data has already been loaded into cache
            if now.timeIntervalSince1970 * 1000 < firstTalk.fromTimeMillis!.doubleValue {
                //We are before Devoxx 2015
                template.headerTextProvider = CLKRelativeDateTextProvider(date: NSDate(timeIntervalSince1970: firstTalk.fromTimeMillis!.doubleValue / 1000), style: .Natural, units: [.Day, .Hour])
                template.body1TextProvider = CLKSimpleTextProvider(text: NSLocalizedString("until Devoxx 2015", comment:""))
            } else if let lastTalk = DataController.sharedInstance.getLastTalk() {
                //We are either after or during Devoxx 2015
                if now.timeIntervalSince1970 * 1000 > lastTalk.toTimeMillis!.doubleValue {
                    //We are after Devoxx 2015
                    template.headerTextProvider = CLKSimpleTextProvider(text: NSLocalizedString("Devoxx 2015 is over", comment:""))
                    template.body1TextProvider = CLKSimpleTextProvider(text: NSLocalizedString("See you next year!", comment:""))
                } else {
                    //We are during Devoxx 2015
                    let nextFavoriteTalks = DataController.sharedInstance.getFavoriteTalksAfterDate(now)
                    if nextFavoriteTalks.count > 0 {
                        //There is an upcoming favorite talk
                        template.headerTextProvider = CLKRelativeDateTextProvider(date: NSDate(timeIntervalSince1970: nextFavoriteTalks[0].fromTimeMillis!.doubleValue / 1000), style: .Natural, units: [.Day, .Hour, .Minute])
                        template.body1TextProvider = CLKSimpleTextProvider(text: nextFavoriteTalks[0].title!)
                        template.body2TextProvider = CLKSimpleTextProvider(text: nextFavoriteTalks[0].roomName!)
                    } else {
                        //There is no upcoming talk anymore
                        template.headerTextProvider = CLKSimpleTextProvider(text: NSLocalizedString("Devoxx 2015", comment:""))
                        template.body1TextProvider = CLKSimpleTextProvider(text: NSLocalizedString("No more upcoming favorite talk", comment:""))
                    }
                }
            }
        } else {
            //Data has not been loaded into cache yet
            template.headerTextProvider = CLKSimpleTextProvider(text: NSLocalizedString("Devoxx 2015", comment:""))
            template.body1TextProvider = CLKSimpleTextProvider(text: NSLocalizedString("Launch Smartvoxx to load Devoxx 2015 schedule", comment:""), shortText: NSLocalizedString("Launch Smartvoxx", comment:""))
        }
        
        return CLKComplicationTimelineEntry(date: now.dateByAddingTimeInterval(-60), complicationTemplate: template)
    }
}

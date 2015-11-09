//
//  TalkSlot+CoreDataProperties.swift
//  Smartvoxx
//
//  Created by Sebastien Arbogast on 11/10/2015.
//  Copyright © 2015 Epseelon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension TalkSlot {

    @NSManaged var lang: String?
    @NSManaged var summary: String?
    @NSManaged var summaryAsHtml: String?
    @NSManaged var talkId: String?
    @NSManaged var talkType: String?
    @NSManaged var title: String?
    @NSManaged var favorite: NSNumber?
    @NSManaged var speakers: NSSet?
    @NSManaged var track: Track?

}

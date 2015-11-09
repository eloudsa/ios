//
//  Slot+CoreDataProperties.swift
//  Smartvoxx
//
//  Created by Sebastien Arbogast on 04/10/2015.
//  Copyright © 2015 Epseelon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Slot {

    @NSManaged var slotId: String?
    @NSManaged var roomId: String?
    @NSManaged var roomName: String?
    @NSManaged var day: String?
    @NSManaged var fromTime: String?
    @NSManaged var toTime: String?
    @NSManaged var fromTimeMillis: NSNumber?
    @NSManaged var toTimeMillis: NSNumber?
    @NSManaged var schedule: Schedule?

}

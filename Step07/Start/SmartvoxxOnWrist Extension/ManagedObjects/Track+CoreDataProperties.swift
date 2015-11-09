//
//  Track+CoreDataProperties.swift
//  Smartvoxx
//
//  Created by Sebastien Arbogast on 10/10/2015.
//  Copyright © 2015 Epseelon. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Track {

    @NSManaged var name: String?
    @NSManaged var color: String?
    @NSManaged var talks: NSOrderedSet?

}

//
//  Speaker+CoreDataProperties.swift
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

extension Speaker {

    @NSManaged var avatarURL: String?
    @NSManaged var bio: String?
    @NSManaged var company: String?
    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
    @NSManaged var name: String?
    @NSManaged var href: String?
    @NSManaged var uuid: String?
    @NSManaged var bioAsHtml: String?
    @NSManaged var avatar: NSData?
    @NSManaged var talks: NSSet?

}

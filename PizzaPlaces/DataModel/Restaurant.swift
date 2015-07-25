//
//  Restaurant.swift
//  
//
//  Created by Andrew Zborovskyi on 7/25/15.
//
//

import Foundation
import CoreData

class Restaurant: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var formattedPhone: String
    @NSManaged var formattedAddress: String
    @NSManaged var categoryName: String
    @NSManaged var id: String

}

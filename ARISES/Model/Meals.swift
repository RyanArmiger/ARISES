//
//  Meals.swift
//  ARISES
//
//  Created by Ryan Armiger on 25/05/2018.
//  Copyright © 2018 Ryan Armiger. All rights reserved.
//

import UIKit
import CoreData

/**
 Meals NSManagedObject category/extension file
 - Note: The following auto-generated properties are managed within ARISES.xcdatamodeld:
     fetchRequest(),    
     carbs,
     fat,
     name,
     protein,
     time,
     day,
     favourite
 */
class Meals: NSManagedObject {

    func createEncoded() -> NSMealsEncode? {
        
        // Processing to convert Date to String type for uploading
        // Might be unnecessary for this storage method, but often required when working with APIs that expect dates as Strings
        let dateFormatterUTC = DateFormatter()
        dateFormatterUTC.timeZone = TimeZone(abbreviation: "BST")
        dateFormatterUTC.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        guard let timestampFormattedUTC = dateFormatterUTC.string(for: self.time) else { return nil }
        
        // Create new struct in format for JSON encoding
        let newMeal = NSMealsEncode(times: timestampFormattedUTC,
                                    name: self.name!,
                                    carbs: self.carbs,
                                    protein: self.protein,
                                    fat:self.fat)
        
        return newMeal
    }

}


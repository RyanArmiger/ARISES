//
//  NSUserDefaults.swift
//  xDripG5
//
//  Created by Nathan Racklyeft on 11/24/15.
//  Copyright © 2015 Nathan Racklyeft. All rights reserved.
//

import Foundation

extension UserDefaults {

    var transmitterID: String {
        get {
            return string(forKey: "transmitterID") ?? "500000"
        }
        set {
            set(newValue, forKey: "transmitterID")
        }
    }
    var glucoseUnits: String {
        get {
            return string(forKey: "glucoseUnits") ?? "millimolesPerLiter"
        }
        set {
            set(newValue, forKey: "glucoseUnits")
        }
    }
}

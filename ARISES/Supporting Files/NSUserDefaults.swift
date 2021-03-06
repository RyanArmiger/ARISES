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
    var graphLayout: String {
        get {
            return string(forKey: "graphLayout") ?? "0.33"
        }
        set {
            set(newValue, forKey: "graphLayout")
        }
    }
    var empaticaAPIKey: String {
        get {
            return string(forKey: "empaticaAPIKey") ?? "e317ade3900a4804ba6050da0bd581ae" 
        }
        set {
            set(newValue, forKey: "empaticaAPIKey")
        }
    }
}

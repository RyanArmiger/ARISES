//
//  ChartXAxisFormatter.swift
//  ABC4D
//
//  Created by Ryan Armiger on 22/01/2019.
//  Copyright © 2019 El Sharkawy, Mohamed Fayez. All rights reserved.
//

import Charts
import Foundation
import UIKit

class ChartXAxisFormatter: NSObject {
    fileprivate var dateFormatter: DateFormatter?
    fileprivate var referenceTimeInterval: TimeInterval?
    
    convenience init(referenceTimeInterval: TimeInterval, dateFormatter: DateFormatter) {
        self.init()
        self.referenceTimeInterval = referenceTimeInterval
        self.dateFormatter = dateFormatter
    }
}

extension ChartXAxisFormatter: IAxisValueFormatter {
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        guard let dateFormatter = dateFormatter,
            let referenceTimeInterval = referenceTimeInterval
            else {
                return ""
        }
        
        let date = Date(timeIntervalSince1970: value * 3_600 * 24 + referenceTimeInterval)
        return dateFormatter.string(from: date)
    }
    
}

//
//  ModelFunctions.swift
//  ABC4D
//
//  Created by Ryan Armiger on 31/03/2019.
//  Copyright © 2019 El Sharkawy, Mohamed Fayez. All rights reserved.
//

import Foundation
import UIKit

//struct SubmissionsTable {
//    let timeStamp: Date
//    let glucose: Float
//    let carbohydrate: Float
//    let bolus: Float
//    let correctionBolus: Float
//    let adjustmentDoseROC: Float
//    let corrBolusIOB: Float
//    let mealBolus: Float
//    let mealBolusIOB: Float
//    let bolusUser: Float
//}
//
//struct ContinuousVariables {
//    let timeStamp: Date
//    let glucose: Float?
//    let ROC: Float
//    let corrBolusIOB: Float
//    let mealBolusIOB: Float
//    let variableGlucoseTarget: Float
//}
// swiftlint:disable:next function_parameter_count
func calculateInsulinOnBoard(currentTimeStamp: Date,
                             decayTimeIOB: Float,
                             submissionTimeStamp: Date,
                             corrBolus: Float,
                             mealBolus: Float,
                             corrBolusIOB: Float,
                             mealBolusIOB: Float,
                             bolus: Float,
                             bolusUser: Float
    ) -> (Float, Float) {
    var corrBolusIOBout: Float
    var mealBolusIOBout: Float
    
    if bolus != 0 {
        corrBolusIOBout = max(0, corrBolus / bolus * bolusUser) + corrBolusIOB
        mealBolusIOBout = mealBolus / bolus * bolusUser + mealBolusIOB
    } else {
        corrBolusIOBout = bolusUser + corrBolusIOB
        mealBolusIOBout = mealBolusIOB
    }
    //CHECK HOW THIS DATE COMPONENT WORKS
    let intervalComponents = Calendar.current.dateComponents([.minute, .hour], from: currentTimeStamp, to: submissionTimeStamp)
    guard let intervalMin = intervalComponents.value(for: .minute) else {
        //This should never occur given valid dates
        // Either an unlikely value should be returned and checked or this function should throw
        print("ERROR: Could not convert date min in IOB calculation")
//        DebugAlerts().testAlert(error: "Could not convert date min in IOB calculation")

        return (0, 0)
    }
    guard let intervalHour = intervalComponents.value(for: .hour) else {
        //This should never occur given valid dates
        // Either an unlikely value should be returned and checked or this function should throw
        print("ERROR: Could not convert date hour in IOB calculation")
//        DebugAlerts().testAlert(error: "Could not convert date hour in IOB calculation")
        return (0, 0)
    }
    let interval = abs(intervalMin + intervalHour * 60)
    let decay = Float(1) - (Float(interval) / (decayTimeIOB * 60))
    corrBolusIOBout = max(corrBolusIOBout * (decay), 0)
    mealBolusIOBout = max(mealBolusIOBout * (decay), 0)
    
    return (corrBolusIOBout, mealBolusIOBout)
}

func calculateVariableGlucoseTarget(timeStamp: Date, mealTime: Date, mealGlucose: Float, mealCarbohydrates: Int, lowGlucoseTarget: Float, highGlucoseTarget: Float, mealTimeGlucoseTarget: Float) -> Float {

    let variableGlucoseTarget: Float
    var mealTimeGlucoseTargetVar = mealTimeGlucoseTarget
    
    //Defined but never used?
//    let glucoseTarget = (highGlucoseTarget + lowGlucoseTarget) / 2
    
    let reduction = Float( 1 - max(0, (mealGlucose - highGlucoseTarget) / highGlucoseTarget) )
    let gain: Float = 1.3
    mealTimeGlucoseTargetVar = mealGlucose + reduction * gain * Float(mealCarbohydrates)
//    if mealCarbohydrates > 100 {
//        mealTimeGlucoseTargetVar = mealTimeGlucoseTarget * 1.2
//    } else if mealCarbohydrates > 30 {
//        mealTimeGlucoseTargetVar = mealTimeGlucoseTarget * 0.8
//    }
    
//    mealTimeGlucoseTargetVar += max(0, (mealGlucose - highGlucoseTarget))
    let timeFromMealComponents = Calendar.current.dateComponents([.minute, .hour], from: timeStamp, to: mealTime)
    guard let timeFromMealMin = timeFromMealComponents.value(for: .minute) else {
        //This should never occur given valid dates
        // Either an unlikely value should be returned and checked or this function should throw
        print("ERROR: Could not convert date in Glucose target calculation")
//        DebugAlerts().testAlert(error: "Could not convert date in Glucose target calculation")
        return 0
    }
    guard let timeFromMealHour = timeFromMealComponents.value(for: .hour) else {
        //This should never occur given valid dates
        // Either an unlikely value should be returned and checked or this function should throw
        print("ERROR: Could not convert date in Glucose target calculation")
//        DebugAlerts().testAlert(error: "convert date in Glucose target calculation")

        return 0
    }
    //    let timeTest = timeFromMealMin
    //    let timeTestHour = timeFromMealHour
    let timeFromMeal = abs(timeFromMealMin + (60 * timeFromMealHour))
    if timeFromMeal <= 60 {
        variableGlucoseTarget = mealTimeGlucoseTargetVar
    } else if timeFromMeal > 60 && timeFromMeal < 240 {
        //Should this use highGlucoseTarget?
        variableGlucoseTarget = mealTimeGlucoseTargetVar + (highGlucoseTarget - mealTimeGlucoseTargetVar) / 180 * Float(timeFromMeal - 60)
    } else {
        //Should this use highGlucoseTarget?
        variableGlucoseTarget = highGlucoseTarget
    }
    
    return variableGlucoseTarget
}

enum icrError: Error {
    case daySegmentNotSet
    case exerciseSegmentNotSet
    case hourValueConversionFailed
}

func retrieveICR(ICRs: [[Int]], timeStamp: Date, preExercise: Bool, postExercise: Bool) throws  -> Int {

    let currentHourComponent = Calendar.current.dateComponents([.hour], from: timeStamp)
    guard let currentHour = currentHourComponent.value(for: .hour) else {
        print("ERROR: Could not convert date in retriveICR")

        throw icrError.hourValueConversionFailed
    }

    var daySegment = 0
    var exercise = 0

    if currentHour >= 5 && currentHour < 11 {
        daySegment = 1
    } else if currentHour >= 11 && currentHour < 17 {
        daySegment = 2
    } else if currentHour >= 17
              && currentHour < 24
              || currentHour >= 0
              && currentHour < 5 {
        daySegment = 3
    } else {
        print("ICR day segment not selected from within times given. Defaulted to segment 3")
        
        daySegment = 3
    }

    if preExercise == true || postExercise == true {
        print("In exercise 2")
        exercise = 2
    } else {
        print("In exercise 1")
        exercise = 1
    }
    
    if daySegment == 0 || exercise == 0 {
        print("ERROR: daySegment: \(daySegment) or exercise: \(exercise) not set")
        if daySegment == 0 {
            throw icrError.daySegmentNotSet
        } else {
            throw icrError.exerciseSegmentNotSet
        }
    }
    let ICR = ICRs[exercise - 1][daySegment - 1]

    print(ICR)
    return (ICR)
}

//func retrieveICR(ICRs: [[Int]], timeStamp: Date, preExercise: Bool, postExercise: Bool) -> (Int, String) {
//    let submissionTypeArr = [["Breakfast", "Lunch", "Dinner"],
//                             ["Breakfast", "Lunch", "Dinner"]]
//    let currentHourComponent = Calendar.current.dateComponents([.hour], from: timeStamp)
//    guard let currentHour = currentHourComponent.value(for: .hour) else {
//        print("ERROR: Could not convert date in retriveICR")
//        return (-1, "")
//    }
//    var daySegment = 0
//    var exercise = 0
//    if currentHour >= 5 && currentHour < 11 {
//        daySegment = 1
//    } else if currentHour >= 11 && currentHour < 17 {
//        daySegment = 2
//    } else if currentHour >= 17 && currentHour < 24 {
//        daySegment = 3
//    } else if currentHour > 0 && currentHour < 5 {
//        daySegment = 3
//    }
//
//    if preExercise || postExercise {
//        exercise = 2
//    } else {
//        exercise = 1
//    }
//
//    if daySegment == 0 || exercise == 0 {
//        print("ERROR: daySegment: \(daySegment) or exercise: \(exercise) not set")
//        return (-1, "")
//    }
//    let ICR = ICRs[exercise - 1][daySegment - 1]
//    let submissionType = submissionTypeArr[exercise - 1][daySegment - 1]
//    return (ICR, submissionType)
//}

func retrieveISF(ISFs: [Float], isfTimes: [[Date]], timeStamp: Date) -> Float {
    var calendarUTC = Calendar.current
    //Need to adjust this based on server timezone?
    calendarUTC.timeZone = TimeZone(secondsFromGMT: 3600)!
    
    let currentHourComponent = Calendar.current.dateComponents([.hour, .minute], from: timeStamp)
    guard let currentHour = currentHourComponent.value(for: .hour) else {
        print("ERROR: Could not convert date in retriveISF")
//        DebugAlerts().testAlert(error: "Could not convert date in retriveISF")

        return 0
    }
//    guard let currentMinute = currentHourComponent.value(for: .minute) else {
//        print("ERROR: Could not convert minute in retriveISF")
//        DebugAlerts().testAlert(error: "Could not convert minute in retriveISF")
//
//        return 0
//    }
    
    // Should probably pass this is a safer way

    if let isfOneStart = (calendarUTC.dateComponents([.hour], from: isfTimes[0][0])).value(for: .hour) {
        if let isfOneEnd = (calendarUTC.dateComponents([.hour], from: isfTimes[0][1])).value(for: .hour) {
            if let isfTwoStart = (calendarUTC.dateComponents([.hour], from: isfTimes[1][0])).value(for: .hour) {
                if let isfTwoEnd = (calendarUTC.dateComponents([.hour], from: isfTimes[1][1])).value(for: .hour) {
                    if let isfThreeStart = (calendarUTC.dateComponents([.hour], from: isfTimes[2][0])).value(for: .hour) {
                        if let isfThreeEnd = (calendarUTC.dateComponents([.hour], from: isfTimes[2][1])).value(for: .hour) {
                            
                            if currentHour >= isfOneStart && currentHour < isfOneEnd {
                                return ISFs[0]
                            } else if currentHour >= isfTwoStart && currentHour < isfTwoEnd {
                                return ISFs[1]
                            } else if currentHour >= isfThreeStart && currentHour < 24 || currentHour >= 0 && currentHour < isfThreeEnd {
                                return ISFs[2]
                            }
                        }
                    }
                }
            }
        }
    }
    print("ERROR: ISF failed to find a time")
//    DebugAlerts().testAlert(error: "ISF failed to find a time")

    // An error here could be because it uses hour times, not anything more precise like half hour or minute increments.
    return -1
}
//Complete once ICR structure decided
// swiftlint:disable:next large_tuple
func calculateBolus(glucose: Float, carbohydrates: Float, ICR: Int, ROC: Float, lowGlucoseTarget: Float, highGlucoseTarget: Float, variableGlucoseTarget: Float, corrBolusIOB: Float) -> ( Float, Float, Float, Float ) {
    print("Glucose used for bolus calc: ", glucose)
    print("highGlucTarget used for bolus calc: ", highGlucoseTarget)
    print("varGlucTarget used for bolus calc: ", variableGlucoseTarget)
    print("lowGlucTarget used for bolus calc: ", lowGlucoseTarget)

    var ISF: Float
    
    
    ISF = (4.44 / 18) * Float(ICR)
    
    var correctionBolus: Float
    var saturatedBolus: Float
    var adjustmentDoseROC: Float
    var mealBolus = carbohydrates / Float(ICR)
//    let ISF = 4.44 * Float(ICR)
    
    if glucose > variableGlucoseTarget {
//        print("Calculating a correction bolus 1")
//        correctionBolus = max(0, (glucose - variableGlucoseTarget) / ISF - corrBolusIOB)
        correctionBolus = (glucose - variableGlucoseTarget) / ISF - corrBolusIOB
    } else if glucose < lowGlucoseTarget {
//        print("Calculating a correction bolus 2")
        let glucoseTarget = (highGlucoseTarget + lowGlucoseTarget) / 2
        correctionBolus = (glucose - glucoseTarget) / ISF
    } else {
//        print("Not calculating a correction bolus ")
        correctionBolus = 0
    }
    
    adjustmentDoseROC = doseAdjustmentROC(ROC: ROC, ISF: ISF)
    
    let bolus = max(0, mealBolus + correctionBolus + adjustmentDoseROC)
    saturatedBolus = round(bolus / 0.5) * 0.5
    
    if saturatedBolus == 0 {
        mealBolus = 0
        correctionBolus = 0
    } else {
        mealBolus = mealBolus / bolus * saturatedBolus
        correctionBolus = correctionBolus / bolus * saturatedBolus
    }
    
    return (saturatedBolus, mealBolus, correctionBolus, adjustmentDoseROC)
}
// swiftlint:disable:next cyclomatic_complexity
func doseAdjustmentROC(ROC: Float, ISF: Float) -> Float {
    var IDA: Float = 0
    
    if ROC > 3 {
        if ISF < 25 {
            IDA = 4.5
        } else if ISF >= 25 && ISF < 50 {
            IDA = 3.5
        } else if ISF >= 50 && ISF < 75 {
            IDA = 2.5
        } else if ISF >= 75 {
            IDA = 1.5
        }
    } else if ROC > 2 && ROC <= 3 {
        if ISF < 25 {
            IDA = 3.5
        } else if ISF >= 25 && ISF < 50 {
            IDA = 2.5
        } else if ISF >= 50 && ISF < 75 {
            IDA = 1.5
        } else if ISF >= 75 {
            IDA = 1
        }
    } else if ROC > 1 && ROC <= 2 {
        if ISF < 25 {
            IDA = 2.5
        } else if ISF >= 25 && ISF < 50 {
            IDA = 1.5
        } else if ISF >= 50 && ISF < 75 {
            IDA = 1
        } else if ISF >= 75 {
            IDA = 0.5
        }
    } else if -1 <= ROC && ROC < 1 {
        IDA = 0
    } else if -2 <= ROC && ROC < -1 {
        if ISF < 25 {
            IDA = -2.5
        } else if ISF >= 25 && ISF < 50 {
            IDA = -1.5
        } else if ISF >= 50 && ISF < 75 {
            IDA = -1
        } else if ISF >= 75 {
            IDA = -0.5
        }
    } else if -3 <= ROC && ROC < -2 {
        if ISF < 25 {
            IDA = -3.5
        } else if ISF >= 25 && ISF < 50 {
            IDA = -2.5
        } else if ISF >= 50 && ISF < 75 {
            IDA = -1.5
        } else if ISF >= 75 {
            IDA = -1
        }
    } else if ROC < -3 {
        if ISF < 25 {
            IDA = -4.5
        } else if ISF >= 25 && ISF < 50 {
            IDA = -3.5
        } else if ISF >= 50 && ISF < 75 {
            IDA = -2.5
        } else if ISF >= 75 {
            IDA = -1.5
        }
    } else {
        IDA = 0
    }
    
    return IDA
}

//func calculateGlucoseRateOfChange (sampleTime: Date, glucoseVector: [Float], numberOfSamples: Int) -> Float {
//    let dimension = glucoseVector.count
//    print("Dimension: ", dimension)
//    print("Samples: ", numberOfSamples)
//    if dimension >= numberOfSamples {
//
//        let time = [0, 5, 10, 15]
//        //Check slice range
//        let tempGlucose = glucoseVector[(dimension - numberOfSamples)..<dimension]
//        print(tempGlucose)
//        let a1Component = (Float(numberOfSamples) * (zip(time, tempGlucose).map { Float($0) * $1 }).reduce(0, +))
//        let a2Component = Float(time.reduce(0, +)) * tempGlucose.reduce(0, +)
//        let bComponent = (numberOfSamples * (zip(time, time).map(*)).reduce(0, +) - (time.reduce(0, +) * (time.reduce(0, +))))
//        print("a1: \(a1Component) a2: \(a2Component) b: \(bComponent)")
//        let glucoseRateOfChange = Float(a1Component - a2Component) / Float(bComponent)
//        return glucoseRateOfChange
//    } else {
//        print("ERROR: Glucose ROC set to 0")
//        DebugAlerts().testAlert(error: "Glucose ROC set to 0")
//        return 0
//    }
//}

func calculateGlucoseRateOfChangeTime (sampleTime: [Date], glucoseVector: [Float], numberOfSamples: Int) -> Float {
    let dimension = glucoseVector.count
    print("Dimension: ", dimension)
    print("Samples: ", numberOfSamples)
    if dimension >= numberOfSamples {
        let timeSampled = sampleTime[(dimension - numberOfSamples)..<dimension]
        let time = timeSampled.map { date -> Int in
            let diffTime = date.timeIntervalSince(timeSampled.first!)
            return Int(round(diffTime / 60))
        }

        print("diffTime: ", time)
        if time != [0, 5, 10, 15] {
            print("Non consecutive glucose values, defaulting to 0 ROC")
            return 0
        }
        //Check slice range
        let tempGlucose = glucoseVector[(dimension - numberOfSamples)..<dimension]
        print(tempGlucose)
        let a1Component = (Float(numberOfSamples) * (zip(time, tempGlucose).map { Float($0) * $1 }).reduce(0, +))
        let a2Component = Float(time.reduce(0, +)) * tempGlucose.reduce(0, +)
        let bComponent = (numberOfSamples * (zip(time, time).map(*)).reduce(0, +) - (time.reduce(0, +) * (time.reduce(0, +))))
        print("a1: \(a1Component) a2: \(a2Component) b: \(bComponent)")
        let glucoseRateOfChange = Float(a1Component - a2Component) / Float(bComponent)
        return glucoseRateOfChange
    } else {
        print("ERROR: Glucose ROC set to 0")
//        DebugAlerts().testAlert(error: "Glucose ROC set to 0")
        return 0
    }
    
}

enum bolusError: Error {
    case noSettings
    case noRecentGlucose
}

func getBolus(carborhydrates: Int = 0) throws -> ( Float, Float, Float, Float, Float, Float ) {
    //* Get settings
    guard let foundSettings = ModelController().fetchSettings() else {
        print("ERROR: Could not fetch settings in getBolus")
        throw bolusError.noSettings
    }
    //* Fetch last insulin
    let lastInsulin = ModelController().fetchLastInsulin()
    // Calculate IOB
    var correctionIOB: Float = 0
    var mealIOB: Float = 0
    if let lastInsulinUnwrapped = lastInsulin {
        (correctionIOB, mealIOB) = calculateInsulinOnBoard(currentTimeStamp: Date(),
                                                           decayTimeIOB: foundSettings.iobTimeDecay,
                                                           submissionTimeStamp: lastInsulinUnwrapped.time!,
                                                           corrBolus: lastInsulinUnwrapped.corrBolus,
                                                           mealBolus: lastInsulinUnwrapped.mealBolus,
                                                           corrBolusIOB: lastInsulinUnwrapped.corrBolusIOB,
                                                           mealBolusIOB: lastInsulinUnwrapped.mealBolusIOB,
                                                           bolus: Float(lastInsulinUnwrapped.units),
                                                           bolusUser: lastInsulinUnwrapped.unitsUser)
    }
    //* Get exercise in last 8 hours  ( + future? )
    let recentExercise = ModelController().recentExercise()
    //* Fetch last 20 minutes of glucose
    let recentGlucose = ModelController().fetchRecentGlucose()
    //TODO: Allow a user to input a recent glucose value
    var lastGlucose: GlucoseMO? = nil
    if !recentGlucose.isEmpty {
        lastGlucose = recentGlucose[0]
    }
    guard let lastGlucoseUnwrapped = lastGlucose else {
        print("ERROR: No recent glucose value")
        throw bolusError.noRecentGlucose
    }
    // Calculate ROC
        // If not possible set to 0
    var ROC: Float = 0
    if recentGlucose.count > 4 || recentGlucose.count < 4 {
        print("Recent glucose count = \(recentGlucose.count)")
    } else {
        let recentGlucoseVal = recentGlucose.map { Float($0.value) }
        let recentGlucoseTime = recentGlucose.map { $0.time! }
        ROC =  calculateGlucoseRateOfChangeTime(sampleTime: recentGlucoseTime as [Date], glucoseVector: recentGlucoseVal, numberOfSamples: 4)
    }
    //If no meals, we want to set target as glucoseMinHigh setpoint
    var variableGlucoseTarget: Float = foundSettings.glucoseMinHighSetpoint
    //* Fetch last meal (TEST THIS AS CARBS MAY NOT SET)
    if let lastMeal = ModelController().fetchLastMeal() {
        if let mealGlucose = ModelController().fetchMealGlucose(date: lastMeal.time!) {
            variableGlucoseTarget = calculateVariableGlucoseTarget(timeStamp: Date(),
                                                                   mealTime: lastMeal.time!,
                                                                   mealGlucose: Float(mealGlucose.value),
                                                                   mealCarbohydrates: Int(lastMeal.carbs),
                                                                   lowGlucoseTarget: foundSettings.glucoseMinLowSetpoint,
                                                                   highGlucoseTarget: foundSettings.glucoseMinHighSetpoint,
                                                                   mealTimeGlucoseTarget: foundSettings.mealTimeGlucoseTarget)
            print(lastMeal)
        }
        // Calculate variable glucose target
    }
    // fetch ICRs
    let ICRTable = [[Int(foundSettings.icrBreakfast),
                     Int(foundSettings.icrLunch),
                     Int(foundSettings.icrDinner)],
                    [Int(foundSettings.icrBreakfastExercise),
                     Int(foundSettings.icrLunchExercise),
                     Int(foundSettings.icrDinnerExercise)]]
    var selectedICR: Int
    selectedICR = try retrieveICR(ICRs: ICRTable, timeStamp: Date(), preExercise: recentExercise, postExercise: recentExercise)
    // Calculate bolus
    let (saturatedBolus, mealBolus, correctionBolus, adjustmentDoseROC) = calculateBolus(glucose: Float(lastGlucoseUnwrapped.value),
                                                                                         carbohydrates: Float(carborhydrates),
                                                                                         ICR: selectedICR,
                                                                                         ROC: ROC,
                                                                                         lowGlucoseTarget: foundSettings.glucoseMinLowSetpoint,
                                                                                         highGlucoseTarget: foundSettings.glucoseMinHighSetpoint,
                                                                                         variableGlucoseTarget: variableGlucoseTarget,
                                                                                         corrBolusIOB: correctionIOB)
    
    return (saturatedBolus, mealBolus, correctionBolus, mealIOB, correctionIOB, adjustmentDoseROC)
}

//
//  ARISESTests.swift
//  ARISESTests
//
//  Created by Ryan Armiger on 01/06/2019.
//  Copyright © 2019 Ryan Armiger. All rights reserved.
//

import XCTest
@testable import ARISES

class ARISESTests: XCTestCase {

    let model = MLController()
    var glucoseVector: [[Float]] = []
    var mealsVector: [[Float]] = []
    var insulinVector: [[Float]] = []
    var timeVector: [[Float]] = []
    var predVector: [Int32] = []
    var resultDiff: [Int] = []
    let test: ()  = XCTAssert(true)
    let expectation = XCTestExpectation(description: "Wait for all predictions")


    
    override func setUp() {

        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

//    func testExample() {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//    }
    func testLoop() {
        let testBundle = Bundle(for: type(of: self))
        
        let fileURL = testBundle.url(forResource: "cgm0", withExtension: "txt")
        let glucoseString = try? String(contentsOf: fileURL!, encoding: String.Encoding.utf8)
//        let glucoseArr = glucoseString!.split(separator: ",")
        glucoseVector = glucoseString!.components(separatedBy: "\n").map{ $0.components(separatedBy: ",").compactMap { Float( $0 ) } }
//        glucoseVector = glucoseArr.compactMap { ($0) }
        
        
        
        
        let fileURLmeal = testBundle.url(forResource: "meal2", withExtension: "txt")
        let mealString = try? String(contentsOf: fileURLmeal!, encoding: String.Encoding.utf8)
        mealsVector = mealString!.components(separatedBy: "\n").map{ $0.components(separatedBy: ",").compactMap { Float( $0 ) } }

//        let mealArr = mealString!.split(separator: ",")
//        mealsVector = mealArr.compactMap { Float($0) }
        
        let fileURLinsulin = testBundle.url(forResource: "insulin1", withExtension: "txt")
        let insulinString = try? String(contentsOf: fileURLinsulin!, encoding: String.Encoding.utf8)
        insulinVector = insulinString!.components(separatedBy: "\n").map{ $0.components(separatedBy: ",").compactMap { Float( $0 ) } }

//        let insulinArr = insulinString!.split(separator: ",")
//        insulinVector = insulinArr.compactMap { Float($0) }
        
        let fileURLtime = testBundle.url(forResource: "time3", withExtension: "txt")
        let timeString = try? String(contentsOf: fileURLtime!, encoding: String.Encoding.utf8)
        timeVector = timeString!.components(separatedBy: "\n").map{ $0.components(separatedBy: ",").compactMap { Float( $0 ) } }

//        let timeArr = timeString!.split(separator: ",")
//        timeVector = timeArr.compactMap { Float($0) }
        
        let fileURLpred = testBundle.url(forResource: "pred_ind", withExtension: "txt")
        let predString = try? String(contentsOf: fileURLpred!, encoding: String.Encoding.utf8)
        predVector = predString!.components(separatedBy: "\n").compactMap{ Int32( $0 ) }

//        let predArr = predString!.split(separator: ",")
//        predVector = predArr.compactMap { Int32($0) }
//        print(predVector)
        for _ in 0...(2589 - 1) {
            resultDiff.append(1000)
        }
        
        for index in 0...(2589 - 1) {
            performanceExample(index: index)
        }
        
        wait(for: [expectation], timeout: 1000)
//        let deadlineTime = DispatchTime.now() + .seconds(100)
//        DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
//            print(self.resultDiff)
//        }
    }

    func performanceExample(index: Int) {
        // This is an example of a performance test case.
//        var glucose: [Float] = glucoseVector
//        var insulin: [Float] = insulinVector
//        var meals: [Float] = mealsVector
//        var timeIndex: [Float] = timeVector
//        var expected: [Int32] = predVector
        
        var inputArr: [Float32] = []
        
        for i in 0...(glucoseVector[index].count - 1) {
            
            inputArr.append(glucoseVector[index][i])
            inputArr.append(insulinVector[index][i])
            inputArr.append(mealsVector[index][i])
            inputArr.append(timeVector[index][i])
            
        }

//        self.measure {
            // Put the code you want to measure the time of here.
//            startMeasuring()
        model.testPredict(input: inputArr, handle: { prediction in
//                self.stopMeasuring()
//            print("prediction: ", prediction)
//            print("predVector: ", self.predVector[index])
//            print("diff: ", prediction - self.predVector[index])
//            self.resultDiff[index] = Int(prediction - self.predVector[index])
            self.resultDiff[index] = Int(prediction)
            

            if index == 2588 {
                print(self.resultDiff)
                self.expectation.fulfill()
            }
            
//            XCTAssert(prediction == self.predVector[index])
        })

//        }
    }
  
}

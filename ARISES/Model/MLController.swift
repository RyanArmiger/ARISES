//
//  MLController.swift
//  ARISES
//
//  Created by Ryan Armiger on 28/05/2019.
//  Copyright © 2019 Ryan Armiger. All rights reserved.
//

import Foundation
import TensorFlowLite

//import class TensorFlowLite.Interpreter
//import struct TensorFlowLite.InterpreterOptions
//import struct TensorFlowLite.Tensor
//import struct TensorFlowLite.TensorShape
//import enum TensorFlowLite.Runtime

class MLController {
    
    //Mark Properties
    
    /// TensorFlowLite interpreter object for performing inference from a given model.
    private var interpreter: Interpreter?
    
    /// Serial dispatch queue for managing `Interpreter` calls.
    private let interpreterQueue = DispatchQueue(
        label: Constant.dispatchQueueLabel,
        qos: .userInitiated
    )
    
    //Mark Functions

    
    func predict() {
        loadModel()
        var glucose: [Float]
        var insulin: [Float]
        var meals: [Float]
        var timeIndex: [Float]
        
        (glucose, meals, insulin, timeIndex) = ModelController().fetchModelInputs(date: Date())
        
        var inputArr: [Float32] = []
        for i in 0...(glucose.count-1) {
            
            inputArr.append(glucose[i])
            inputArr.append(insulin[i])
            inputArr.append(meals[i])
            inputArr.append(timeIndex[i])
            
        }
        invokeAdd(input: inputArr)
    }
    
    func predictInsulinScrub(insulinVal: Float) {
        loadModel()
        var glucose: [Float]
        var insulin: [Float]
        var meals: [Float]
        var timeIndex: [Float]
        
        
        (glucose, meals, insulin, timeIndex) = ModelController().fetchModelInputs(date: Date())
        insulin[insulin.count - 1] += insulinVal
        print(insulin)

        var inputArr: [Float32] = []
        for i in 0...(glucose.count-1) {
            
            inputArr.append(glucose[i])
            inputArr.append(insulin[i])
            inputArr.append(meals[i])
            inputArr.append(timeIndex[i])
            
        }
        invokeAdd(input: inputArr)
    }
    
    func predictCarbScrub(carbVal: Float) {
        loadModel()
        var glucose: [Float]
        var insulin: [Float]
        var meals: [Float]
        var timeIndex: [Float]
        
        
        (glucose, meals, insulin, timeIndex) = ModelController().fetchModelInputs(date: Date())
        meals[meals.count - 1] += carbVal
        print(meals)
        
        var inputArr: [Float32] = []
        for i in 0...(glucose.count-1) {
            
            inputArr.append(glucose[i])
            inputArr.append(insulin[i])
            inputArr.append(meals[i])
            inputArr.append(timeIndex[i])
            
        }
        invokeAdd(input: inputArr)
    }
    
    func testPredict(input: [Float32], handle: @escaping (Int32) -> Void ) {
        loadModel()
        testInvokeAdd(input: input, handle: handle)
    }
    
    
    private func loadModel() {
        
        guard let modelPath = Bundle.main.path(forResource: "converted_model.tflite", ofType: nil)
            else {
                print("Failed to load the model.")
                return
        }
        interpreterQueue.async {
            do {
                var options = InterpreterOptions()
                options.threadCount = 2
                self.interpreter = try Interpreter(modelPath: modelPath, options: options)
            } catch let error {
                print("Failed to create the interpreter with error: \(error.localizedDescription)")
                return
            }
//            print("Succeeded")
        }
    }
    
    private func invokeAdd(input: [Float32]) {
        interpreterQueue.async {
        
            guard let interpreter = self.interpreter else {
                print(Constant.nilInterpreterErrorMessage)
                return
            }
            do {

                try interpreter.allocateTensors()
                let data = Data(copyingBufferOf: input)

                try interpreter.copy(data, toInputAt: 0)
                try interpreter.invoke()
                let outputTensor = try interpreter.output(at: 0)
                let results: () -> Int? = {
                    guard let results = [Int32](unsafeData: outputTensor.data) else { return nil }
//                    print(outputTensor.dataType)
//                    print(outputTensor.data)
//                    print(results)
                    return Int(results[0])
                }
//                print(results())
                if let res = results() {
                    let range: [Int] = Array(-127...128)
                    print(range.count)
                    let adjustedRes = range[res]
                    print(adjustedRes)
                    DispatchQueue.main.async { [weak self] in
                        let nc = NotificationCenter.default
                        nc.post(name: Notification.Name("newPrediction"), object: Float(adjustedRes) / Float(18) )
                    }
                }
                return
            } catch let error {
                print("Failed to invoke the interpreter with error: \(error.localizedDescription)")
                return
            }
        }
    }
    
    private func testInvokeAdd(input: [Float32], handle: @escaping (Int32) -> Void ) {
        interpreterQueue.async {
            
            guard let interpreter = self.interpreter else {
                print(Constant.nilInterpreterErrorMessage)
                return
            }
            do {
                
                try interpreter.allocateTensors()
                let data = Data(copyingBufferOf: input)
                
                try interpreter.copy(data, toInputAt: 0)
                try interpreter.invoke()
                let outputTensor = try interpreter.output(at: 0)
                let results: () -> Int32? = {
                    guard let results = [Int32](unsafeData: outputTensor.data) else { return nil }
//                    print(outputTensor.dataType)
//                    print(outputTensor.data)
//                    print(results)
                    return results[0]
                }
//                print(results())
                if let res = results() {
                    handle(res)
                }
                return
            } catch let error {
                print("Failed to invoke the interpreter with error: \(error.localizedDescription)")
                return
            }
        }
    }
    
}




private enum Constant {
    static let dispatchQueueLabel = "TensorFlowLiteInterpreterQueue"
    static let nilInterpreterErrorMessage =
    "Failed to invoke the interpreter because the interpreter was nil."
}

extension Array {
    /// Creates a new array from the bytes of the given unsafe data.
    ///
    /// - Warning: The array's `Element` type must be trivial in that it can be copied bit for bit
    ///     with no indirection or reference-counting operations; otherwise, copying the raw bytes in
    ///     the `unsafeData`'s buffer to a new array returns an unsafe copy.
    /// - Note: Returns `nil` if `unsafeData.count` is not a multiple of
    ///     `MemoryLayout<Element>.stride`.
    /// - Parameter unsafeData: The data containing the bytes to turn into an array.
    init?(unsafeData: Data) {
        guard unsafeData.count % MemoryLayout<Element>.stride == 0 else { return nil }
        #if swift(>=5.0)
        self = unsafeData.withUnsafeBytes { .init($0.bindMemory(to: Element.self)) }
        #else
        self = unsafeData.withUnsafeBytes {
            .init(UnsafeBufferPointer<Element>(
                start: $0,
                count: unsafeData.count / MemoryLayout<Element>.stride
            ))
        }
        #endif  // swift(>=5.0)
    }
}

extension Data {
    /// Creates a new buffer by copying the buffer pointer of the given array.
    ///
    /// - Warning: The given array's element type `T` must be trivial in that it can be copied bit
    ///     for bit with no indirection or reference-counting operations; otherwise, reinterpreting
    ///     data from the resulting buffer has undefined behavior.
    /// - Parameter array: An array with elements of type `T`.
    init<T>(copyingBufferOf array: [T]) {
        self = array.withUnsafeBufferPointer(Data.init)
    }
}

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
        invokeAdd()
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
            print("Succeeded")
        }
    }
    
    private func invokeAdd() {
        interpreterQueue.async {
            
            var glucose: [Float]
            var insulin: [Float]
            var meals: [Float]
            var timeIndex: [Float]
            
            (glucose, meals, insulin, timeIndex) = ModelController().fetchModelInputs(date: Date())
            
            guard let interpreter = self.interpreter else {
                print(Constant.nilInterpreterErrorMessage)
                return
            }
            do {
//                let inputShape = TensorShape([1, 16, 4])
//                try interpreter.resize/Input(at: 0, to: inputShape)
                try interpreter.allocateTensors()
                
//                let input: [[Float32]] = [glucose, insulin, meals, timeIndex]
                //Pretty weird that you need to do this
                var inputArr: [Float32] = []
                for i in 0...(glucose.count-1) {
                    
                    inputArr.append(glucose[i])
                    inputArr.append(insulin[i])
                    inputArr.append(meals[i])
                    inputArr.append(timeIndex[i])

                }
//                print(glucose.count)
//                print(insulin.count)
//                print(meals.count)
//                print(timeIndex.count)
                let data = Data(copyingBufferOf: inputArr)
                
//                print(data)
                
                try interpreter.copy(data, toInputAt: 0)
                try interpreter.invoke()
                let outputTensor = try interpreter.output(at: 0)
                let results: () -> Float? = {
                    guard let results = [Int32](unsafeData: outputTensor.data) else { return nil }
                    print(outputTensor.dataType)
                    print(outputTensor.data)
                    print(results)
                    return Float(results[0])
                }
                print(results())
                if let res = results() {
                    DispatchQueue.main.async { [weak self] in
                        let nc = NotificationCenter.default
                        nc.post(name: Notification.Name("newPrediction"), object: res)
                    }
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

//
//  EmpaticaModelController.swift
//  ARISES
//
//  Created by Ryan Armiger on 23/05/2019.
//  Copyright © 2019 Ryan Armiger. All rights reserved.
//

import Foundation
import CoreData

class EmpaticaModelController {
    
    func getLocalTimeString(timestamp: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM HH:mm:ss"

        return dateFormatter.string(from: timestamp)
    }
    
    func addTemp(temp: Float, timestamp: Date) {
        PersistenceService.context.performAndWait {

            let newTemp = Temperature(context: PersistenceService.context)
            newTemp.temp = temp
            newTemp.timestamp = timestamp
//            newTemp.localTime = getLocalTimeString(timestamp: timestamp)
            print("Temp time: ", timestamp)
            PersistenceService.saveContext()
        }
    }
    
    func addTag(timestamp: Date) {
        PersistenceService.context.performAndWait {

            let newTag = Tag(context: PersistenceService.context)
            newTag.timestamp = timestamp
//            newTag.localTime = getLocalTimeString(timestamp: timestamp)
            PersistenceService.saveContext()
        }
    }
    
    func addHR(hr: Float, qualityIndex: Int32, timestamp: Date) {
        PersistenceService.context.performAndWait {

            let newHR = HR(context: PersistenceService.context)
            newHR.hr = hr
            newHR.qualityIndex = qualityIndex
            newHR.timestamp = timestamp
//            newHR.localTime = getLocalTimeString(timestamp: timestamp)
            PersistenceService.saveContext()
        }
    }
    
    func addAcc(x: Int16, y: Int16, z: Int16, timestamp: Date) {
        PersistenceService.context.performAndWait {
            
            let newAcc = Acc(context: PersistenceService.context)
            newAcc.x = x
            newAcc.y = y
            newAcc.z = z
            newAcc.timestamp = timestamp
            //            newHR.localTime = getLocalTimeString(timestamp: timestamp)
            PersistenceService.saveContext()
        }
    }
    
    func addBVP(bvp: Float, timestamp: Date) {
        PersistenceService.context.performAndWait {
            let newBVP = BVP(context: PersistenceService.context)
            newBVP.bvp = bvp
            newBVP.timestamp = timestamp
//            newBVP.localTime = getLocalTimeString(timestamp: timestamp)
            PersistenceService.saveContext()
        }
    }
    
    func addIBI(ibi: Float, timestamp: Date) {
        PersistenceService.context.performAndWait {
            let newIBI = IBI(context: PersistenceService.context)
            newIBI.ibi = ibi
            newIBI.timestamp = timestamp
//            newIBI.localTime = getLocalTimeString(timestamp: timestamp)
            PersistenceService.saveContext()
        }
    }
    
    func addGSR(gsr: Float, timestamp: Date) {
        PersistenceService.context.performAndWait {
            let newGSR = GSR(context: PersistenceService.context)
            newGSR.gsr = gsr
            newGSR.timestamp = timestamp
//            newGSR.localTime = getLocalTimeString(timestamp: timestamp)
            PersistenceService.saveContext()
        }

    }
    
    
}

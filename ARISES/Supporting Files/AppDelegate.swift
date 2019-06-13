//
//  AppDelegate.swift
//  ARISES
//
//  Created by Ryan Armiger on 05/05/2018.
//  Copyright © 2018 Ryan Armiger. All rights reserved.
//

import CoreData
import HealthKit
import UIKit
import UserNotifications
//import AWSCognito
import AWSCore
import AWSS3

@UIApplicationMain
// swiftlint:disable:next line_length
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, URLSessionDelegate, NSURLConnectionDelegate, TransmitterDelegate, TransmitterCommandSource {
    
    var window: UIWindow?
    private var today: Date?
    
    static var sharedDelegate: AppDelegate {
        // swiftlint:disable force_cast
        return UIApplication.shared.delegate as! AppDelegate
    }
    var empaticaInstance: EmpaticaViewController?
    
    var transmitterID: String? {
        didSet {
            if let id = transmitterID {
                transmitter = Transmitter(
                    id: id,
                    passiveModeEnabled: true
                )
                transmitter?.stayConnected = true
                transmitter?.delegate = self
                transmitter?.commandSource = self
                
                UserDefaults.standard.transmitterID = id
            }
            glucose = nil
        }
    }
    
    
//    static let EMPATICA_API_KEY = "e317ade3900a4804ba6050da0bd581ae"

    
    var unit: HKUnit?
    
    var transmitter: Transmitter?
    
    let commandQueue = CommandQueue()
    
    var glucose: Glucose?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        registerForPushNotifications()

        transmitterID = UserDefaults.standard.transmitterID
//
//        if UserDefaults.standard.glucoseUnits == "millimolesPerLiter"{
//            self.unit = HKUnit.millimolesPerLiter
//        } else {
//            self.unit = HKUnit.milligramsPerDeciliter
//        }
        
//        self.unit = HKUnit.milligramsPerDeciliter

        self.unit = HKUnit.millimolesPerLiter

        today = Calendar.current.startOfDay(for: Date())
        
        let hiddenAD = HiddenAppDelegate()
        let configuration = hiddenAD.config
        AWSServiceManager.default().defaultServiceConfiguration = configuration

        
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.allButUpsideDown
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        if let transmitter = transmitter, !transmitter.stayConnected {
            transmitter.stopScanning()
        }
        
        EmpaticaAPI.prepareForBackground()

    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        transmitter?.resumeScanning()
        
        EmpaticaAPI.prepareForResume()
        
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        //        self.saveContext()
    }
    
    // MARK: - TransmitterDelegate
    
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        return dateFormatter
    }()
    
    func dequeuePendingCommand(for transmitter: Transmitter) -> Command? {
        return commandQueue.dequeue()
    }
    
    func transmitter(_ transmitter: Transmitter, didFail command: Command, with error: Error) {
    }
    
    func transmitter(_ transmitter: Transmitter, didComplete command: Command) {
    }
    
    func transmitter(_ transmitter: Transmitter, didError error: Error) {
        DispatchQueue.main.async {
            print("Transmitter Error: \(error)")
            print(NSLocalizedString("Error", comment: "Title displayed during error response"))
        }
    }
    
    func transmitter(_ transmitter: Transmitter, didRead glucose: Glucose) {
        self.glucose = glucose
        DispatchQueue.main.async {
            
            let date = glucose.readDate
            
            self.today = Calendar.current.startOfDay(for: Date())
            
            if self.today != nil {
                guard let glucoseValue = glucose.glucose else {
                    print("ERROR: Glucose value is unexpectedly nil")
                    return
                }
                guard let glucoseUnit = self.unit else {
                    print("ERROR: Glucose unit is unexpectedly nil")
                    return
                }
                // swiftlint:disable:next line_length
                ModelController().addGlucose(value: glucoseValue.doubleValue(for: glucoseUnit), time: date, trend: Int32(glucose.trend), date: self.today!)
            } else {
                print("ERROR: App delegate value of today is nil")
            }
            
        }
    }
    
    func transmitter(_ transmitter: Transmitter, didReadUnknownData data: Data) {
        DispatchQueue.main.async {
            print(NSLocalizedString("Unknown Data", comment: "Title displayed during unknown data response"))
        }
    }
    
    func transmitter(_ transmitter: Transmitter, didReadBackfill glucose: [Glucose]) {
        DispatchQueue.main.async {
            for gluc in glucose {
                let date = gluc.readDate
                //                let unit = HKUnit.milligramsPerDeciliter
                guard let glucoseUnit = self.unit else {
                    print("ERROR: Glucose unit is unexpectedly nil")
                    return
                }
                
                self.today = Calendar.current.startOfDay(for: Date())
                
                if self.today != nil {
                    guard let glucoseValue = gluc.glucose else {
                        print("ERROR: Glucose value is nil")
                        return
                    }
                    // swiftlint:disable:next line_length
                    ModelController().addGlucose(value: glucoseValue.doubleValue(for: glucoseUnit), time: date, trend: Int32(gluc.trend), date: self.today!)
                } else {
                    print("ERROR: App delegate value of today is nil")
                }
            }
            print(NSLocalizedString("Backfill", comment: "Title displayed during backfill response"))
            
        }
    }
    
 
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            granted, error in
            print("Permission granted: \(granted)")
            guard granted else { return }
            self.getNotificationSettings()
        }
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
//            DispatchQueue.main.async(execute: {
////                UIApplication.shared.registerForRemoteNotifications()
//            })
        }
    }
}

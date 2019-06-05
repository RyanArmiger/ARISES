//
//  UserSettingsController.swift
//  ARISES
//
//  Created by Ryan Armiger on 03/06/2019.
//  Copyright © 2019 Ryan Armiger. All rights reserved.
//

import Foundation
import UIKit

class UserSettingsController: UIViewController {
    
    @IBOutlet weak var icrBreakfast: UITextField!
    @IBOutlet weak var icrLunch: UITextField!
    @IBOutlet weak var icrDinner: UITextField!
    @IBOutlet weak var icrBreakfastExercise: UITextField!
    @IBOutlet weak var icrLunchExercise: UITextField!
    @IBOutlet weak var icrDinnerExercise: UITextField!
    @IBOutlet weak var iobDecayTime: UITextField!
    @IBOutlet weak var glucoseSetpoint: UITextField!
    @IBOutlet weak var mealTimeSetpoint: UITextField!
    @IBOutlet weak var minLowSetpoint: UITextField!
    @IBOutlet weak var minHighSetpoint: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()

        if let foundSettings = ModelController().fetchSettings() {
            icrBreakfast.text = String(foundSettings.icrBreakfast)
            icrLunch.text = String(foundSettings.icrLunch)
            icrDinner.text = String(foundSettings.icrDinner)
            icrBreakfastExercise.text = String(foundSettings.icrBreakfastExercise)
            icrLunchExercise.text = String(foundSettings.icrLunchExercise)
            icrDinnerExercise.text = String(foundSettings.icrDinnerExercise)
            iobDecayTime.text = String(foundSettings.iobTimeDecay)
            glucoseSetpoint.text = String(foundSettings.glucoseSetpoint)
            mealTimeSetpoint.text = String(foundSettings.mealTimeGlucoseTarget)
            minLowSetpoint.text = String(foundSettings.glucoseMinLowSetpoint)
            minHighSetpoint.text = String(foundSettings.glucoseMinHighSetpoint)
        }
    }
    
    
    @IBAction func dismissView(_ sender: Any) {
        self.dismiss(animated: true, completion: {})
    }
    
    @IBAction func updateSettingsButton(_ sender: Any) {
        if let icrBreakfastVal = Int(icrBreakfast.text!),
            let icrLunchVal = Int(icrLunch.text!),
            let icrDinnerVal = Int(icrDinner.text!),
            let icrBreakfastExVal = Int(icrBreakfastExercise.text!),
            let icrLunchExVal = Int(icrLunchExercise.text!),
            let icrDinnerExVal = Int(icrDinnerExercise.text!),
            let iobDecayTimeVal = Float(iobDecayTime.text!),
            let glucoseSetpointVal = Float(glucoseSetpoint.text!),
            let glucoseMinLowVal = Float(minLowSetpoint.text!),
            let glucoseMinHighVal = Float(minHighSetpoint.text!),
            let glucoseMealTimeVal = Float(mealTimeSetpoint.text!){
            
            ModelController().updateSettings(icrBreakfast: icrBreakfastVal,
                                             icrLunch: icrLunchVal,
                                             icrDinner: icrDinnerVal,
                                             icrBreakfastExercise: icrBreakfastExVal,
                                             icrLunchExercise: icrLunchExVal,
                                             icrDinnerExercise: icrDinnerExVal,
                                             iobDecayTime: iobDecayTimeVal,
                                             glucoseSetpoint: glucoseSetpointVal,
                                             glucoseMinLow: glucoseMinLowVal,
                                             glucoseMinHigh: glucoseMinHighVal,
                                             glucoseMealTimeSetpoint: glucoseMealTimeVal)
            
            let testAlert = UIAlertController(title: "Updated", message: "User settings have been updated", preferredStyle: .alert)
            testAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: nil))
            self.present(testAlert, animated: true, completion: nil)

        }

    }
}

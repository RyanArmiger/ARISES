//
//  InsulinAdviceController.swift
//  ARISES
//
//  Created by Ryan Armiger on 05/06/2019.
//  Copyright © 2019 Ryan Armiger. All rights reserved.
//

import Foundation
import UIKit

class ViewControllerInsulin: UIViewController {
    
    @IBOutlet private weak var insulinTextField: UITextField!
    @IBOutlet private weak var breakdownLabel: UILabel!
    @IBOutlet private weak var adviceView: UIView!
    
    var carbohydrates: Int = 0
    private var saturatedBolus: Float = -1
    private var mealBolus: Float = -1
    private var correctionBolus: Float = -1
    private var mealIOB: Float = -1
    private var correctionIOB: Float = -1
    private var adjustmentDoseROC: Float = -1

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        addToolbar()
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(handleShowKeyboardNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        nc.addObserver(self, selector: #selector(handleHideKeyboardNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        do {
            (saturatedBolus, mealBolus, correctionBolus, mealIOB, correctionIOB, adjustmentDoseROC) =  try getBolus(carborhydrates: carbohydrates)
        } catch {
            print("ERROR: Cannot calculate bolus, error \(error)")
        }
        if saturatedBolus != -1
            && mealBolus != -1
            && correctionBolus != -1
            && mealIOB != -1
            && correctionIOB != -1
            && adjustmentDoseROC != -1 {
            insulinTextField.text = String(format: "%.1f", saturatedBolus)
            breakdownLabel.text = String(format: "%.1f", mealBolus)
                                    + "U Meal bolus + "
                                    + String(format: "%.1f", correctionBolus)
                                    + "U Correction"
            
        }
    }
    
    @IBAction private func submitButton(_ sender: Any) {
        if saturatedBolus != -1
            && mealBolus != -1
            && correctionBolus != -1
            && mealIOB != -1
            && correctionIOB != -1
            && adjustmentDoseROC != -1 {
            
            guard let userInsulinText = insulinTextField.text else {
                return
            }
            guard let userInsulin = Float(userInsulinText) else {
                return
            }
            
            ModelController().addInsulin(units: saturatedBolus, unitsUser: userInsulin, correctionBolus: correctionBolus, mealBolus: mealBolus, mealIOB: mealIOB, correctionIOB: correctionIOB, time: Date(), date: Date())
        }
        
        let testAlert = UIAlertController(title: "Success", message: "Insulin submitted", preferredStyle: .alert)
        testAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: dismissButton(_:)))
        self.present(testAlert, animated: true, completion: nil)
        
        
    }
    
    
    @IBAction private func dismissButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @objc private func doneWithKeypad(){
        view.endEditing(true)
    }
    
    @objc
    private func handleShowKeyboardNotification(notification: NSNotification) {
        guard let keyboardRect = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        if UIApplication.shared.statusBarOrientation.isPortrait {
            let testy = adviceView.superview?.convert(adviceView.frame, to: nil)
            
            //        print(testy)
            if let maxY = testy?.maxY {
                if keyboardRect.minY < maxY {
                    let adjustValue = maxY - keyboardRect.minY
                    self.view.frame.origin.y = -(adjustValue + 15)
                }
            }
        }
    }
    @objc
    private func handleHideKeyboardNotification(notification: NSNotification) {
        self.view.frame.origin.y = 0
    }
    
    private func addToolbar() {
        let doneButtonBar = UIToolbar()
        doneButtonBar.sizeToFit()
        
        let flexible = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: #selector(doneWithKeypad))
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(doneWithKeypad))
        
        doneButtonBar.setItems([flexible, doneButton], animated: true)
        
        insulinTextField.inputAccessoryView = doneButtonBar
    }
}

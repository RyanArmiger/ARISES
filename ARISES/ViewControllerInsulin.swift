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

    private var model: MLController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        addToolbar()
        
        model = MLController()

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
            model?.predictInsulinScrub(insulinVal: saturatedBolus)

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
            
            let testAlert = UIAlertController(title: "Success", message: "Insulin submitted", preferredStyle: .alert)
            testAlert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: {_ in self.dismiss(animated: true, completion: nil)}))
            self.present(testAlert, animated: true, completion: nil)
            
        }
        
    }
    
    
    @IBAction private func dismissButton(_ sender: Any) {
        let testAlert = UIAlertController(title: "Warning", message: "Are you sure you want to leave without submitting insulin?", preferredStyle: .alert)
        testAlert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: "Default action"), style: .default, handler: nil))
        testAlert.addAction(UIAlertAction(title: NSLocalizedString("Yes", comment: "Default action"), style: .default, handler: {_ in self.dismiss(animated: true, completion: nil)}))

        self.present(testAlert, animated: true, completion: nil)
        
        
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
  
    
    @IBAction func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        let loc = recognizer.location(in: self.view)
        var percHeight: CGFloat = ( loc.y - 0.1 * self.view.bounds.height ) / self.view.bounds.height
        
        let adjustment =  (percHeight - 0.5) * -10
        
        if saturatedBolus != -1
            && mealBolus != -1
            && correctionBolus != -1
            && mealIOB != -1
            && correctionIOB != -1
            && adjustmentDoseROC != -1 {
            if saturatedBolus + Float(adjustment)  >= 0 {
                model?.predictInsulinScrub(insulinVal: saturatedBolus + Float(adjustment))
                insulinTextField.text = String(format: "%.1f", saturatedBolus + Float(adjustment))
                breakdownLabel.text = "Recommended bolus: " + String(format: "%.1f", saturatedBolus)
            } else {
                model?.predict()
                insulinTextField.text = String(format: "%.1f", 0)
                breakdownLabel.text = "Recommended bolus: " + String(format: "%.1f", saturatedBolus)
            }
            
            
        }
        //Update prediction on graph
        
        
        if recognizer.state == .ended  {
            //Update insulin label
            
            
        }
        
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

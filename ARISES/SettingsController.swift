//
//  SettingsController.swift
//  ABC4D
//
//  Created by Ryan Armiger on 22/12/2018.
//  Copyright © 2018 El Sharkawy, Mohamed Fayez. All rights reserved.
//

import HealthKit
import UIKit

class SettingsController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet private weak var transmitterIDField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.hideKeyboardWhenTappedAround()
        
        transmitterIDField.text = AppDelegate.sharedDelegate.transmitter?.ID
        // Do any additional setup after loading the view.
        
    }
    
    // MARK: - UITextFieldDelegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text {
            let newString = text.replacingCharacters(in: range.rangeOfString(text), with: string)
            
            if newString.count > 6 {
                return false
            } else if newString.count == 6 {
                AppDelegate.sharedDelegate.transmitterID = newString
                textField.text = newString
                
                textField.resignFirstResponder()
                
                return false
            }
        }
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField.text?.count != 6 {
            textField.text = UserDefaults.standard.transmitterID
        }
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    @IBAction func dismissView(_ sender: Any) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
}

private extension NSRange {
    func rangeOfString(_ string: String) -> Range<String.Index> {
        let startIndex = string.index(string.startIndex, offsetBy: location)
        let endIndex = string.index(startIndex, offsetBy: length)
        return startIndex..<endIndex
    }
}

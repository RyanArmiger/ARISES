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
    @IBOutlet private weak var empaticaAPIkeyField: UITextField!
    @IBOutlet private weak var empaticaConnect: UIButton!
    @IBOutlet private weak var empaticaTableContainer: UIView!
    
    private var empaticaController: EmpaticaViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        transmitterIDField.text = AppDelegate.sharedDelegate.transmitter?.ID
        // Do any additional setup after loading the view.
        empaticaAPIkeyField.text = UserDefaults.standard.empaticaAPIKey
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(hideEmpaticaConnect), name: Notification.Name("empaticaAuth"), object: nil)
        
        empaticaConnect.isUserInteractionEnabled = true
        empaticaConnect.backgroundColor = #colorLiteral(red: 0.7377689481, green: 0.8417704701, blue: 0.937656343, alpha: 1)
        empaticaAPIkeyField.isUserInteractionEnabled = true

    }
    
    @objc func hideEmpaticaConnect() {
        empaticaConnect.isUserInteractionEnabled = false
        empaticaConnect.backgroundColor = #colorLiteral(red: 0.3921568627, green: 0.737254902, blue: 0.4392156863, alpha: 1)
        empaticaAPIkeyField.isUserInteractionEnabled = false
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
        self.dismiss(animated: true, completion: {})
    }
    
    @IBAction func empaticaConnectButton(_ sender: Any) {
        guard let APIkey = empaticaAPIkeyField.text else {
            return
        }
        EmpaticaViewController.EMPATICA_API_KEY = APIkey
        UserDefaults.standard.empaticaAPIKey = APIkey
        
        if empaticaController != nil {
            empaticaController?.beginAuthenticate()
            view.endEditing(true)
            
        } else {
            
            // Load Storyboard
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            
            // Instantiate View Controller
            empaticaController = storyboard.instantiateViewController(withIdentifier: "empaticaTable") as! EmpaticaViewController
                guard let ec = empaticaController else {
                    view.endEditing(true)
                    return
                }
            // Add View Controller as Child View Controller
            empaticaTableContainer.addSubview(ec.view)      //        EmpaticaViewController().beginAuthenticate()
            view.endEditing(true)
        }
    }
    
}

private extension NSRange {
    func rangeOfString(_ string: String) -> Range<String.Index> {
        let startIndex = string.index(string.startIndex, offsetBy: location)
        let endIndex = string.index(startIndex, offsetBy: length)
        return startIndex..<endIndex
    }
}

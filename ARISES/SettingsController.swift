//
//  SettingsController.swift
//  ABC4D
//
//  Created by Ryan Armiger on 22/12/2018.
//  Copyright © 2018 El Sharkawy, Mohamed Fayez. All rights reserved.
//

import HealthKit
import UIKit
//import AWSCognito
import AWSS3

class SettingsController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet private weak var transmitterIDField: UITextField!
    @IBOutlet private weak var empaticaAPIkeyField: UITextField!
    @IBOutlet private weak var empaticaConnect: UIButton!
    @IBOutlet private weak var empaticaTableContainer: UIView!
    
//    private var empaticaController: EmpaticaViewController?
    
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

        loadEmpaticaController()
    }
    
//    override func viewWillAppear(_ animated: Bool) {
//        if let ec = empaticaController {
//            empaticaTableContainer.addSubview(ec.view)      //        EmpaticaViewController().beginAuthenticate()
//
//        }
//    }
    
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
        
//        if let ec = self.empaticaController {
//            empaticaTableContainer.addSubview(ec.view)      //        EmpaticaViewController().beginAuthenticate()
//            return
//        }
        if AppDelegate.sharedDelegate.empaticaInstance == nil {
            print("empatical controller nil?")
            loadEmpaticaController()
        }
        
    }
    
    private func loadEmpaticaController() {
        guard let APIkey = empaticaAPIkeyField.text else {
            return
        }
        EmpaticaViewController.EMPATICA_API_KEY = APIkey
        UserDefaults.standard.empaticaAPIKey = APIkey
        
        if AppDelegate.sharedDelegate.empaticaInstance != nil {
            guard let ec = AppDelegate.sharedDelegate.empaticaInstance else {
                view.endEditing(true)
                return
            }
            // Add View Controller as Child View Controller
            empaticaTableContainer.addSubview(ec.view)      //        EmpaticaViewController().beginAuthenticate()
            view.endEditing(true)
            hideEmpaticaConnect()
//            ec.beginAuthenticate()
        } else {
            
            // Load Storyboard
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            
            // Instantiate View Controller
            AppDelegate.sharedDelegate.empaticaInstance = storyboard.instantiateViewController(withIdentifier: "empaticaTable") as? EmpaticaViewController
            guard let ec = AppDelegate.sharedDelegate.empaticaInstance else {
                view.endEditing(true)
                return
            }
            // Add View Controller as Child View Controller
            empaticaTableContainer.addSubview(ec.view)      //        EmpaticaViewController().beginAuthenticate()
            view.endEditing(true)
        }
    }
    
    
    @IBAction func uploadDataAWS(_ sender: Any) {
        let currentDay = Calendar.current.startOfDay(for: Date())
        let loggedMeals = ModelController().fetchMeals(day: currentDay)
        var topLevel: [NSMealsEncode?] = []
        for meal in loggedMeals{
            topLevel.append(meal.createEncoded())
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let uploadData = try? encoder.encode(topLevel)
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first{
            let key  = "data.json"
            let fileURL = dir.appendingPathComponent(key)
            do{
                try uploadData?.write(to: fileURL)
            }catch {}
            print("JSONPath: \(fileURL)")
            uploadFile(with: fileURL,key: key)
            
            
        }
    }
    
    func uploadFile(with JsonURL:URL,key:String){
        
        
        
        DispatchQueue.main.async (execute: {
            
            let transferUtility = AWSS3TransferUtility.default()
            let bucketname = "arises"
            let expression = AWSS3TransferUtilityUploadExpression()
            
            transferUtility.uploadFile(JsonURL, bucket: bucketname, key: key, contentType: "binary/octet-stream", expression: expression){(task,error) in
                if let error = error{
                    print(error.localizedDescription)
                    return
                }
                
                print("Uploaded File")
                
                //                self.uploadStatus.text = "Uploaded data!"
            }
            
            
        })
        
        
    }
    
}


private extension NSRange {
    func rangeOfString(_ string: String) -> Range<String.Index> {
        let startIndex = string.index(string.startIndex, offsetBy: location)
        let endIndex = string.index(startIndex, offsetBy: length)
        return startIndex..<endIndex
    }
}

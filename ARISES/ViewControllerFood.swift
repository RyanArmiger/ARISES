//
//  ViewControllerFood.swift
//  ARISES
//
//  Created by Ryan Armiger on 16/05/2018.
//  Copyright © 2018 Ryan Armiger. All rights reserved.
//

import Foundation
import UIKit

class ViewControllerFood: UIViewController, UIPickerViewDelegate, UITableViewDataSource, UITableViewDelegate {
    
    //TODO: food log not working
 
    //MARK: Properties
    @IBOutlet weak var foodTimeField: UITextField!
    @IBOutlet weak var foodLogTable: UITableView!
    @IBOutlet weak var carbsTextField: UITextField!
    @IBOutlet weak var proteinTextField: UITextField!
    @IBOutlet weak var fatTextField: UITextField!
    @IBOutlet weak var foodNameTextField: UITextField!
    
    //defining picker related variables
    var foodTimePicker = UIDatePicker()
    
    //defining table related variables
    var loggedFoodName = [String]()
    var loggedFoodTime = [String]()
    
    //MARK: Override
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createFoodTimePicker()
        
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneWithKeypad))
        
        toolBar.setItems([flexible, doneButton], animated: false)
        
        carbsTextField.inputAccessoryView = toolBar
        proteinTextField.inputAccessoryView = toolBar
        fatTextField.inputAccessoryView = toolBar
        foodNameTextField.inputAccessoryView = toolBar
    }
    
    //MARK: Picker functions
    //Food Time picker
    func createFoodTimePicker(){
        
        let doneButtonBar = UIToolbar()
        doneButtonBar.sizeToFit()
        
        let flexible = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: #selector(doneWithPicker))
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(doneWithPicker))
        
        doneButtonBar.setItems([flexible, doneButton], animated: false)
        
        foodTimeField.inputAccessoryView = doneButtonBar
        foodTimeField.inputView = foodTimePicker
        
        foodTimePicker.datePickerMode = .time
    }
    
    @objc func doneWithPicker(){
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        
        foodTimeField.text = dateFormatter.string(from: foodTimePicker.date)
        self.view.endEditing(true)
    }
    
    //MARK: Table functions
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loggedFoodName.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ViewControllerTableViewCell
        
        cell.loggedFoodStar.image = UIImage(named: "Star.jpg")
        cell.loggedFoodName.text = loggedFoodName[indexPath.row]
        cell.loggedFoodTime.text = loggedFoodTime[indexPath.row]
        
        return(cell)
    }
    
    @objc func doneWithKeypad(){
        view.endEditing(true)
    }
    
    
}

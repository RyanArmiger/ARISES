//
//  ViewControllerAdvice.swift
//  ARISES
//
//  Created by Ryan Armiger on 16/05/2018.
//  Copyright © 2018 Ryan Armiger. All rights reserved.
//

import UIKit


/**
 Controls all UI elements within the advice domain. Currently this is only the expanding suggestion bar
 */
class ViewControllerAdvice: UIViewController, UITableViewDelegate, UITableViewDataSource {

    
    //MARK: - Outlets
    @IBOutlet var predictButtonOutlet: UIButton!
    @IBOutlet var predictionValueLabel: UILabel!
    @IBOutlet var predictionDetailLabel: UILabel!
    
    @IBOutlet var insulinLogTable: UITableView!
    private var loggedInsulin = [Insulin]()
    private var model: MLController?

    ///Tracks date set by graph and hides data entry fields when not on current day using didSet
    private var currentDay = Date(){
        didSet{
           
        }
    }
    //MARK: - Override viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        model = MLController()

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(updateDay(notification:)), name: Notification.Name("dayChanged"), object: nil)
        nc.addObserver(self, selector: #selector(updateTable), name: Notification.Name("InsulinAdded"), object: nil)
        nc.addObserver(self, selector: #selector(addPrediction(notification:)), name: Notification.Name("newPrediction"), object: nil)

        updateTable()

    }
    
    //MARK: - Update Day
    ///Updates the currentDay variable with a date provided via notification from ViewControllerGraph and re-fetches the table
    @objc private func updateDay(notification: Notification) {
        currentDay = notification.object as! Date
        updateTable()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loggedInsulin.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ViewControllerTableViewCell
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = #colorLiteral(red: 0.9455107252, green: 0.9455107252, blue: 0.9455107252, alpha: 1)
        cell.selectedBackgroundView = backgroundView
        
        let currentInsulin = loggedInsulin[indexPath.row]
        
        cell.loggedInsulinUnits.text = String(format: "%.1f",  currentInsulin.unitsUser)
        
        if let InsulinTime = currentInsulin.time {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            let insulinTimeString = dateFormatter.string(from: InsulinTime)
            cell.loggedInsulinTime.text = insulinTimeString
        }
        else {
            print("ERROR: CurrentExercise time is nil")
            cell.loggedInsulinTime.text = "ERROR"
        }
        if currentInsulin.mealBolus != 0 {
            cell.loggedInsulinImage.image = #imageLiteral(resourceName: "apple")
            cell.loggedInsulinImage.tintColor = #colorLiteral(red: 0.9764705882, green: 0.6235294118, blue: 0.2196078431, alpha: 1)
        } else {
            cell.loggedInsulinImage.image = #imageLiteral(resourceName: "blood")
            cell.loggedInsulinImage.tintColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        }
        
        if currentInsulin.units == currentInsulin.unitsUser {
            cell.loggedInsulinDetail.text = String(format: "%.1f",  currentInsulin.mealBolus) + "U Meal + " + String(format: "%.1f",  currentInsulin.corrBolus) + "U Correct"
        } else {
            cell.loggedInsulinDetail.text = ""
        }
        
        
        return cell
    }
    
    ///Updates the table by re-fetching either a list of exercise for that day, or the user's favourites
    @objc private func updateTable(){
        let loggedInsulin = ModelController().fetchInsulin(day: currentDay)
        self.loggedInsulin = loggedInsulin
        self.insulinLogTable.reloadData()
        
    }

    @objc func addPrediction(notification: Notification) {
        guard let prediction = notification.object as? Float else {
            print("ERROR: prediction object could not be cast to float")
            return
        }
        let lastGlucose = ModelController().fetchRecentGlucose()
        guard !lastGlucose.isEmpty else {
            return
        }
        if let predictionTime = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            let formattedPredTime = dateFormatter.string(from: predictionTime)
            predictionValueLabel.text = String(format: "%.1f", (Double(prediction) + lastGlucose[lastGlucose.count - 1].value))
            predictionDetailLabel.text = "mmol/l at " + formattedPredTime
        }
        
    }
    
    @IBAction func predictionCall(_ sender: Any) {
        model?.predict()
    }
    
    
}

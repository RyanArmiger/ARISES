//
//  ViewControllerGraph.swift
//  ARISES
//  This file deals with everything graph related. Base chart library (Podfile):
//  Created by Ryan Armiger on 16/05/2018.
//  Copyright Â© 2018 Ryan Armiger. All rights reserved.
//

import Charts
import UIKit
import Foundation

/**
*	The UIViewController subclass for the top half of the app's UI. It controls the bifocal display utilising the SwiftCharts library, referenced in
*	the documentation.
*/
class ViewControllerGraph: UIViewController {

    
    @IBOutlet weak var trendArrow: UIButton!
    @IBOutlet weak var glucoseField: UITextField!
    
    @IBOutlet weak var chartView: LineChartView!
    //MARK: Chart Area Variables
    
//    private var dataLoaded: Bool = false
//    private var didLayout: Bool = false
    private var glucoseArr: [GlucoseMO]?

 
    
    @IBOutlet weak var pickerTextField: UITextField!
	///DatePicker used to change and display date
    let picker = UIDatePicker()
    
	/// Initializes the app to today
    var today = Calendar.current.startOfDay(for: Date())

    //MARK: Methods
	
    /**
	*	This function is an override of the same function in the superclass which is called after the view has loaded. It calls the functions 
	*	responsible for rotating the sideView containers, creating the DatePicker, update any settings and add the notification listeners.
	*	
	*	- Returns: Null
	*/
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Declares Notifications
        let nc = NotificationCenter.default
//        nc.addObserver(self, selector: #selector(updateGraph), name: Notification.Name("newGlucoseValue"), object: nil)
        nc.addObserver(self, selector: #selector(updateGraph), name: Notification.Name("GlucoseAdded"), object: nil)
        nc.addObserver(self, selector: #selector(setDay(notification:)), name: Notification.Name("setDay"), object: nil)
        createDatePicker()
        
//        glucoseArr = ModelController().fetchGlucose(day: today)
        //        print(glucoseArr?.count)
        nc.addObserver(self, selector: #selector(updateGlucoseValue(notification:)), name: Notification.Name("newGlucoseValue"), object: nil)
        self.trendArrow.setImage(#imageLiteral(resourceName: "hyper"), for: .normal)

        updateGraph()

    }
    
    /**
    *	Function called when a Notification is detected upon the date being changed. Used to synchronize the app.
    *	- Parameter notification: Notification, detected by NotificationCenter's observer.
    */
    @objc func setDay(notification: Notification){
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none

        let dayToSet = notification.object as! Date
//        today = dateFormatter.date(from: dayToSet)!
        today = dayToSet
        formatWeekday(date: today)
        updateDay()
//        glucoseArr = ModelController().fetchGlucose(day: today)
        updateGraph()
    }
	
	/// Creates a Notification used to synchronize the Date throughout the app.
    func updateDay(){
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("dayChanged"), object: today)
    }

    /**
	*	Takes the date as argument and converts it to the format 'weekday day month, year', then places it in the DatePicker.
    * - Parameter date: Date to be transformed
    */
    func formatWeekday(date: Date){
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "EEEE, dd MMMM"
        pickerTextField.text = weekdayFormatter.string(from:date)
        pickerTextField.sizeToFit()
    }
    
    
    /**
    *	Create a date picker and formats today's date as required and displays it.
    */
    func createDatePicker(){
        
        formatWeekday(date: Date())
        picker.datePickerMode = .date
        picker.maximumDate = Date()
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(donePressed))
        toolbar.setItems([done], animated: false)
        pickerTextField.inputAccessoryView = toolbar
        pickerTextField.inputView = picker
        
        
    }
	
	///	Function called after the user has finished with the DatePicker and synchronizes the date used for the chart with the viewController.
    @objc func donePressed(){
        formatWeekday(date: picker.date)
        self.view.endEditing(true)

        today = Calendar.current.startOfDay(for: picker.date)
        updateDay()
        picker.date = Date()
//        glucoseArr = ModelController().fetchGlucose(day: today)
        updateGraph()
    }
    
    @objc
    private func updateGraph() {
        glucoseArr = ModelController().fetchGlucose(day: today)
        guard glucoseArr != [] else {
            chartView.isHidden = true
            return
        }
        chartView.isHidden = false
        guard let arr = glucoseArr else {
            return
        }
        
        var lineChartEntry = [ChartDataEntry]()
        //        let today = Calendar.current.startOfDay(for: Date())
        
        // Define chart xValues formatter
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale.current
        
        let referenceTimeInterval = Double(0)
        let xValuesNumberFormatter = ChartXAxisFormatter(referenceTimeInterval: referenceTimeInterval, dateFormatter: formatter)
        
        //For this to work correctly glucoseArr needs to be in ASCENDING order, or it won't show up
        for gluc in arr {
            if let xTime = gluc.time?.timeIntervalSinceReferenceDate {
                let value = ChartDataEntry(x: xTime / ( 3_600 * 24 ), y: gluc.value)
                lineChartEntry.append(value)
            }
        }
        
        let line1 = LineChartDataSet(values: lineChartEntry, label: "BG mmol/l")
        line1.colors = [NSUIColor.blue]
        line1.drawCirclesEnabled = true
        line1.drawCircleHoleEnabled = false
        line1.circleRadius = 3
        line1.circleColors = [NSUIColor.gray]
        
        let data = LineChartData()
        data.addDataSet(line1)
        data.setDrawValues(false)
        chartView.xAxis.valueFormatter = xValuesNumberFormatter
        chartView.xAxis.labelPosition = XAxis.LabelPosition.bottom
        chartView.legend.enabled = false
        //        let customYAxis = CustomYAxisRenderer(viewPortHandler: chartView.viewPortHandler, yAxis: chartView.getAxis(.left), transformer: chartView.getTransformer(forAxis: .left))
        //        chartView.leftYAxisRenderer = customYAxis
        //        chartView.leftAxis.drawGridLinesEnabled = true
        chartView.data = data
        //        chartView.chartDescription?.text = "Blood glucose chart"
    }
    
    /// Called when a new glucose log is added to the database. Updates labels related to that information e.g. Glucose value, IOB
    ///
    /// - Parameter notification: an NSGlucose log
    @objc
    func updateGlucoseValue(notification: Notification) {
        guard let loggedGlucose = notification.object as? GlucoseMO else {
            print("ERROR: Glucose value passed as notification cannot be downcast to NSGlucose")
            glucoseField.text = ""
            return
        }
        
        
        glucoseField.text = String(format: "%.1f", loggedGlucose.value)
        
//        print("GLUCOSE TREND: \(loggedGlucose.g)")
        let glucoseTrend = self.getRotation(value: Int(loggedGlucose.trend))
        if glucoseTrend == 1.5 * CGFloat.pi {
            self.trendArrow.setImage(#imageLiteral(resourceName: "hyper"), for: .normal)
        } else {
            self.trendArrow.setImage(#imageLiteral(resourceName: "hyper"), for: .normal)
            UIView.animate(withDuration: 2.0, animations: {
                //            self.trendArrow.transform = CGAffineTransform(rotationAngle: self.getRotation(value: loggedGlucose.value))
                self.trendArrow.transform = CGAffineTransform(rotationAngle: glucoseTrend)
            })
        }
        
    }
    
    /// Function to map a glucose value to a rotation for testing a trend arrow
    ///
    /// - Parameter value: blood glucose value, currently in mmol/l
    /// - Returns: CGFloat value relating to a rotation between 0 and pi
    private func getRotation(value: Int) -> CGFloat {
        if value <= -90 || value >= 90 {
            return 1.5 * CGFloat.pi
        } else if value < 10 && value > -10 {
            return ( 1 / 2 ) * CGFloat.pi
        } else if value <= -10 && value > -20 {
            return ( 3 / 4 ) * CGFloat.pi
        } else if value <= -20 && value > -30 {
            return CGFloat.pi
        } else if value >= 10 && value < 20 {
            return ( 1 / 4 ) * CGFloat.pi
        } else if value >= 20 && value < 30 {
            return CGFloat.pi
        } else if value < 90 && value >= 30 {
            return 0
        } else if value > -90 && value <= -30 {
            return CGFloat.pi
        } else {
            return 1.5 * CGFloat.pi
        }
    }
}


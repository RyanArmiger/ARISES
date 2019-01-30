//
//  ViewControllerMain.swift
//  ARISES
//
//  Created by Ryan Armiger on 16/05/2018.
//  Copyright © 2018 Ryan Armiger. All rights reserved.
//

import UIKit

///State enum for domain tabs
enum MainViewState
{
    ///A default state currently overwritten in viewDidLoad to .food
    case uninitialised
    ///State where health domain is visible
    case health
    ///State where food domain is visible
    case food
    ///State where exercise domain is visible
    case exercise
    ///State where advice domain is visible
    case advice
}

/**
Controls transitions between domains by showing and hiding domain and indicator views.
Also controls insulin entry views.
 */
class ViewControllerMain: UIViewController{
    
    //MARK: - Outlets
    // Views with status indicators
    
    @IBOutlet weak private var tabsContainerView: UIView!
    @IBOutlet weak private var viewHealth: UIView!
    @IBOutlet weak private var viewFood: UIView!
    @IBOutlet weak private var viewAdvice: UIView!
    @IBOutlet weak private var viewExercise: UIView!
    // Containers for embedding view contents
    @IBOutlet weak private var containerHealth: UIView!
    @IBOutlet weak private var containerFood: UIView!
    @IBOutlet weak private var containerAdvice: UIView!
    @IBOutlet weak private var containerExercise: UIView!
    // Indicator outlet for toggling
    @IBOutlet weak private var indicatorFood: UIView!
    @IBOutlet weak private var indicatorExercise: UIView!
    @IBOutlet weak private var indicatorHealth: UIView!
    @IBOutlet weak private var indicatorAdvice: UIView!
    
    //Labels
    @IBOutlet weak private var foodLabel: UILabel!
    @IBOutlet weak private var exerciseLabel: UILabel!
    @IBOutlet weak private var adviceLabel: UILabel!
    @IBOutlet weak private var healthLabel: UILabel!
    
    
    //Insulin outlets
    @IBOutlet weak private var glucoseButtonOutlet: UIButton!
    @IBOutlet weak private var insulinTextField: UITextField!
    @IBOutlet weak private var glucoseClockOutlet: UIButton!
    @IBOutlet weak private var insulinTimeField: UITextField!
    
    //MARK: - Properties
    ///Tracks date set by graph and hides insulin entry fields when not on current day
    private var currentDay = Date(){
        didSet{
            if currentDay != Calendar.current.startOfDay(for: Date()) {
                glucoseButtonOutlet.tintColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
                glucoseButtonOutlet.isHidden = true
                insulinTextField.isHidden = true
                glucoseClockOutlet.tintColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
                glucoseClockOutlet.isHidden = true
                insulinTimeField.isHidden = true
            }
            else{
                glucoseButtonOutlet.tintColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
                glucoseButtonOutlet.isHidden = false
                insulinTextField.isHidden = true
                glucoseClockOutlet.tintColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
                glucoseClockOutlet.isHidden = true
                insulinTimeField.isHidden = true
            }
        }
    }
    ///Instantiates Date Picker for insulin time selection
    private var insulinTimePicker = UIDatePicker()
    ///Stores whether keyboard is open, to smooth transitions between tabs
//    private var keyboardOpen = false
    private var insulinTimestamp: Date?
    
    // Variables for rounding and shadow extension
    private var shadowLayer: CAShapeLayer!
    private var cornerRadius: CGFloat = 25.0
    private var fillColor: UIColor = .blue
    ///Variable to track state of views
    private var state: MainViewState = .uninitialised
    {
        didSet
        {
            updateViews()
        }
    }
    // Variable to track which value to add to database every 5 minutes
    private var loadCounter: Int = 0
    private var loadDate: Date?
    
    //MARK: - Override viewDidLoad
    /**viewDidLoad override to set initial state of:
     Insulin date entry field,
     TimePicker instantiation,
     Observer to act on current graph day changing,
     Observers to act based on keyboard state
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        self.state = .food
        
        glucoseButtonOutlet.tintColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
        glucoseButtonOutlet.isHidden = false
        insulinTextField.isHidden = true
        glucoseClockOutlet.tintColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
        glucoseClockOutlet.isHidden = true
        insulinTimeField.isHidden = true
        
        //Data entry 'done' toolbars
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.doneWithKeypad))
        
        toolBar.setItems([flexible, doneButton], animated: true)
        
        insulinTextField.inputAccessoryView = toolBar
        
        //Instantiates picker for insulin time entry
        createInsulinTimePicker()
        
        let nc = NotificationCenter.default
        //Observer to update currentDay variable to match graph's day
        nc.addObserver(self, selector: #selector(updateDay(notification:)), name: Notification.Name("dayChanged"), object: nil)
        
        loadDate = Date()
        //Observers to determine keyboard state
//        nc.addObserver(self, selector: #selector(keyboardWillShow(sender:)), name: UIResponder.keyboardWillShowNotification, object: nil)
//
//        nc.addObserver(self, selector: #selector(keyboardWillHide(sender:)), name: UIResponder.keyboardWillHideNotification, object: nil)
//        readCSV()
//        startTimer()
        
//
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
    }
    
    private func updateSimulationData() {
        // THIS IS TERRIBLE CODE RIGHT NOW.
        // Better way to do it, if this code is important, is to pre-load the amount based on time passed
        // Then create a new function in model controller to add all without saving and giving notification until end
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                // 3
                guard let strongSelf = self else {
                    return
                }
                guard let _ = strongSelf.loadDate else {
                    print("ERROR: loadDate is nil")
                    return
                }
                let glucoseStartDate = Calendar.current.startOfDay(for: strongSelf.loadDate!)
                //FIND A BETTER WAY
    //            print("loadDate: \(strongSelf.loadDate) Date \(Date())")
    //            print("is <:  \(strongSelf.loadDate! < Date())" )
                while strongSelf.loadDate! < Date() {
                    guard let row = strongSelf.readCSV(row: strongSelf.loadCounter) else {
                        print("ERROR: readCSV failed to return a non-nil value")
                        return
                    }
                    guard let glucoseValue = Double(row[1]) else {
                        print("ERROR: GlucoseValue is nil")
                        return
                    }
                    //            let dateFormatter = DateFormatter()
                    //            dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
                    //            guard let glucoseDate = loadDate else {
                    ////                    print("Whaaaa 2 \(dateFormatter.date(from: row[0]))")
                    //                print("ERROR: GlucoseDate formatted to nil")
                    //                return
                    //            }
                    //            print(glucoseStartDate)
                    //                print("GlucoseValue: \(glucoseValue), GlucoseDate: \(glucoseDate), GlucoseStart: \(glucoseStartDate)")
                    ModelController().addGlucose(value: glucoseValue, time: strongSelf.loadDate!, date: glucoseStartDate)
                    strongSelf.loadCounter = strongSelf.loadCounter + 1
                    strongSelf.loadDate = strongSelf.loadDate!.addingTimeInterval(300)
                    
                }
            }
        }
    }
    
    private func updateSimulationData2() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                return
            }
            DispatchQueue.main.async { [weak self] in
                // 3
                guard let strongSelf = self else {
                    return
                }
                guard let _ = strongSelf.loadDate else {
                    print("ERROR: loadDate is nil")
                    return
                }
                let difference = Date().timeIntervalSince(strongSelf.loadDate!)
//                print("TimeDifference: ", difference)
                let numPassed = difference / 300
                guard numPassed > 1 else {
                    return
                }
                let glucoseStartDate = Calendar.current.startOfDay(for: strongSelf.loadDate!)
                guard let row = strongSelf.readAllCSV(row: strongSelf.loadCounter) else {
                    print("ERROR: readCSV failed to return a non-nil value")
                    return
                }
                var glucoseVal = [Double]()
                for tuple in row[strongSelf.loadCounter..<(strongSelf.loadCounter+Int(floor(numPassed)))] {
                    glucoseVal.append(Double(tuple[1])!)
                }

                ModelController().addGlucoseArr(value: glucoseVal, time: strongSelf.loadDate!, date: glucoseStartDate)
                strongSelf.loadCounter = strongSelf.loadCounter + Int(floor(numPassed))
                
                let timeAdd = 300 * floor(numPassed)
                strongSelf.loadDate = strongSelf.loadDate!.addingTimeInterval(timeAdd)
                
            }
        }
    }
    
    private func updateSimulationData3() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in

            // 3
            guard let strongSelf = self else {
                return
            }
            guard let _ = strongSelf.loadDate else {
                print("ERROR: loadDate is nil")
                return
            }
            let difference = Date().timeIntervalSince(strongSelf.loadDate!)
            //                print("TimeDifference: ", difference)
            let numPassed = difference / 300
            guard numPassed > 1 else {
                return
            }
            let glucoseStartDate = Calendar.current.startOfDay(for: strongSelf.loadDate!)
            guard let row = strongSelf.readAllCSV(row: strongSelf.loadCounter) else {
                print("ERROR: readCSV failed to return a non-nil value")
                return
            }
            var glucoseVal = [Double]()
            for tuple in row[strongSelf.loadCounter..<(strongSelf.loadCounter+Int(floor(numPassed)))] {
                glucoseVal.append(Double(tuple[1])!)
            }
//            print(glucoseVal.count)
            ModelController().addGlucoseArr(value: glucoseVal, time: strongSelf.loadDate!, date: glucoseStartDate)
            strongSelf.loadCounter = strongSelf.loadCounter + Int(floor(numPassed))
            
            let timeAdd = 300 * floor(numPassed)
            strongSelf.loadDate = strongSelf.loadDate!.addingTimeInterval(timeAdd)
            
            DispatchQueue.main.async {
                let nc = NotificationCenter.default
                nc.post(name: Notification.Name("GlucoseAdded"), object: nil)
            }
        }
    
    }
    
    
//
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        switch UIDevice.current.orientation{
        case .portrait: break
//            tabsContainerView.isHidden = false
        case .portraitUpsideDown: break
//            tabsContainerView.isHidden = false
        case .landscapeLeft:
            tabsContainerView.isHidden = true
        case .landscapeRight:
            tabsContainerView.isHidden = true
        default:
            tabsContainerView.isHidden = false
        }
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        switch UIDevice.current.orientation{
        case .portrait:
            tabsContainerView.isHidden = false
        case .portraitUpsideDown:
            tabsContainerView.isHidden = false
        case .landscapeLeft: break
//            tabsContainerView.isHidden = true
        case .landscapeRight: break
//            tabsContainerView.isHidden = true
        default:
            tabsContainerView.isHidden = false
        }
    }
    
//   private weak var timer: Timer?
//
//    private func startTimer() {
//        timer?.invalidate()   // just in case you had existing `Timer`, `invalidate` it before we lose our reference to it
//        timer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
//            guard let strongSelf = self else {
//                return
//            }
//            guard let row = strongSelf.readCSV(row: strongSelf.loadCounter) else {
//                return
//            }
//            guard let glucoseValue = Double(row[1]) else {
//                print("ERROR: GlucoseValue is nil")
//                return
//            }
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
//            guard let glucoseDate = strongSelf.loadDate else {
////                    print("Whaaaa 2 \(dateFormatter.date(from: row[0]))")
//                print("ERROR: GlucoseDate formatted to nil")
//                return
//            }
//            let glucoseStartDate = Calendar.current.startOfDay(for: glucoseDate)
////            print(glucoseStartDate)
////                print("GlucoseValue: \(glucoseValue), GlucoseDate: \(glucoseDate), GlucoseStart: \(glucoseStartDate)")
//            ModelController().addGlucose(value: glucoseValue, time: glucoseDate, date: glucoseStartDate)
//            print("Timer goes tick")
//            strongSelf.loadCounter = strongSelf.loadCounter + 1
//            strongSelf.loadDate = strongSelf.loadDate?.addingTimeInterval(300)
//        }
//    }
//
//    private func stopTimer() {
//        timer?.invalidate()
//    }
//
//    deinit {
//        stopTimer()
//    }

    private func readCSV(row: Int) -> [String]? {
        guard let csvPath = Bundle.main.path(forResource: "ABC4001_CGM_6m_I", ofType: "csv") else { return nil }

        do {
            let csvData = try String(contentsOfFile: csvPath, encoding: String.Encoding.utf8)
            let csv = csvData.csvRows()
//            let csvLength = csv.count
            return csv[row]
//            print(csv.count)
//            for row in csv[1..<csvLength] {
////                let row = csv[index]
////                print("date: \(row[0]), glucose: \(row[1])")
////                print("glucose: \(row[1])")
//                guard let glucoseValue = Double(row[1]) else {
//                    print("Whaaaa")
//                    return
//                }
//                let dateFormatter = DateFormatter()
//                dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
//                guard let glucoseDate = dateFormatter.date(from: row[0]) else {
////                    print("Whaaaa 2 \(dateFormatter.date(from: row[0]))")
//                    print("Whaaa 2")
//                    return
//                }
//                let glucoseStartDate = Calendar.current.startOfDay(for: glucoseDate)
//                print(glucoseStartDate)
////                print("GlucoseValue: \(glucoseValue), GlucoseDate: \(glucoseDate), GlucoseStart: \(glucoseStartDate)")
//                ModelController().addGlucose(value: glucoseValue, time: glucoseDate, date: glucoseStartDate)
//            }
        } catch{
            print("ERROR: \(error)")
            return nil
        }
    }
    
    private func readAllCSV(row: Int) -> [[String]]? {
        guard let csvPath = Bundle.main.path(forResource: "ABC4001_CGM_6m_I", ofType: "csv") else { return nil }
        
        do {
            let csvData = try String(contentsOfFile: csvPath, encoding: String.Encoding.utf8)
            let csv = csvData.csvRows()
            //            let csvLength = csv.count
            return csv
            //            print(csv.count)
            //            for row in csv[1..<csvLength] {
            ////                let row = csv[index]
            ////                print("date: \(row[0]), glucose: \(row[1])")
            ////                print("glucose: \(row[1])")
            //                guard let glucoseValue = Double(row[1]) else {
            //                    print("Whaaaa")
            //                    return
            //                }
            //                let dateFormatter = DateFormatter()
            //                dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
            //                guard let glucoseDate = dateFormatter.date(from: row[0]) else {
            ////                    print("Whaaaa 2 \(dateFormatter.date(from: row[0]))")
            //                    print("Whaaa 2")
            //                    return
            //                }
            //                let glucoseStartDate = Calendar.current.startOfDay(for: glucoseDate)
            //                print(glucoseStartDate)
            ////                print("GlucoseValue: \(glucoseValue), GlucoseDate: \(glucoseDate), GlucoseStart: \(glucoseStartDate)")
            //                ModelController().addGlucose(value: glucoseValue, time: glucoseDate, date: glucoseStartDate)
            //            }
        } catch{
            print("ERROR: \(error)")
            return nil
        }
    }
    
    
    //MARK: - Update Day
    ///Updates the currentDay variable with a date provided via notification from ViewControllerGraph
    @objc private func updateDay(notification: Notification) {
        currentDay = notification.object as! Date
    }
    
    //MARK: - Functions for tracking when keyboard open
//    @objc private func keyboardWillShow(sender: NSNotification) {
////        keyboardOpen = true
//    }
//    @objc private func keyboardWillHide(sender: NSNotification) {
////        keyboardOpen = false
//    }
    
    //MARK: - View re-positioning
    /**
     Func to set state cases: .food, .exercise, .health or .advice.
     This hides other embedded views and brings chosen domain to the front
     */
    private func updateViews()
    {
        switch self.state
        {
        case .food:
            tabsContainerView.bringSubviewToFront(viewFood)
            containerFood.isHidden = false
            containerAdvice.isHidden = true
            containerHealth.isHidden = true
            containerExercise.isHidden = true
            indicatorFood.isHidden = true
            indicatorAdvice.isHidden = false
            indicatorHealth.isHidden = false
            indicatorExercise.isHidden = false
            
            foodLabel.isHidden = true
            healthLabel.isHidden = false
            exerciseLabel.isHidden = false
            adviceLabel.isHidden = false
            
        case .exercise:
            self.tabsContainerView.bringSubviewToFront(self.viewExercise)
            containerFood.isHidden = true
            containerAdvice.isHidden = true
            containerHealth.isHidden = true
            containerExercise.isHidden = false
            indicatorFood.isHidden = false
            indicatorAdvice.isHidden = false
            indicatorHealth.isHidden = false
            indicatorExercise.isHidden = true
            
            foodLabel.isHidden = false
            healthLabel.isHidden = false
            exerciseLabel.isHidden = true
            adviceLabel.isHidden = false
            
        case .health:
            self.tabsContainerView.bringSubviewToFront(self.viewHealth)
            containerFood.isHidden = true
            containerAdvice.isHidden = true
            containerHealth.isHidden = false
            containerExercise.isHidden = true
            indicatorFood.isHidden = false
            indicatorAdvice.isHidden = false
            indicatorHealth.isHidden = true
            indicatorExercise.isHidden = false
            
            foodLabel.isHidden = false
            healthLabel.isHidden = true
            exerciseLabel.isHidden = false
            adviceLabel.isHidden = false
            
        case .advice:
            tabsContainerView.bringSubviewToFront(viewAdvice)
            containerFood.isHidden = true
            containerAdvice.isHidden = false
            containerHealth.isHidden = true
            containerExercise.isHidden = true
            indicatorFood.isHidden = false
            indicatorAdvice.isHidden = true
            indicatorHealth.isHidden = false
            indicatorExercise.isHidden = false
            
            foodLabel.isHidden = false
            healthLabel.isHidden = false
            exerciseLabel.isHidden = false
            adviceLabel.isHidden = true
            
        case .uninitialised:
            print("uninitialised view state")
        }
    }
    
    //MARK: - Buttons to open each domain
    ///Sets state to .health, updating the view to display the health domain
    @IBAction private func healthButton(_ sender: UIButton) {
        self.state = .health
    }
    ///Sets state to .food, updating the view to display the food domain. If keyboard is open when set (only possible from Exercise domain), it is dismissed and state change is delayed to smooth the transition
    @IBAction private func foodButton(_ sender: UIButton) {
        //If keyboard is open and tab is swapped, dismiss it and then change state smoothly
//        if keyboardOpen == true{
        view.endEditing(true)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
//                self.state = .food
//            }
//        }
//        else{
        self.state = .food
//        }
    }
    ///Sets state to .exercise, updating the view to display the exercise domain. If keyboard is open when set (only possible from Food domain), it is dismissed and state change is delayed to smooth the transition
    @IBAction private func exerciseButton(_ sender: UIButton) {
//        if keyboardOpen == true{
//            view.endEditing(true)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
        view.endEditing(true)

        self.state = .exercise
//            }
//        }
//        else{
//            self.state = .exercise
//        }
    }
    ///Sets state to .advice, updating the view to display the advice domain
    @IBAction private func adviceButton(_ sender: UIButton) {
        updateSimulationData3()
        self.state = .advice
    }
    
    
    //MARK: - Insulin actions
    ///Insulin clock icon: Toggles a text field with a time picker to enter time of insulin dose
    @IBAction private func glucoseClockButton(_ sender: Any) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if self.glucoseClockOutlet.tintColor == #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1) {
                self.glucoseClockOutlet.tintColor = #colorLiteral(red: 0.3921568627, green: 0.737254902, blue: 0.4392156863, alpha: 1)
                self.insulinTimeField.isHidden = false
            }
            else{
                self.glucoseClockOutlet.tintColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
                self.insulinTimeField.isHidden = true
            }
        }
    }
    /**
     Insulin button (blood symbol): Toggles visibility of insulin text field and insulin clock icon. When closed, if a value has been entered it will be added to the database. If no time value was entered, the current time will be used.
    */
    @IBAction private func glucoseButton(_ sender: Any) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            if self.glucoseButtonOutlet.tintColor == #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1) {
                self.glucoseButtonOutlet.tintColor = #colorLiteral(red: 0.3921568627, green: 0.737254902, blue: 0.4392156863, alpha: 1)
                self.insulinTextField.isHidden = false
                self.glucoseClockOutlet.isHidden = false
                
            }
            else{
                self.glucoseButtonOutlet.tintColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
                self.insulinTextField.isHidden = true
                self.glucoseClockOutlet.isHidden = true
                self.glucoseClockOutlet.tintColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)
                self.insulinTimeField.isHidden = true
                
                //add insulin if not nil
                if (self.insulinTextField.text != ""){
                    if self.insulinTimeField.text != ""{
                        guard let insulinTime = self.insulinTimestamp else {
                            return
                        }
                        ModelController().addInslin(units: Double((self.insulinTextField.text)!)!, time: insulinTime, date: Date())
                        self.insulinTextField.text = ""
                    }
                    else{
                        ModelController().addInslin(units: Double((self.insulinTextField.text)!)!, time: Date(), date: Date())
                        
                        self.insulinTextField.text = ""
                        self.insulinTimeField.text = ""
                    }
                }
            }
        }
    }
    
    
    ///Insulin Time picker
    private func createInsulinTimePicker(){
        
        let doneButtonBar = UIToolbar()
        doneButtonBar.sizeToFit()
        
        let flexible = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: #selector(doneWithPicker))
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(doneWithPicker))
        
        doneButtonBar.setItems([flexible, doneButton], animated: true)
        
        insulinTimeField.inputAccessoryView = doneButtonBar
        insulinTimeField.inputView = insulinTimePicker
        
        insulinTimePicker.datePickerMode = .time
    }
    @objc private func doneWithPicker(){
        insulinTimestamp = insulinTimePicker.date
        insulinTimeField.text = ModelController().formatDateToHHmm(date: insulinTimePicker.date)
        self.view.endEditing(true)
    }
    
    @objc private func doneWithKeypad(){
        view.endEditing(true)
    }
    
    //MARK: - Settings
    ///Opens phone settings
    @IBAction func settingsPopup(_ sender: Any) {
        UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
    }
}

//MARK: - Extensions
//Rounding view and shadow inspectable extensions
extension UIView {
    func setRadius(radius: CGFloat? = nil) {
        self.layer.cornerRadius = radius ?? self.frame.width / 8
        self.layer.masksToBounds = true
        
    }
}

extension UIView {
    
    @IBInspectable
    var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
    
    @IBInspectable
    var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable
    var borderColor: UIColor? {
        get {
            if let color = layer.borderColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.borderColor = color.cgColor
            } else {
                layer.borderColor = nil
            }
        }
    }
    
    @IBInspectable
    var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }
    
    @IBInspectable
    var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }
    
    @IBInspectable
    var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }
    
    @IBInspectable
    var shadowColor: UIColor? {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return nil
        }
        set {
            if let color = newValue {
                layer.shadowColor = color.cgColor
            } else {
                layer.shadowColor = nil
            }
        }
    }
}



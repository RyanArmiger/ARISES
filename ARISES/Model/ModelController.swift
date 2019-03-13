//
//  ModelController.swift
//  ARISES
//
//  Created by Ryan Armiger on 25/05/2018.
//  Copyright © 2018 Ryan Armiger. All rights reserved.
//

import Foundation
import CoreData

/**
Provides fuctions to safely add and fetch objects from the persistent relational database 'Core Data'
 */
class ModelController {

    //TODO: - Abstract functions to apply to food, exercise and days etc.

    //MARK: - Basic date formatting functions
    //Returns strings
    
    /// - parameter date: Date, date to be formatted as start of day
    /// - returns: Date corresponding to beginning of day provided 
    func formatDateToDay(date: Date) -> Date{
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateStyle = .short
//        dateFormatter.timeStyle = .none
//        return dateFormatter.string(from: date)
        return Calendar.current.startOfDay(for: date)
    }
    /// - parameter date: Date, date to be formatted to HHmm and returned as a string
    /// - returns: String of input date's time component in HH:mm format e.g. 11:35
    func formatDateToHHmm(date: Date) -> String{
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return timeFormatter.string(from: date)
    }

    //MARK: - Private functions
    /**
     Checks for an existing favourites object
     - Returns: Existing favourites object or a newly created favourites object if none existed
     */
    private func checkForExistingFavourites() -> Favourites{
        let favFetch: NSFetchRequest<Favourites> = Favourites.fetchRequest()
        let checkFav = try? PersistenceService.context.fetch(favFetch)
        if checkFav != nil{
            if checkFav?.count != 0{
                return checkFav![0]
                }
            else{
                let newFav = Favourites(context: PersistenceService.context)
                PersistenceService.saveContext()
                return newFav
            }
        }
        print("Error fetching favourites")
        return checkFav![0]
    }

    /**
     Checks for an existing Day log or creates one
     - parameter day: Date of day log to be found (type Date)
     - returns: Day object with date (not time) corresponding to input date, or a newly created Day object for that date
     */
    func findOrMakeDay(day: Date) -> Day {
        //        let day = formatDateToDay(date: day)
        let dayStart = Calendar.current.startOfDay(for: day)
        let dateFetch: NSFetchRequest<Day> = Day.fetchRequest()
        dateFetch.predicate = NSPredicate(format: "date == %@", dayStart as CVarArg)
        let checkForDay = try? PersistenceService.context.fetch(dateFetch)
        if checkForDay != nil {
            if checkForDay?.isEmpty == false {
//                print("NotNewDate: \(checkForDay!.first!)")
                return (checkForDay!.first!)
            } else {
                let newDay = Day(context: PersistenceService.context)
                newDay.date = dayStart
//                print("NewDay: \(newDay.date)")
                PersistenceService.saveContext()
                return newDay
            }
        }
        print("Error finding or creating day log")
        return checkForDay![0]
        //Should never happen
    }
    
    
    //MARK: - Data object setting (add/toggle)
    
    
    /**
     Adds a new meal log to core data.
     - parameter name: String, Name of meal to add.
     - parameter time: String, Time of meal consumed.
     - parameter date: Date, Date of meal to add.
     - parameter carbs: Int32, Total carbs (grams) of meal to add.
     - parameter fat: Int32, Total fat (grams) of meal to add.
     - parameter protein: Int32, Total protein (grams) of meal to add.
     - Note: Posts a notification "FoodAdded" which is picked up by viewControllerGraph and IndicatorControllerFood to update views.
     */
    func addMeal(name: String, time: Date, date: Date, carbs: Int32, fat: Int32, protein: Int32){
        print("meal added")
        let currentDay = findOrMakeDay(day: date)
        let newMeal = Meals(context: PersistenceService.context)
        newMeal.name = name
        newMeal.time = time
        newMeal.carbs = carbs
        newMeal.protein = protein
        newMeal.fat = fat
        currentDay.addToMeals(newMeal)
        PersistenceService.saveContext()
        
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("FoodAdded"), object: nil)

    }
    
    /**
     Adds a new exercise log to core data
     - parameter name: String, Name of exercise to add
     - parameter time: String, Time of exercise done
     - parameter date: Date, Date of exercise to add
     - parameter intensity: String, inensity of exercise to add
     - parameter duration: String, duration of exercise to add
     - note: Posts a notification "ExerciseAdded" which is picked up by viewControllerGraph to update views
     */
    func addExercise(name: String, time: Date, date: Date, intensity: String, duration: String){
        
        let currentDay = findOrMakeDay(day: date)
        let newExercise = Exercise(context: PersistenceService.context)
        newExercise.name = name
        newExercise.time = time
        newExercise.intensity = intensity
        newExercise.duration = duration
        currentDay.addToExercise(newExercise)
        PersistenceService.saveContext()
        
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("ExerciseAdded"), object: nil)
    }
    
//    /**
//     Adds a new glucose log to core data
//     - parameter value: Double, Value of glucose in mM/L
//     - parameter time: String, Time of glucose log
//     - parameter date: Date, Date of glucose log to add
//     */
//    func addGlucose(value: Double, time: Date, date: Date){
//
//        let currentDay = findOrMakeDay(day: date)
//        let newGlucose = Glucose(context: PersistenceService.context)
//        newGlucose.value = value
//        newGlucose.time = time
//        currentDay.addToGlucose(newGlucose)
//        PersistenceService.saveContext()
//
//        let nc = NotificationCenter.default
//        nc.post(name: Notification.Name("GlucoseAdded"), object: nil)
//
//    }
//
    
    /**
     Adds a new glucose log to core data
     
     - parameter value: Double, Value of glucose in mM/L or mg/dL depending on setting
     - parameter time: String, Time of glucose log
     - parameter date: Date, Date of glucose log to add
     */
    func addGlucose(value: Double, time: Date, trend: Int32, date: Date) {
        guard value < 25 else {
            //Need to change this depending on units
            print("Glucose value too high: \(value)")
            return
        }
        let currentDay = findOrMakeDay(day: date)
        let newGlucose = GlucoseMO(context: PersistenceService.context)
        newGlucose.value = value
        newGlucose.time = time
        newGlucose.trend = trend
//        newGlucose.mealIOB = Float(0.9)
//        newGlucose.correctionIOB = Float(0.2)
        currentDay.addToGlucose(newGlucose)
        PersistenceService.saveContext()
        //        nc.post(name: Notification.Name("newGlucoseValue"), object: nil)
        NotificationCenter.default.post(name: Notification.Name("GlucoseAdded"), object: nil)
        NotificationCenter.default.post(name: Notification.Name("newGlucoseValue"), object: newGlucose)

        
    }

//    func addGlucoseArr(value: [Double], time: Date, date: Date){
////        print("adding arr")
//        var runningTime = time
//        let currentDay = findOrMakeDay(day: date)
//        for val in value{
//            let newGlucose = GlucoseMO(context: PersistenceService.context)
//            newGlucose.value = val
//            newGlucose.time = runningTime
//            currentDay.addToGlucose(newGlucose)
//            runningTime = runningTime.addingTimeInterval(300)
//        }
//        PersistenceService.saveContext()
//    }
//
 
//    func addTemp(timestamp: Double, array: [Float]){
//        let currentDay = findOrMakeDay(day: date)
//        for temp in array {
//            let newTemp = Temperature(context: PersistenceService.context)
//            newTemp.temperature = temp
//            newTemp.time = time
//            currentDay.addToTemp(newTemp)
//        }
//        PersistenceService.saveContext()
//    }
    
    /**
     Adds a new insulin log to core data
     - parameter units: Double, Insulin units injected
     - parameter time: String, Time of insulin injection
     - parameter date: Date, Date of insulin injected
     - note: Posts a notification "InsulinAdded" which is picked up by viewControllerGraph to update views
     */
    func addInsulin(units: Double, time: Date, date: Date){
        
        let currentDay = findOrMakeDay(day: date)
        let newInsulin = Insulin(context: PersistenceService.context)
        newInsulin.units = units
        newInsulin.time = time
        currentDay.addToInsulin(newInsulin)
        PersistenceService.saveContext()
        
        let nc = NotificationCenter.default
        nc.post(name: Notification.Name("InsulinAdded"), object: nil)
    }
    
    /**
     Toggles whether a meal is favourited in core data
     - parameter item: Meals, Meals object to toggle
     */
    func toggleFavouriteFood(item: Meals){
        
        let favList = checkForExistingFavourites()
        var found = false
        for index in favList.objectIDs(forRelationshipNamed: "meals"){
            if index == item.objectID{
                favList.removeFromMeals(item)
                found = true
            }
        }
        if found == false{
            favList.addToMeals(item)
        }
        PersistenceService.saveContext()
    }
    
    /**
     Toggles whether an exercise is favourited in core data
     - parameter item: Exercise, Exercise object to toggle
     */
    func toggleFavouriteExercise(item: Exercise){
        
        let favList = checkForExistingFavourites()
        var found = false
        for index in favList.objectIDs(forRelationshipNamed: "exercise"){
            if index == item.objectID{
                favList.removeFromExercise(item)
                found = true
            }
        }
        if found == false{
            favList.addToExercise(item)
        }
        PersistenceService.saveContext()
        
    }
    
    /**
     Toggles whether a day is favourited in core data
     - parameter item: Day, Day object to toggle
     */
    func toggleFavouriteDay(item: Day){
        
        let favList = checkForExistingFavourites()
        var found = false
        for index in favList.objectIDs(forRelationshipNamed: "days"){
            if index == item.objectID{
                favList.removeFromDays(item)
                found = true
            }
        }
        if found == false{
            favList.addToDays(item)
        }
        PersistenceService.saveContext()
        
    }
    
    /**
     Adds a stress log to core data
     - parameter start: Date, Date containing start time of a stress log
     - parameter end: Date, Date containing end time of a stress log
     */
    func addStress(start: Date, end: Date){
        
        let currentDay = findOrMakeDay(day: start)
        let newStress = Stress(context: PersistenceService.context)
        newStress.start = start
        newStress.end = end
        currentDay.addToStress(newStress)
        PersistenceService.saveContext()
    }
    /**
     Adds an illness log to core data
     - parameter start: Date, Date containing start time of an illness log
     - parameter end: Date, Date containing end time of an illness log
     */
    func addIllness(start: Date, end: Date){
        
        let currentDay = findOrMakeDay(day: start)
        let newIllness = Illness(context: PersistenceService.context)
        newIllness.start = start
        newIllness.end = end
        currentDay.addToIllness(newIllness)
        PersistenceService.saveContext()
    }
    
    //MARK: - Data object getting (fetch/return)

    ///Returns true if item (Meals object) is in favourites
    func itemInFavouritesFood(item: Meals) -> Bool{
        
        let favList = checkForExistingFavourites()
        for index in favList.objectIDs(forRelationshipNamed: "meals"){
            if index == item.objectID{
                return true
            }
        }
        return false
    }
    
    ///Returns true if item (Exercise object) is in favourites
    func itemInFavouritesExercise(item: Exercise) -> Bool{
        
        let favList = checkForExistingFavourites()
        for index in favList.objectIDs(forRelationshipNamed: "exercise"){
            if index == item.objectID{
                return true
            }
        }
        return false
    }
    
    ///Returns true if item (Day object) is in favourites
    func itemInFavouritesDay(item: Day) -> Bool{
        
        let favList = checkForExistingFavourites()
        for index in favList.objectIDs(forRelationshipNamed: "days"){
            if index == item.objectID{
                return true
            }
        }
        return false
    }

    /**
     Fetches an array of Meals objects that are favourited, sorted by name
     - returns: Array of favourited Meals objects sorted by name or an empty array if no favourite Meals exist
    */
    func fetchFavouritesFood() -> [Meals]{
        let fetchRequest: NSFetchRequest<Meals> = Meals.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "favourite != nil")
        //Sorts alphabetically downwards
        let sectionSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let sortDescriptors = [sectionSortDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        let foundMeals = try? PersistenceService.context.fetch(fetchRequest)
        if(foundMeals == nil){
            print("Error fetching meals")
            return []
        }
        else{
            return foundMeals!
        }
    }
    
    /**
     Fetches an array of Exercise objects that are favourited, sorted by name
     - returns: Array of favourited Exercise objects sorted by name or an empty array if no favourite Exercise exist
     */
    func fetchFavouritesExercise() -> [Exercise]{
        let fetchRequest: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "favourite != nil")
        //Sorts alphabetically downwards
        let sectionSortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        let sortDescriptors = [sectionSortDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        let foundExercise = try? PersistenceService.context.fetch(fetchRequest)
        if(foundExercise == nil){
            print("Error fetching exercise")
            return []
        }
        else{
            return foundExercise!
        }
    }
    /**
     Fetches an array of Day objects that are favourited, sorted by date
     - returns: Array of favourited Day objects sorted by date or an empty array if no favourite Day objects exist
     */
    func fetchFavouritesDays() -> [Day]{
        let fetchRequest: NSFetchRequest<Day> = Day.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "favourite != nil")
        //Sorts alphabetically downwards
        let sectionSortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        let sortDescriptors = [sectionSortDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        let foundDays = try? PersistenceService.context.fetch(fetchRequest)
        if(foundDays == nil){
            print("Error fetching days")
            return []
        }
        else{
            return foundDays!
        }
    }
    
    /**
     Fetches an array of Meals objects, sorted by time
     - parameter day: Date, date of day object whose meals are to be fetched
     - returns: Array of Meals objects sorted by time or an empty array if no Meals objects exist
     */
    func fetchMeals(day: Date) -> [Meals]{
        let fetchRequest: NSFetchRequest<Meals> = Meals.fetchRequest()
        let dayToShow = Calendar.current.startOfDay(for: day)
        fetchRequest.predicate = NSPredicate(format: "day.date == %@", dayToShow as CVarArg)
        let sectionSortDescriptor = NSSortDescriptor(key: "time", ascending: true)
        let sortDescriptors = [sectionSortDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        let foundMeals = try? PersistenceService.context.fetch(fetchRequest)
        if(foundMeals == nil){
            print("Error fetching meals")
            return []
        }
        else{
            return foundMeals!
        }
    }
    
    /**
     Fetches an array of Glucose objects, sorted by time
     - parameter day: Date, date of day object whose glucose logs are to be fetched
     - returns: Array of Glucose objects sorted by time or an empty array if no Glucose objects exist
     */
    func fetchGlucose(day: Date) -> [GlucoseMO]{
        let fetchRequest: NSFetchRequest<GlucoseMO> = GlucoseMO.fetchRequest()
        let dayToShow = Calendar.current.startOfDay(for: day)
        fetchRequest.predicate = NSPredicate(format: "day.date == %@", dayToShow as CVarArg)
        //Sorts by short time - currently not correctly
        let sectionSortDescriptor = NSSortDescriptor(key: "time", ascending: true)
        let sortDescriptors = [sectionSortDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        let foundGlucose = try? PersistenceService.context.fetch(fetchRequest)

        if(foundGlucose == nil){
            print("Error fetching glucose")
            return []
        }
        else{
            return foundGlucose!
        }
    }
    
    /**
     Fetches an array of Insulin objects, sorted by time
     - parameter day: Date, date of day object whose insulin logs are to be fetched
     - returns: Array of Insulin objects sorted by time or an empty array if no Insulin objects exist
     */
    func fetchInsulin(day: Date) -> [Insulin]{
        let fetchRequest: NSFetchRequest<Insulin> = Insulin.fetchRequest()
        let dayToShow = Calendar.current.startOfDay(for: day)
        fetchRequest.predicate = NSPredicate(format: "day.date == %@", dayToShow as CVarArg)
        let sectionSortDescriptor = NSSortDescriptor(key: "time", ascending: true)
        let sortDescriptors = [sectionSortDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        let foundInsulin = try? PersistenceService.context.fetch(fetchRequest)
        if(foundInsulin == nil){
            print("Error fetching insulin")
            return []
        }
        else{
            return foundInsulin!
        }
    }
    
    /**
     Fetches an array of Exercise objects, sorted by time
     - parameter day: Date, date of day object whose exercise logs are to be fetched
     - returns: Array of Exercise  objects sorted by time or an empty array if no Exercise objects exist
     */
    func fetchExercise(day: Date) -> [Exercise]{
        let fetchRequest: NSFetchRequest<Exercise> = Exercise.fetchRequest()
        let dayToShow = Calendar.current.startOfDay(for: day)
        fetchRequest.predicate = NSPredicate(format: "day.date == %@", dayToShow as CVarArg)
        let sectionSortDescriptor = NSSortDescriptor(key: "time", ascending: true)
        let sortDescriptors = [sectionSortDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        let foundExercise = try? PersistenceService.context.fetch(fetchRequest)
        if(foundExercise == nil){
            print("Error fetching exercise")
            return []
        }
        else{
            return foundExercise!
        }
    }
    

    /**
     Fetches an array of Day objects, sorted by date
     - returns: Array of Day objects sorted by date or an empty array if no Day objects exist
     - note: Currently fetches ALL days, then filters in ViewControllerHealth to last 7/30/60. This is due to Day.date being a "string" not a Date, and therefore not being filterable using a fetch predicate. Ideally this would be refactored for efficiency when many Days are stored, but even within several years, it is unlikely to have much effect on performance.
     */
    func fetchDay() -> [Day]{
        let fetchRequest: NSFetchRequest<Day> = Day.fetchRequest()
        let sectionSortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        let sortDescriptors = [sectionSortDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        let foundDay = try? PersistenceService.context.fetch(fetchRequest)
        
        if(foundDay == nil){
            print("Error fetching day")
            return[]
        }
        else{
            return foundDay!
        }
    }

}

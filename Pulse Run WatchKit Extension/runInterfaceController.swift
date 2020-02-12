//
//  runInterfaceController.swift
//  Pulse Run WatchKit Extension
//
//  Created by Umut Ozdemir on 29.12.19.
//  Copyright © 2019 Umut Ozdemir. All rights reserved.
//

import WatchKit
import Foundation
import YOChartImageKit
import HealthKit


class runInterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {
    
    // variables for drawer
    var lastHeartRate = 0.0
    
    // variables for average bpm calculation
    var lastHeartRateListAVG = [Double]()
    
    var HMax = 999
    
    let healthStore = HKHealthStore()
    var workoutSession: HKWorkoutSession?
    
    //State of the app - is the workout activated
    var workoutActive = false
    
    var workoutPaused = false
    
    // define the activity types
    var totalEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 0)
    var totalDistance = HKQuantity(unit: HKUnit.meter(), doubleValue: 0)
    var totalstepsCount = HKQuantity(unit: HKUnit.count(), doubleValue: 0)
    var currenQuery : HKQuery?
    let countPerMinuteUnit = HKUnit(from: "count/min")
    
    var theTimer = Timer()
    var backgroundTimer = TimeInterval(20)
    
    var modeString = "None"
    var bpm_status = "perfect"
    
    // init User Data struct
    struct userDataStruct:Codable {
        var Hmax: Int
        var sex: String
        var age: Int
        var distance_type: String
        var stats_date: Array<Date>
        var stats_avg_bpm: Array<Int>
        var stats_distance: Array<Double>
        var stats_calories: Array<Double>
        var stats_steps: Array<Int>
        var mode: Array<String>
    }
    
    var distanceMode = "None"
    
    // inital variables for stats after run is finished
    var stats_avg_bpm = [000]
    var stats_distance = [00.0]
    var stats_calories = [00.0]
    var stats_steps = [000]
    
     var workoutIsActive = true
     var workoutStartDate = Date()
     var workoutEndDate = Date()
     var activeDataQueries = [HKQuery]()
    
    
    // feedback timer
    var feedbackTimer : Timer?
    var feedbackTimerCounter = 0
    
    
    
    
    @IBOutlet var button: WKInterfaceButton!
    @IBOutlet var HMaxMinLabel: WKInterfaceLabel!
    @IBOutlet var HMaxMaxLabel: WKInterfaceLabel!
    @IBOutlet var BPMLabel: WKInterfaceLabel!
    

   
    @IBOutlet var feedbackGroup: WKInterfaceGroup!
    @IBOutlet var Arrow: WKInterfaceImage!
    @IBOutlet var calibratingLabel: WKInterfaceLabel!
    @IBOutlet var speedUpLabel: WKInterfaceLabel!
    @IBOutlet var distanceLabel: WKInterfaceLabel!
    @IBOutlet var caloriesLabel: WKInterfaceLabel!
    @IBOutlet var stepLabel: WKInterfaceLabel!
    @IBOutlet var pauseButton: WKInterfaceButton!
    
    

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        print("hey im in in run view")
        
        let mode = context as? String
        if let m = mode {
            print(m)
            modeString = m
        }
        
        
        // set calibrating Label
        calibratingLabel.setText("calibrating ...")
        
        
        // if no permission set calibrating text to "grant permissions"
        guard HKHealthStore.isHealthDataAvailable() == true else {
            calibratingLabel.setText("grant permissions")
            return
        }
    
        
        let dataTypes: Set<HKSampleType> = [
            HKSampleType.quantityType(forIdentifier: .heartRate)!,
            HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKSampleType.quantityType(forIdentifier: .stepCount)!
        ]
        

        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) -> Void in
            if success == false {
                self.calibratingLabel.setText("grant permissions")
            }
            if success == true {
                self.startWorkout()
            }
        }
        
        // get user HMax Value
        let data = getUserData()
        HMax = data.Hmax
        distanceMode = data.distance_type
        
        // set min and max HMax Labels
        set_min_max_label(mode: modeString)
        
        startFeedbackTimer()
        
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        button.setHidden(false)
        pauseButton.setHidden(false)
    }

    
    override func willDisappear() {
        //finish the current workout
         self.workoutIsActive = false
        
         guard let workoutSession = workoutSession else { return }
         workoutEndDate = Date()

         healthStore.end(workoutSession)
        
         self.theTimer.invalidate()
         self.calibratingLabel.setHidden(false)
         self.calibratingLabel.setText("finishing training ...")
         feedbackGroup.setHidden(true)
    }
    
    
    //feeback timer
    
    func showFeedbackTimerStatus() {
        feedbackGroup.setHidden(false)
        calibratingLabel.setText("feedback in \(60-feedbackTimerCounter) s")
        if feedbackTimerCounter > 60 {
            killFeedbackTimer()
            calibratingLabel.setHidden(false)
            calibratingLabel.setText(" ")
        }
    }
    
    func startFeedbackTimer() {
        feedbackTimer = Timer.scheduledTimer(timeInterval:1, target:self, selector:#selector(processFeedbackTimer), userInfo: nil, repeats: true)
    }
    
    func killFeedbackTimer() {
       feedbackTimer?.invalidate()
       feedbackTimer = nil
    }

    @objc func processFeedbackTimer() {
        feedbackTimerCounter += 1
        //print("This is a second ", feedbackTimerCounter)
        showFeedbackTimerStatus()

    }
    
    func setUserData(userData: userDataStruct) {
                
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(userData) {
            let defaults = UserDefaults.standard
            defaults.set(encoded, forKey: "shared_default")
        }
    }
    
    
    func getUserData() -> userDataStruct {
        
        // init User Defaults
        let defaults = UserDefaults.standard
        
        let date = Date()
        // init User Data - any random default values just relevant that line 185 doesn't gives error. These values will not be saved
        let userData = userDataStruct (Hmax: 0, sex: "Female", age: 25, distance_type: "Miles", stats_date: [date,date,date],  stats_avg_bpm: [000,000,000], stats_distance: [00.0,00.0,00.0], stats_calories: [00.0,00.0,00.0], stats_steps: [000,000,000],mode:["mode","mode","mode"])
        
        var data = userData
        
        if let savedUserData = defaults.object(forKey: "shared_default") as? Data {
            let decoder = JSONDecoder()
            if let loadedUserData = try? decoder.decode(userDataStruct.self, from: savedUserData) {
                print(loadedUserData.Hmax)

                data =  loadedUserData
            }
        }
        return data
    }

    
    func feedback_logic() {
        
        // get bpm status
        bpm_status = bpm_checker(mode: modeString, lastHeartRate: lastHeartRate, HMax: HMax)
        
        
        // set BPMGraph color
        var color = UIColor(named: "blue")
        if bpm_status != "perfect" {
            // red color
            color = UIColor(red: 0.698, green: 0, blue: 0, alpha: 0.3)
        }
        
        // function to draw the line chart
        
        if workoutIsActive == false {
            feedbackGroup.setHidden(true)
        }

        
        // get correct user feedback
        userFeedback(bpm_status: bpm_status)
        
    }
    
    

    
    func startWorkout() {
        
        // set active workout
        workoutIsActive = true
        //red
        pauseButton.setBackgroundColor(UIColor(red:0.93, green:0.04, blue:0.33, alpha:1.0))
        
        // Configure the workout session.
        let config = HKWorkoutConfiguration()
        config.activityType = .running
        config.locationType = .outdoor

        
        if let session = try? HKWorkoutSession(configuration: config) {
            workoutSession = session
            healthStore.start(session)
            workoutStartDate = Date()
            session.delegate = self
        }
    }
    
    func startQueries() {
        startQuery(quantityTypeIdentifier: .distanceWalkingRunning)
        startQuery(quantityTypeIdentifier: .activeEnergyBurned)
        startQuery(quantityTypeIdentifier: .heartRate)
        startQuery(quantityTypeIdentifier: .stepCount)
    }
    
    func startQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) {
        let datePredicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: .strictStartDate)
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let queryPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [datePredicate, devicePredicate])

        let updateHandler = { (query: HKAnchoredObjectQuery, samples: [HKSample]?, deletedObjects: [HKDeletedObject]?, queryAnchor: HKQueryAnchor?, error: Error?) in
            guard let samples = samples as? [HKQuantitySample] else { return }
            self.process(samples, type: quantityTypeIdentifier)
        }

        let query = HKAnchoredObjectQuery(type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!, predicate: queryPredicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: updateHandler)
        query.updateHandler = updateHandler
        healthStore.execute(query)

        activeDataQueries.append(query)
    }
    
    
    func process(_ samples: [HKQuantitySample], type: HKQuantityTypeIdentifier) {
        // ignore updates while we are paused
        guard workoutIsActive else { return }

        for sample in samples {
            
            if type == .activeEnergyBurned {
                let newEnergy = sample.quantity.doubleValue(for: HKUnit.kilocalorie())
                let currentEnergy = totalEnergyBurned.doubleValue(for: HKUnit.kilocalorie())
                totalEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: currentEnergy + newEnergy)
                print("Total energy: \(totalEnergyBurned)")
                
            } else if type == .heartRate {
                lastHeartRate = sample.quantity.doubleValue(for: countPerMinuteUnit)
                print("Last heart rate: \(lastHeartRate)")
                
                if self.lastHeartRate > 0.0 {
                    self.lastHeartRateListAVG.append(self.lastHeartRate)
                }
                
                print("AVG list, \(lastHeartRateListAVG)")
                
            } else if type == .distanceWalkingRunning {
                let newDistance = sample.quantity.doubleValue(for: HKUnit.meter())
                let currentDistance = totalDistance.doubleValue(for: HKUnit.meter())
                totalDistance = HKQuantity(unit: HKUnit.meter(), doubleValue: currentDistance + newDistance)
                print("Total distance: \(totalDistance)")
                
            } else if type == .stepCount {
                let newSteps = sample.quantity.doubleValue(for: HKUnit.count())
                let currentSteps = totalstepsCount.doubleValue(for: HKUnit.count())
                totalstepsCount = HKQuantity(unit: HKUnit.count(), doubleValue: currentSteps + newSteps)
                print("Total steps: \(totalstepsCount)")
            }
        }
        updateLabels()
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            if fromState == .notStarted {
                startQueries()

            } else {
                workoutIsActive = true
            }

        case .paused:
            workoutIsActive = false

        case .ended:
            workoutIsActive = false

            // appear save HMax button
            // appleTimer.setHidden(true)
            
            // reset Hear Rate variables
            lastHeartRate = 0.0
            
            var data = getUserData()
            
            // set stats_date
            let today = Date()
            data.stats_date.removeFirst()
            data.stats_date.append(today)
            
            // set average BPM
            if (lastHeartRateListAVG.count > 0 ) {
                print("avg list, \(lastHeartRateListAVG)")
                let sumArray = lastHeartRateListAVG.reduce(0, +)
                let avgBPM = Int(sumArray) / lastHeartRateListAVG.count
                data.stats_avg_bpm.removeFirst()
                data.stats_avg_bpm.append(avgBPM)
            }
            
            // set distance
            data.stats_distance.removeFirst()
            data.stats_distance.append(stats_distance[0])
            
            // set calories
            data.stats_calories.removeFirst()
            data.stats_calories.append(stats_calories[0])
            
            // set steps
            data.stats_steps.removeFirst()
            data.stats_steps.append(stats_steps[0])
            
            //set mode
            data.mode.removeFirst()
            data.mode.append(modeString)
            
            print(data)
            
            setUserData(userData: data)
            
            cleanUpQueries()
//            save(workoutSession)
            
            


        default:
            break
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
    }

    func cleanUpQueries() {
        for query in activeDataQueries {
            healthStore.stop(query)
        }

        activeDataQueries.removeAll()
        self.popToRootController()
    }

//    func save(_ workoutSession: HKWorkoutSession) {
//        let config = workoutSession.workoutConfiguration
//        let workout = HKWorkout(activityType: config.activityType, start: workoutStartDate, end: workoutEndDate, workoutEvents: nil, totalEnergyBurned: totalEnergyBurned, totalDistance: totalDistance, metadata: [HKMetadataKeyIndoorWorkout: false])
//
//        healthStore.save(workout) { (success, error) in
//            if success {
//                DispatchQueue.main.async {
//                    WKInterfaceController.reloadRootPageControllers(withNames: ["InterfaceController"], contexts: nil, orientation: .horizontal, pageIndex: 0)
//                }
//            }
//        }
//    }
    
    func updateLabels() {
        
        
        // Distance in Kilometers
        let meters = totalDistance.doubleValue(for: HKUnit.meter())
        let kilometers = meters / 1000
        let miles = kilometers / 1.61
        
        if distanceMode == "Miles" {
            let formattedDistance = String(format: "%.1f", miles)
            distanceLabel.setText(formattedDistance)
            stats_distance.removeFirst()
            stats_distance.append(miles)
        } else {
            let formattedDistance = String(format: "%.1f", kilometers)
            distanceLabel.setText(formattedDistance)
            stats_distance.removeFirst()
            stats_distance.append(kilometers)
        }
        
        
        
        // Kilocalories
        let kilocalories = totalEnergyBurned.doubleValue(for: HKUnit.kilocalorie())
        let formatterKilocalories = String(format: "%.0f", kilocalories)
        caloriesLabel.setText(formatterKilocalories)
        stats_calories.removeFirst()
        stats_calories.append(kilocalories)
        
        //Heart Rate
        let heartRate = String(Int(lastHeartRate))
        BPMLabel.setText(heartRate)
        
        // Steps Count
        let steps = totalstepsCount.doubleValue(for: HKUnit.count())
        let count = HKUnit(from: "count")
        let int_steps = Int(steps)
        stepLabel.setText(String(String(int_steps)))
        stats_steps.removeFirst()
        stats_steps.append(int_steps)


        self.feedback_logic()

            
    }
    
    func userFeedback(bpm_status: String) {
        
        let odd_even = lastHeartRateListAVG.count % 2
        //print("the odd even value is \(odd_even)")
        
        if feedbackTimerCounter > 60 {
             if bpm_status == "perfect" {
                speedUpLabel.setHidden(false)
                speedUpLabel.setTextColor(UIColor.white)
                speedUpLabel.setText("perfect")
                Arrow.setImage(UIImage(systemName: "smiley"))
                Arrow.setTintColor(UIColor.white)
            }
        }

        // only trigger if odd_even is 1. This halfs the amount of feedback
        if odd_even == 1 && feedbackTimerCounter > 60 {
            if bpm_status == "slow_down" {
                speedUpLabel.setHidden(false)
                speedUpLabel.setText("slow down")
                // green
                speedUpLabel.setTextColor(UIColor(red:0.01, green:0.56, blue:0.00, alpha:1.0))
                Arrow.setImage(UIImage(systemName: "arrow.down"))
                Arrow.setTintColor(UIColor(red:0.01, green:0.56, blue:0.00, alpha:1.0))
                WKInterfaceDevice.current().play(.stop)
            }
            
            if bpm_status == "speed_up" {
                speedUpLabel.setHidden(false)
                speedUpLabel.setText("speed up")
                // red
                speedUpLabel.setTextColor(UIColor(red:0.93, green:0.04, blue:0.33, alpha:1.0))
                Arrow.setImage(UIImage(systemName: "arrow.up"))
                Arrow.setTintColor(UIColor(red:0.93, green:0.04, blue:0.33, alpha:1.0))
                WKInterfaceDevice.current().play(.retry)
            }
        }

        
    }
    
    func set_min_max_label(mode: String) {
        var min_HMax = 0.0
        var max_HMax = 0.0
        
        var calc_min = 0.0
        var calc_max = 0.0
        
        switch modeString {
        case "long":
            min_HMax = 0.7
            max_HMax = 0.8
            calc_min = Double(HMax) * min_HMax
            calc_max = Double(HMax) * max_HMax
            HMaxMinLabel.setText(String(Int(calc_min)))
            HMaxMaxLabel.setText(String(Int(calc_max)))
        
        case "mid":
            min_HMax = 0.8
            max_HMax = 0.9
            calc_min = Double(HMax) * min_HMax
            calc_max = Double(HMax) * max_HMax
            HMaxMinLabel.setText(String(Int(calc_min)))
            HMaxMaxLabel.setText(String(Int(calc_max)))
            
        case "fast":
            min_HMax = 0.9
            max_HMax =  1.0
            calc_min = Double(HMax) * min_HMax
            calc_max = Double(HMax) * max_HMax
            HMaxMinLabel.setText(String(Int(calc_min)))
            HMaxMaxLabel.setText(String(Int(calc_max)))
            
        default:
            HMaxMinLabel.setText("---")
            HMaxMaxLabel.setText("---")
        }
    }
    
    func bpm_checker(mode: String, lastHeartRate: Double, HMax: Int) -> String {
        
        var min_HMax = 0.0
        var max_HMax = 0.0
        
        var calc_min = 0.0
        var calc_max = 0.0
        
        switch modeString {
        case "long":
            min_HMax = 0.7
            max_HMax = 0.8
            calc_min = Double(HMax) * min_HMax
            calc_max = Double(HMax) * max_HMax
        
        case "mid":
            min_HMax = 0.8
            max_HMax = 0.9
            calc_min = Double(HMax) * min_HMax
            calc_max = Double(HMax) * max_HMax
            
        case "fast":
            min_HMax = 0.9
            max_HMax =  1.0
            calc_min = Double(HMax) * min_HMax
            calc_max = Double(HMax) * max_HMax
            
        default:
            min_HMax = 0.8
            max_HMax = 0.9
        }
        
//        print("\(modeString), \(min_HMax), \(max_HMax)")
        

        if (calc_min ... calc_max ~= lastHeartRate)  {
            bpm_status = "perfect"
        }
        if lastHeartRate > calc_max {
            bpm_status = "slow_down"
        }
        if lastHeartRate < calc_min {
            bpm_status = "speed_up"
        }
        
        //print("\(calc_min), \(lastHeartRate), \(calc_max), \(bpm_status)")
        return bpm_status

    }
    
    
    @IBAction func buttonTapped() {
    
        //finish the current workout
         killFeedbackTimer()
         self.workoutIsActive = false
        
         guard let workoutSession = workoutSession else { return }
         workoutEndDate = Date()

         healthStore.end(workoutSession)
        
         self.theTimer.invalidate()
         self.calibratingLabel.setHidden(false)
         self.calibratingLabel.setText("finishing training ...")
         feedbackGroup.setHidden(true)
         button.setHidden(true)
         pauseButton.setHidden(true)
        
    
    }
    
    @IBAction func pauseButtonTapped() {

        if workoutPaused == false {
            workoutPaused = true
            killFeedbackTimer()
            healthStore.pause(workoutSession!)

            pauseButton.setTitle("resume")
            pauseButton.setBackgroundColor(UIColor(red:0.01, green:0.56, blue:0.00, alpha:1.0))
        } else {
            workoutPaused = false
            healthStore.resumeWorkoutSession(workoutSession!)
            startFeedbackTimer()
            pauseButton.setTitle("pause")
            //red
            pauseButton.setBackgroundColor(UIColor(red:0.93, green:0.04, blue:0.33, alpha:1.0))
        }
    }
    
    
    
}

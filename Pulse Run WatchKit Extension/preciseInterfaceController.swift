//
//  preciseInterfaceController.swift
//  Pulse Run WatchKit Extension
//
//  Created by Umut Ozdemir on 21.12.19.
//  Copyright © 2019 Umut Ozdemir. All rights reserved.
//

import WatchKit
import Foundation
import YOChartImageKit
import HealthKit
import UserNotifications

class preciseInterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {
    

    
    var lastHeartRateList: [Double] = [0.0,0.0]
    var lastHeartRate = 0.0
    
    let healthStore = HKHealthStore()
    
    //State of the app - is the workout activated
    var workoutActive = false
    
    // define the activity type and location
    var session : HKWorkoutSession?
    let heartRateUnit = HKUnit(from: "count/min")
    var currenQuery : HKQuery?
    
    var theTimer = Timer()
    var backgroundTimer = TimeInterval(110)
    
    
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
    
    // notfication center
    let center = UNUserNotificationCenter.current()
    
    
    
    @IBOutlet var HMaxLabel: WKInterfaceLabel!
    @IBOutlet var BPMLabel: WKInterfaceLabel!
    @IBOutlet var startButton: WKInterfaceButton!
    @IBOutlet var BPMGraph: WKInterfaceImage!
    @IBOutlet var calibratingLabel: WKInterfaceLabel!
    @IBOutlet var appleTimer: WKInterfaceTimer!
    @IBOutlet var BPMGroup: WKInterfaceGroup!
    @IBOutlet var saveHMaxButton: WKInterfaceButton!
    @IBOutlet var backButton: WKInterfaceButton!
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        // request notification permission
         center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
             if granted {
                 print("Yay!")

             } else {
                 print("D'oh")
             }
         }
        
        // initially hide Graph Group
        BPMGroup.setHidden(true)
        
        // set calibrating Label
        calibratingLabel.setText("press start and run as fast as you can for 110 seconds")
        
        // if no permission set calibrating text to "grant permissions"
        guard HKHealthStore.isHealthDataAvailable() == true else {
            calibratingLabel.setText("grant permissions")
            return
        }
    
        // set quantityType for Heart Rate
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            self.calibratingLabel.setText("grant permissions")
            return
        }
        
        let dataTypes = Set(arrayLiteral: quantityType)
        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) -> Void in
            if success == false {
                self.calibratingLabel.setText("grant permissions")
            }
        }
        
        // set HMax label with current HMax value
        let data = getUserData()
        HMaxLabel.setText(String(data.Hmax))
        
    }

    override func didDeactivate() {
       super.didDeactivate()
    }
    


    func drawer() {
        
        // function to draw the line chart

        let frame = CGRect(x: 0, y: 0, width: contentFrame.width, height: contentFrame.height)
        let image2 = YOLineChartImage()
        image2.strokeWidth = 3.0              // width of line
        image2.fillColor = UIColor(red: 0.698, green: 0, blue: 0, alpha: 0.3)
        image2.strokeColor = UIColor(red: 0.698, green: 0, blue: 0, alpha: 1)    // color of line
        image2.smooth = true                 // disable smooth line
        image2.values = lastHeartRateList as [NSNumber]
        
        let chart2 = image2.draw(frame, scale: WKInterfaceDevice.current().screenScale)
        
        if workoutActive == false {
            BPMGroup.setHidden(true)
            BPMGraph.setHidden(true)
        }else {
            calibratingLabel.setHidden(true)
        }
        
        self.BPMGraph.setImage(chart2)

    }
    

    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            workoutDidStart(date)
        case .ended:
            workoutDidEnd(date)
        default:
            print("Unexpected state \(toState)")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        // Do nothing for now
        print("Workout error")
    }
    
    func workoutDidStart(_ date : Date) {
        if let query = createHeartRateStreamingQuery(date) {
            self.currenQuery = query
            healthStore.execute(query)
            
            
        } else {
            calibratingLabel.setText("cannot start")
        }
    }
    
    
    func workoutDidEnd(_ date : Date) {
        
        
        healthStore.stop(self.currenQuery!)
        session = nil
                
        // set HMax Label
        let HMaxValue = lastHeartRateList.max()
        
        // appear save HMax button
        appleTimer.setHidden(true)
        
        // check if any BPM was created
        if lastHeartRate > 0.0 {
            self.HMaxLabel.setText(String(Int(HMaxValue!)))
            startButton.setHidden(true)
            saveHMaxButton.setHidden(false)
            self.calibratingLabel.setText("calculation finished")
        } else {
            
            self.calibratingLabel.setText("press start and run as fast as you can for 110 seconds")
            self.startButton.setHidden(false)
            self.startButton.setBackgroundColor(UIColor(red:0.36, green:0.53, blue:0.85, alpha:1.0))
            self.startButton.setTitle("start")
            self.backButton.setHidden(false)
        }
        
        
        // get User Defaults
        var data = getUserData()
        
        // set new HMax Value
        data.Hmax = Int(HMaxValue!)
        
        // write users HMax if it is greater than 0
        if (Int(HMaxValue!) > 0) {
            setUserData(userData: data)
        }
        
        // reset Hear Rate variables
        lastHeartRateList = [0.0,0.0]
        lastHeartRate = 0.0
        
    }

    
    func startWorkout() {
        
        // If we have already started the workout, then do nothing.
        if (session != nil) {
            return
        }
        
        // Configure the workout session.
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .running
        workoutConfiguration.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(configuration: workoutConfiguration)
            session?.delegate = self
        } catch {
            fatalError("Unable to create the workout session!")
        }
        
        healthStore.start(self.session!)
    }
    
    func createHeartRateStreamingQuery(_ workoutStartDate: Date) -> HKQuery? {

        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else { return nil }
        let datePredicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: .strictEndDate )
        //let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate])
        
        
        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            //guard let newAnchor = newAnchor else {return}
            //self.anchor = newAnchor
            self.updateHeartRate(sampleObjects)
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            //self.anchor = newAnchor!
            self.updateHeartRate(samples)
        }
        return heartRateQuery
    }
    
    func updateHeartRate(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {return}
        
        
            guard let sample = heartRateSamples.first else{return}
            let value = sample.quantity.doubleValue(for: self.heartRateUnit)
            self.BPMLabel.setText(String(UInt16(value)))
            print("bpm is \(value)")
            
            // retrieve source from sample
            let name = sample.sourceRevision.source.name
            
            self.lastHeartRate = value
            self.lastHeartRateList.append(self.lastHeartRate)
            self.drawer()
        
        
    }
    
    func timer() {
        appleTimer.setHidden(false)
        // call the timer
        theTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerCountDown), userInfo: nil, repeats: true)
        
    }
    

    @objc fileprivate func timerCountDown() {
        
        backgroundTimer -= 1.0
        print(backgroundTimer)
        
        if backgroundTimer == 0 {
            
            self.BPMGroup.setHidden(true)
            self.BPMGraph.setHidden(true)
            self.startButton.setHidden(true)
            self.appleTimer.setHidden(true)
            self.backgroundTimer = TimeInterval(110)
            self.calibratingLabel.setHidden(false)
            
            print("timer finished")
            
            // inform user that calculation is finished
            WKInterfaceDevice.current().play(.success)
            scheduleNotification()
            
            
            theTimer.invalidate()
            appleTimer.stop()
            self.workoutActive = false
            self.startButton.setTitle("start")
            if let workout = self.session {
                healthStore.end(workout)
            }
            
            

        }
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
        // init User Data - any random default values just relevant that line 347 doesn't gives error. These values will not be saved
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
    
    
    @IBAction func startButtonTapped() {
        if (self.workoutActive) {
            //finish the current workout
            self.workoutActive = false
            self.startButton.setTitle("start")
            if let workout = self.session {
                healthStore.end(workout)
            }
            self.theTimer.invalidate()
            self.appleTimer.stop()
            backgroundTimer = TimeInterval(110)
            let startTime = Date(timeIntervalSinceNow: 110)
            self.appleTimer.setDate(startTime)
            self.appleTimer.setHidden(true)
            self.calibratingLabel.setHidden(false)
            self.calibratingLabel.setText("calculating HMax please wait up to 15 seconds")
            BPMGroup.setHidden(true)
            BPMGraph.setHidden(true)
            self.startButton.setHidden(true)
            
        } else {
            //start a new workout
            WKInterfaceDevice.current().play(.success)
            self.backButton.setHidden(true)
            BPMGroup.setHidden(false)
            BPMGraph.setHidden(false)
            self.calibratingLabel.setText("calibrating")
            self.workoutActive = true
            self.startButton.setTitle("finish")
            self.startButton.setBackgroundColor(UIColor(red:0.01, green:0.56, blue:0.00, alpha:1.0))
            startWorkout()
            self.appleTimer.setHidden(false)
            let startTime = Date(timeIntervalSinceNow: 110)
            appleTimer.setDate(startTime)
            appleTimer.start()
            self.appleTimer.setHidden(false)
            timer()
            
        }
        
    }
    
    func scheduleNotification() {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = "Training finished"
        content.body = "Good Job! Starting to calculate your HMax."
        content.categoryIdentifier = "alarm"
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        center.add(request)
    }
    
    @IBAction func saveHMaxButtonTapped() {
        
        // return to "choose" controller
        self.pushController(withName: "choose", context: nil)

    }
    
    
    @IBAction func backButtonTapped() {
//        pushController(withName: "choose", context: nil)
        self.pop()
    }
    
    


}

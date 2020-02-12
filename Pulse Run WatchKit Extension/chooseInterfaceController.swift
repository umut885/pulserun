//
//  chooseInterfaceController.swift
//  Pulse Run WatchKit Extension
//
//  Created by Umut Ozdemir on 20.12.19.
//  Copyright © 2019 Umut Ozdemir. All rights reserved.
//

import WatchKit
import Foundation


class chooseInterfaceController: WKInterfaceController {
    
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
    
    // mode variable
    var mode = "none"
    
    var HMax = 0
    
    var longRunSwitchBool = false
    var midRunSwitchBool = false
    var fastRunSwitchBool =  false

    @IBOutlet var longRunSwitch: WKInterfaceSwitch!
    @IBOutlet var midRunSwitch: WKInterfaceSwitch!
    @IBOutlet var fastRunSwitch: WKInterfaceSwitch!
    @IBOutlet var startButton: WKInterfaceButton!
    @IBOutlet var homeButton: WKInterfaceButton!
    
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // set HMax of User from User Data
        let data = getUserData()
        HMax = data.Hmax
        
        print("choose: awake data is \(data)")

    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        longRunSwitch.setOn(false)
        midRunSwitch.setOn(false)
        fastRunSwitch.setOn(false)

    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
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
        // init User Data - any random default values just relevant that line 92 doesn't gives error. These values will not be saved
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
    
    
    @IBAction func longRunSwitchTapped(_ value: Bool) {
        mode = "long"
        midRunSwitch.setOn(false)
        midRunSwitchBool = false
        fastRunSwitch.setOn(false)
        fastRunSwitchBool = false
        
        longRunSwitchBool = value
        
        if longRunSwitchBool == false && midRunSwitchBool == false && fastRunSwitchBool == false {
            startButton.setEnabled(false)
            startButton.setBackgroundColor(UIColor.lightGray)
        } else {
            if (HMax == 0) {
                longRunSwitch.setOn(false)
                longRunSwitchBool = false
                pushController(withName: "noHMax", context: nil)
            }else {
                startButton.setEnabled(true)
                //blue
                startButton.setBackgroundColor(UIColor(red:0.36, green:0.53, blue:0.85, alpha:1.0))
                longRunSwitchBool = true
            }
        }

    }
    
    @IBAction func midRunSwitchTapped(_ value: Bool) {
        mode = "mid"
        longRunSwitch.setOn(false)
        longRunSwitchBool = false
        fastRunSwitch.setOn(false)
        fastRunSwitchBool = false
        
        midRunSwitchBool = value
        
        if longRunSwitchBool == false && midRunSwitchBool == false && fastRunSwitchBool == false {
            startButton.setEnabled(false)
            startButton.setBackgroundColor(UIColor.lightGray)
        } else {
            
            if (HMax == 0) {
                midRunSwitch.setOn(false)
                midRunSwitchBool = false
                pushController(withName: "noHMax", context: nil)
            }else {
                startButton.setEnabled(true)
                //blue
                startButton.setBackgroundColor(UIColor(red:0.36, green:0.53, blue:0.85, alpha:1.0))
                midRunSwitchBool = true
            }
        }

    }
    
    @IBAction func fastRunSwitchTapped(_ value: Bool) {
        mode = "fast"
        longRunSwitch.setOn(false)
        longRunSwitchBool = false
        midRunSwitch.setOn(false)
        midRunSwitchBool = false
        
        fastRunSwitchBool = value
        
        if longRunSwitchBool == false && midRunSwitchBool == false && fastRunSwitchBool == false {
            startButton.setEnabled(false)
            startButton.setBackgroundColor(UIColor.lightGray)
        } else {
            
            if (HMax == 0) {
                fastRunSwitch.setOn(false)
                fastRunSwitchBool = false
                pushController(withName: "noHMax", context: nil)
            } else {
                startButton.setEnabled(true)
                //blue
                startButton.setBackgroundColor(UIColor(red:0.36, green:0.53, blue:0.85, alpha:1.0))
                fastRunSwitchBool = true
            }
        }
        
    
    }
    
    // pass data to seque
    override func contextForSegue(withIdentifier segueIdentifier: String) -> Any? {
        return mode
    }
    
    @IBAction func startButtonTapped() {

    }
    
    @IBAction func homeButtonTapped() {
        self.popToRootController()
    }
    
    
    
}

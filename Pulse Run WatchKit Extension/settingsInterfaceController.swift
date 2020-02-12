//
//  settingsInterfaceController.swift
//  Pulse Run WatchKit Extension
//
//  Created by Umut Ozdemir on 30.12.19.
//  Copyright © 2019 Umut Ozdemir. All rights reserved.
//

import WatchKit
import Foundation


class settingsInterfaceController: WKInterfaceController {
    
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
    
    let distance_list: [String] = ["Miles", "Kilometers"]

    
    var selected_distance = "Miles"
    
    var HMax = 999

    @IBOutlet var HMaxLabel: WKInterfaceLabel!
    @IBOutlet var setHMaxButton: WKInterfaceButton!
    @IBOutlet var distanceButton: WKInterfaceButton!
    

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        
        // init User data
        let data = getUserData()
        
        // check if Hmax was ever set, if not set show set button
        if (data.Hmax == 0) {
            HMaxLabel.setText(String("---"))
            HMax = data.Hmax
        } else {
            HMaxLabel.setHidden(false)
            HMaxLabel.setText(String(data.Hmax))
            HMax = data.Hmax
        }
        
        // set distance by User Data
        
        distanceButton.setTitle(String(data.distance_type))
        
        print("settings: awake was \(data)")
        

    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
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
        // init User Data - any random default values just relevant that line 97 doesn't gives error. These values will not be saved
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
    
    
    func saveDistance() {
    
        var data = getUserData()
        data.distance_type = selected_distance
      
        // save data
        setUserData(userData: data)
        
        print("save: saved was \(data)")
    }
    
    @IBAction func setHMaxButtonTapped() {
        pushController(withName: "setHMax", context: nil)
    }
    @IBAction func distanceButtonTapped() {
        let data = getUserData()
        if data.distance_type == "Miles" {
            distanceButton.setTitle("Kilometers")
            selected_distance = "Kilometers"
            saveDistance()
        } else {
            distanceButton.setTitle("Miles")
            selected_distance = "Miles"
            saveDistance()
        }
        
    }
    
}

//
//  roughHMaxInterfaceController.swift
//  Pulse Run WatchKit Extension
//
//  Created by Umut Ozdemir on 20.12.19.
//  Copyright © 2019 Umut Ozdemir. All rights reserved.
//

import WatchKit
import Foundation


class roughHMaxInterfaceController: WKInterfaceController {
    
    let sex: [String] = ["Male", "Female", "Divers"]
    var selected_sex = "Female"
    
    
    let age: [Int] = [12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,52,53,54,55,56,57,58,59,60]
    var selected_age = 32
    
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

    // init User Defaults
    let defaults = UserDefaults.standard
    
    
    @IBOutlet var agePicker: WKInterfacePicker!
    @IBOutlet var sexPicker: WKInterfacePicker!
    @IBOutlet var doneButton: WKInterfaceButton!
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        
        // init age Picker
        var age_items = [WKPickerItem]()

        for ag in age {
            let item = WKPickerItem()
            item.title = String(ag)
            age_items.append(item)
        }
        agePicker.setItems(age_items)
        

        // init sex Picker
        var sex_items = [WKPickerItem]()

        for se in sex {
            let sex_item = WKPickerItem()
            sex_item.title = se
            sex_items.append(sex_item)
        }
        sexPicker.setItems(sex_items)
        
    
        // set user data on pickers
        let data = getUserData()
        print("rough data: awake was \(data)")
        
        selected_sex = data.sex
        sexPicker.setSelectedItemIndex(sex.firstIndex(of: data.sex)!)
        
        selected_age = data.age
        agePicker.setSelectedItemIndex(age.firstIndex(of: Int(data.age))!)
        

    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    
    @IBAction func sexPickerChanged(_ value: Int) {
        selected_sex = sex[value]
    }
    
    @IBAction func agePickerChanged(_ value: Int) {
        selected_age = age[value]
    }
    @IBAction func doneButtonTapped() {
        setHMax()
  
    }
    
    
    func setHMax() {
        
        var HMax = 0
        
        if (selected_sex == "Female") {
            HMax = 226
        }
        if (selected_sex == "Male") {
            HMax = 220
        }
        if (selected_sex == "Divers") {
            HMax = 223
        }
        
        var data = getUserData()
        
        data.Hmax = HMax - selected_age
        data.sex = selected_sex
        data.age = selected_age
        
        setUserData(userData: data)
        
        self.pushController(withName: "choose", context: nil)
        
        print("rough: data was set to: \(data)")

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
        // init User Data - any random default values just relevant that line 153 doesn't gives error. These values will not be saved
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
    

}

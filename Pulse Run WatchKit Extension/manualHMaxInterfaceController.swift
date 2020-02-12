//
//  manualHMaxInterfaceController.swift
//  Pulse Run WatchKit Extension
//
//  Created by Umut Ozdemir on 29.12.19.
//  Copyright © 2019 Umut Ozdemir. All rights reserved.
//

import WatchKit
import Foundation


class manualHMaxInterfaceController: WKInterfaceController {
    
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
    
    let hmax: [Int] = [140,141,142,143,144,145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,247,248,249,250]
    
    var selected_hmax = 999
    
    
    @IBOutlet var hmaxPicker: WKInterfacePicker!
    @IBOutlet var saveButton: WKInterfaceButton!
    

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // init hmax Picker
        var hmax_items = [WKPickerItem]()

        for hm in hmax {
            let item = WKPickerItem()
            item.title = String(hm)
            hmax_items.append(item)
        }
        hmaxPicker.setItems(hmax_items)
        
        // set initial selected Hmax value and check if user as ever set it before
        let data = getUserData()
        if data.Hmax > 139 {
            hmaxPicker.setSelectedItemIndex(hmax.firstIndex(of: Int(data.Hmax))!)
        } else {
            hmaxPicker.setSelectedItemIndex(50)
        }
        
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
        // init User Data - any random default values just relevant that line 87doesn't gives error. These values will not be saved
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
    
    @IBAction func hmaxPickerChanged(_ value: Int) {
        
        selected_hmax = hmax[value]
    }
    
    @IBAction func saveButtonTapped() {
        setHMax()
    }
    
    func setHMax() {
    
        var data = getUserData()
        data.Hmax = selected_hmax
        setUserData(userData: data)
        
        self.pushController(withName: "choose", context: nil)
    }
    

}

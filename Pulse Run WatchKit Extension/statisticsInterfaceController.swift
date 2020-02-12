//
//  statisticsInterfaceController.swift
//  Pulse Run WatchKit Extension
//
//  Created by Umut Ozdemir on 04.01.20.
//  Copyright © 2020 Umut Ozdemir. All rights reserved.
//

import WatchKit
import Foundation


class statisticsInterfaceController: WKInterfaceController {
    
    
    @IBOutlet var topLabel: WKInterfaceLabel!
    
    @IBOutlet var dataGroup1: WKInterfaceGroup!
    @IBOutlet var dataGroup2: WKInterfaceGroup!
    @IBOutlet var dataGroup3: WKInterfaceGroup!
    

    @IBOutlet var dateOne: WKInterfaceLabel!
    @IBOutlet var dateTwo: WKInterfaceLabel!
    @IBOutlet var dateThree: WKInterfaceLabel!
    
    @IBOutlet var avgBPMOne: WKInterfaceLabel!
    @IBOutlet var distanceOne: WKInterfaceLabel!
    @IBOutlet var caloriesOne: WKInterfaceLabel!
    @IBOutlet var stepsOne: WKInterfaceLabel!
    
    @IBOutlet var avgBPMTwo: WKInterfaceLabel!
    @IBOutlet var distanceTwo: WKInterfaceLabel!
    @IBOutlet var caloriesTwo: WKInterfaceLabel!
    @IBOutlet var stepsTwo: WKInterfaceLabel!
    
    @IBOutlet var avgBPMThree: WKInterfaceLabel!
    @IBOutlet var distanceThree: WKInterfaceLabel!
    @IBOutlet var caloriesThree: WKInterfaceLabel!
    @IBOutlet var stepsThree: WKInterfaceLabel!
    
    var dataCheckOne = false
    var dataCheckTwo = false
    var dataCheckThree = false
    
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
    


    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        
        let data = getUserData()
        
        print(data)


        // set statistics for first entry
        if data.stats_avg_bpm.reversed()[0] != 0 {
            dateOne.setText(formatter.string(from: data.stats_date.reversed()[0]))
            avgBPMOne.setText(String(data.stats_avg_bpm.reversed()[0]))
            //set date color green
            if String(data.mode.reversed()[0]) == "long" {
                dateOne.setTextColor(UIColor(red:0.01, green:0.56, blue:0.00, alpha:1.0))
            }
            //set date color blue
            if String(data.mode.reversed()[0]) == "mid" {
                dateOne.setTextColor(UIColor(red:0.04, green:0.44, blue:0.92, alpha:1.0))
            }
            // set date color red
            if String(data.mode.reversed()[0]) == "fast" {
                dateOne.setTextColor(UIColor(red:0.92, green:0.11, blue:0.42, alpha:1.0))
            }
            dataCheckOne = true
        } else {
            dataGroup1.setHidden(true)
        }
        
        if data.stats_distance.reversed()[0] != 0.0 {
            let formattedDistance = String(format: "%.1f", data.stats_distance.reversed()[0] )
            distanceOne.setText(formattedDistance)
        }
        
        if data.stats_calories.reversed()[0] != 0.0 {
            let formatterKilocalories = String(format: "%.0f", data.stats_calories.reversed()[0])
            caloriesOne.setText(formatterKilocalories)
        }
        
        if data.stats_steps.reversed()[0] != 0{
            stepsOne.setText(String(data.stats_steps.reversed()[0]))
        }
        
        // set statistics for second entry
        if data.stats_avg_bpm.reversed()[1] != 0 {
            dateTwo.setText(formatter.string(from: data.stats_date.reversed()[1]))
            avgBPMTwo.setText(String(data.stats_avg_bpm.reversed()[1]))
            //set date color green
            if String(data.mode.reversed()[1]) == "long" {
                dateTwo.setTextColor(UIColor(red:0.01, green:0.56, blue:0.00, alpha:1.0))
            }
            //set date color blue
            if String(data.mode.reversed()[1]) == "mid" {
                dateTwo.setTextColor(UIColor(red:0.04, green:0.44, blue:0.92, alpha:1.0))
            }
            // set date color red
            if String(data.mode.reversed()[1]) == "fast" {
                dateTwo.setTextColor(UIColor(red:0.92, green:0.11, blue:0.42, alpha:1.0))
            }
            dataCheckTwo = true
        } else {
            dataGroup2.setHidden(true)
        }
        
        if data.stats_distance.reversed()[1] != 0.0 {
            let formattedDistance = String(format: "%.1f", data.stats_distance.reversed()[1] )
            distanceTwo.setText(formattedDistance)
        }
        
        if data.stats_calories.reversed()[1] != 0.0 {
            let formatterKilocalories = String(format: "%.0f", data.stats_calories.reversed()[1])
            caloriesTwo.setText(formatterKilocalories)
        }
        
        if data.stats_steps.reversed()[1] != 0{
            stepsTwo.setText(String(data.stats_steps.reversed()[1]))
        }
        
        
        // set statistics for third entry
        if data.stats_avg_bpm.reversed()[2] != 0 {
            dateThree.setText(formatter.string(from: data.stats_date.reversed()[2]))
            avgBPMThree.setText(String(data.stats_avg_bpm.reversed()[1]))
            //set date color green
            if String(data.mode.reversed()[2]) == "long" {
                dateThree.setTextColor(UIColor(red:0.01, green:0.56, blue:0.00, alpha:1.0))
            }
            //set date color blue
            if String(data.mode.reversed()[2]) == "mid" {
                dateThree.setTextColor(UIColor(red:0.04, green:0.44, blue:0.92, alpha:1.0))
            }
            // set date color red
            if String(data.mode.reversed()[2]) == "fast" {
                dateThree.setTextColor(UIColor(red:0.92, green:0.11, blue:0.42, alpha:1.0))
            }
            dataCheckThree = true
        } else {
            dataGroup3.setHidden(true)
        }
        
        if data.stats_distance.reversed()[2] != 0.0 {
            let formattedDistance = String(format: "%.1f", data.stats_distance.reversed()[2] )
            distanceThree.setText(formattedDistance)
        }
        
        if data.stats_calories.reversed()[2] != 0.0 {
            let formatterKilocalories = String(format: "%.0f", data.stats_calories.reversed()[2])
            caloriesThree.setText(formatterKilocalories)
        }
        
        if data.stats_steps.reversed()[2] != 0 {
            stepsThree.setText(String(data.stats_steps.reversed()[2]))
        }
        
        // check if used has run at least once
        
        if dataCheckOne == false && dataCheckTwo == false && dataCheckThree == false {
            topLabel.setText("no runs yet")
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
    
    
    func getUserData() -> userDataStruct {
        
        // init User Defaults
        let defaults = UserDefaults.standard
        
        let date = Date()
        // init User Data - any random default values just relevant that line 87doesn't gives error. These values will not be saved
        let userData = userDataStruct (Hmax: 0, sex: "Female", age: 25, distance_type: "Miles", stats_date: [date,date,date],  stats_avg_bpm: [000,000,000], stats_distance: [00.0,00.0,00.0], stats_calories: [00.0,00.0,00.0], stats_steps: [000,000,000] ,mode:["mode","mode","mode"])

        
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

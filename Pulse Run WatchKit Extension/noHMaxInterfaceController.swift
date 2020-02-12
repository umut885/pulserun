//
//  noHMaxInterfaceController.swift
//  Pulse Run WatchKit Extension
//
//  Created by Umut Ozdemir on 29.12.19.
//  Copyright © 2019 Umut Ozdemir. All rights reserved.
//

import WatchKit
import Foundation


class noHMaxInterfaceController: WKInterfaceController {
    
    
    @IBOutlet var backButton: WKInterfaceButton!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    @IBAction func backButtonTapped() {
        
        self.pushController(withName: "setHMax", context: nil)

    }
    
}

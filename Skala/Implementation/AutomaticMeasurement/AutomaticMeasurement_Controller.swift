//
//  AutomaticMeasurementController.swift
//  Skala
//
//  Created by Johannes Heinke Business on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import UIKit

internal final class AutomaticMeasurement_Controller: UIViewController {
    
    override final internal func viewDidLoad() {
        super.viewDidLoad()
        print("AutomaticMeasurement")
        
        //: Init State Pattern
        _ = self.walkingState.register(controller: self)
        _ = self.measurementState.register(controller: self)
        _ = self.settingState.register(controller: self)
    }
    
    override final internal func viewWillAppear(_ animated: Bool) {
        self._currentState = self.walkingState
    }
    
    //: StatePattern
    private final var _currentState: AutomaticMeasurement_GeneralState = ManualMeasurement_WalkingState.init()
    
    internal final let walkingState = AutomaticMeasurement_WalkingState.init()
    internal final let measurementState = AutomaticMeasurement_MeasurementState.init()
    internal final let settingState = AutomaticMeasurement_SettingState.init()
    
    internal final var currentState: AutomaticMeasurement_GeneralState {
        get {
            return self._currentState
        }
        
        set(newState) {
            self._currentState.disappaerState()
            self._currentState = newState
            self._currentState.appaerState()
        }
    }
}

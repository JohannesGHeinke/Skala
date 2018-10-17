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
        
        //: Init GUI
        self.cancelButton.alpha = 0.0
        
        self.view.addSubview(self.cancelButton)
    }
    
    override final internal func viewWillAppear(_ animated: Bool) {
        UIView.animate(withDuration: 0.5) {
            self.cancelButton.alpha = 1.0
        }
        
        self._currentState = self.walkingState
    }
    
    override final internal func viewWillDisappear(_ animated: Bool) {
        UIView.animate(withDuration: 0.2) {
            self.cancelButton.alpha = 0.0
        }
    }
    
    //: GUI-Elements
    internal lazy var cancelButton = { () -> AutomaticMeasurementUI_CancelButton in
        let button = AutomaticMeasurementUI_CancelButton.init(frame: CGRect.init(x: 70, y: 70, width: 70, height: 70)
            , controller: self)
        button.backgroundColor = UIColor.gray
        return button
    }()
    
    //: StatePattern
    private final var _currentState: AutomaticMeasurement_GeneralState = AutomaticMeasurement_WalkingState.init()
    
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

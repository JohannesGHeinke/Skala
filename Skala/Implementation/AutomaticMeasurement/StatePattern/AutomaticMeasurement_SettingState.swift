//
//  AutomaticMeasurement_SettingState.swift
//  Skala
//
//  Created by Johannes Heinke Business on 17.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import UIKit

internal struct AutomaticMeasurement_SettingState: AutomaticMeasurement_State {
    
    private let handler: AutomaticMeasurement_Controller
    
    init(handler: AutomaticMeasurement_Controller) {
        self.handler = handler
    }
    
    internal nonmutating func appaer() -> AutomaticMeasurement_Controller.StateKey? { return nil }
    internal nonmutating func disappaer() {}
    
    internal nonmutating func handleTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) -> AutomaticMeasurement_Controller.StateKey? {
        return .measuring
    }
    
    internal nonmutating func handleTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) -> AutomaticMeasurement_Controller.StateKey? {
        return nil
    }
    
    internal nonmutating func handleTouchesEnded() -> AutomaticMeasurement_Controller.StateKey? {
        return .walking
    }
    
    internal nonmutating func handleTouchesCancelled() -> AutomaticMeasurement_Controller.StateKey? {
        return .walking
    }
}

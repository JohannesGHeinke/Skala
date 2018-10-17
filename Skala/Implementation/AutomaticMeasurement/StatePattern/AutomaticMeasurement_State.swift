//
//  AutomaticMeasurement_State.swift
//  Skala
//
//  Created by Johannes Heinke Business on 17.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import UIKit

internal protocol AutomaticMeasurement_State {
    
    init(handler: AutomaticMeasurement_Controller)
    
    /// Called if the State goes to current State
    func appaer() -> AutomaticMeasurement_Controller.StateKey?
    /// Called if the State goes out of current State
    func disappaer()

    func handleTouchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) -> AutomaticMeasurement_Controller.StateKey?
    func handleTouchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) -> AutomaticMeasurement_Controller.StateKey?
    func handleTouchesEnded() -> AutomaticMeasurement_Controller.StateKey?
    func handleTouchesCancelled() -> AutomaticMeasurement_Controller.StateKey?
}

//
//  ManualMeasurement_StartState.swift
//  Skala
//
//  Created by Johannes Heinke Business on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

internal final class ManualMeasurement_WalkingState: ManualMeasurement_GeneralState {
    
    override final internal func appaerState() {
        print("ManualMeasurement Walking")
    }
    
    override final internal func handleTouchesBegan(at point: CGPoint) {
        self.interact { (controller) in
            UIView.animate(withDuration: 0.5, animations: {
                controller.resultLabel.alpha = 1.0
            })
            controller.currentState = controller.measurementState
        }
    }
}

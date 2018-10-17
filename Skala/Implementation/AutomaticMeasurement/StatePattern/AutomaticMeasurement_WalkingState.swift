//
//  AutomaticMeasurement_WalkingState.swift
//  Skala
//
//  Created by Johannes Heinke Business on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import CoreGraphics

internal final class AutomaticMeasurement_WalkingState: AutomaticMeasurement_GeneralState {
    
    override final func handleTouchesBegan(at point: CGPoint) {
        self.interact { (controller) in
            //: Check if the ray hits a node
            
        }
    }
}

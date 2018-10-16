//
//  ManualMeasurement_State.swift
//  Skala
//
//  Created by Johannes Heinke Business on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import CoreGraphics

internal class ManualMeasurement_GeneralState {
        
    private final var controller: ManualMesaurement_Controller? = nil
        
    internal func appaerState() {}
    internal func disappaerState() {}
    internal func handleTouchesBegan(at point: CGPoint) {}
    
    @discardableResult
    internal final func register(controller: ManualMesaurement_Controller) -> Bool {
        guard self.controller != nil else {
            self.controller = controller
            return true
        }
        return false
    }
        
    internal final func interact(_ interaction: (_ controller: ManualMesaurement_Controller) -> Void) {
        guard let safeView = self.controller else {
            return
        }
        interaction(safeView)
        }
}

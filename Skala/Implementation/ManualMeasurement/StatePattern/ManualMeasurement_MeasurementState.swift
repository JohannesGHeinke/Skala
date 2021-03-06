//
//  ManualMeasurement_MeasurementState.swift
//  Skala
//
//  Created by Johannes Heinke Business on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import SceneKit

internal final class ManualMeasurement_MeasurementState: ManualMeasurement_GeneralState {
    
    override final func appaerState() {
        print("ManualMeasurement Measurement")
        self.startPosition = nil
        self.handleMeasureSituation()
    }
    
    private final var timer = Timer.init()
    private final var startPosition: SCNVector3? = nil
    
    private final func handleMeasureSituation() {
        self.interact { (controller) in
            
            func getCurrentPosition() -> SCNVector3 {
                return controller.sceneView.unprojectPoint(SCNVector3Zero)
            }
            
            guard let startValue = self.startPosition else {
                self.startPosition = getCurrentPosition()
                self.timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (_) in
                    guard let startValue = self.startPosition else {
                        return
                    }
                    let endValue = getCurrentPosition()
                    controller.resultLabel.text = "\(((endValue.distance(from: startValue) * 10000) / 100).rounded()) cm"
                })
                return
            }
            let endValue = getCurrentPosition()
            controller.resultLabel.text = "\(((endValue.distance(from: startValue) * 10000) / 100).rounded()) cm"
            UIView.animate(withDuration: 0.5, animations: {
                controller.resultLabel.alpha = 0.4
            })
            controller.appendMeasurement(from: startValue, to: endValue)
            controller.currentState = controller.walkingState
        }
    }
    
    override final func handleTouchesBegan(at point: CGPoint) {
        self.handleMeasureSituation()
    }
    
    override func disappaerState() {
        self.timer.invalidate()
        self.startPosition = nil
    }
}

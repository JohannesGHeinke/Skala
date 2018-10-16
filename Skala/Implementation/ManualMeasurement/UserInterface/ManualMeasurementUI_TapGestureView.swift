//
//  ManualMeasurementUI_TapGestureView.swift
//  Skala
//
//  Created by Johannes Heinke Business on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import UIKit

internal final class ManualMeasurementUI_TapGestureView: UIImageView {
    
    private final let controller: ManualMesaurement_Controller
    
    init(frame: CGRect, controller: ManualMesaurement_Controller) {
        self.controller = controller
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override internal final func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touchLocation = touches.first else {
            return
        }
        let touchPoint = touchLocation.location(in: self.controller.view)
        self.controller.currentState.handleTouchesBegan(at: touchPoint)
    }
}

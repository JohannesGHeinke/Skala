//
//  ManualMeasurementUI_CancelButton.swift
//  Skala
//
//  Created by Johannes Heinke Business on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import UIKit

internal final class ManualMeasurementUI_CancelButton: UIButton {
    
    private final let controller: ManualMeasurement_Controller
    
    init(frame: CGRect, controller: ManualMeasurement_Controller) {
        self.controller = controller
        super.init(frame: frame)
    }
    
    override internal final func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.controller.dismiss(animated: true) {
            print("Dismissed")
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

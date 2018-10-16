//
//  ManualMeasurementUI_ResultLabel.swift
//  Skala
//
//  Created by Johannes Heinke Business on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import UIKit

internal final class ManualMeasurementUI_ResultLabel: UILabel {
    
    private final let controller: ManualMeasurement_Controller
    
    init(frame: CGRect, controller: ManualMeasurement_Controller) {
        self.controller = controller
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}

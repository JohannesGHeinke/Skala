//
//  AutomaticMeasurement_SettingState.swift
//  Skala
//
//  Created by Johannes Heinke Business on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import SceneKit

internal final class AutomaticMeasurement_SettingState: AutomaticMeasurement_GeneralState {
    
    internal final var hittingNodeBuffer = SCNNode.init()
    private final var hittingNode = SCNNode.init()
    
    override final func appaerState() {
        //: Sichert das immer auf der gleichen Referenz gearbeitet wird
        self.hittingNode = self.hittingNodeBuffer
    }
}

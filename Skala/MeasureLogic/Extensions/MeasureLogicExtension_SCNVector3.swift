//
//  MeasureLogicExtension_SCNVector3.swift
//  Skala
//
//  Created by Johannes Heinke Business on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import SceneKit

internal extension SCNVector3 {
    internal nonmutating func distanceFromPos(pos: SCNVector3) -> Float {
        let diff = SCNVector3(self.x - pos.x, self.y - pos.y, self.z - pos.z);
        return sqrtf(diff.x * diff.x + diff.y * diff.y + diff.z * diff.z)
    }
}

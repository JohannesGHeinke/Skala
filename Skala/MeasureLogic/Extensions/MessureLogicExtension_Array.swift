//
//  File.swift
//  Skala
//
//  Created by Johannes Heinke on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import SceneKit

internal extension Array where Element == SCNVector3 {
    internal var average: SCNVector3? {
        guard !self.isEmpty else {
            return nil
        }
        let total = self.reduce(SCNVector3Zero) { (tmp, vector) -> SCNVector3 in
            return SCNVector3.init(tmp.x + vector.x, tmp.y + vector.y, tmp.z + vector.z)
        }
        return SCNVector3.init(total.x / Float(self.count), total.y / Float(self.count), total.z / Float(self.count))
    }
}

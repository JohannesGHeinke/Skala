//
//  Drawing.swift
//  Skala
//
//  Created by Johannes Heinke on 23.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import SceneKit

internal extension SCNNode {
    internal final func createLine(to endPosition: SCNVector3) -> SCNNode {
        let distance = self.position.distance(from: endPosition)
        let lineGeometry = SCNCylinder.init(radius: 0.002, height: CGFloat(distance))
        let line = SCNNode.init(geometry: lineGeometry)
        
        let originalVector = SCNVector3.init(0, distance / 2.0, 0)
        let targetVector = SCNVector3.init((endPosition.x - self.position.x) / 2.0, (endPosition.y - self.position.y) / 2.0, (endPosition.z - self.position.z) / 2.0)
        let axis = SCNVector3.init((originalVector.x + targetVector.x) / 2.0, (originalVector.y + targetVector.y) / 2.0, (originalVector.z + targetVector.z) / 2.0)
        let axisNormalized = axis.normalized
        
        let r_m11 = { () -> Float in
            let r_m11_1 = axisNormalized.x * axisNormalized.x
            let r_m11_2 = axisNormalized.y * axisNormalized.y
            let r_m11_3 = axisNormalized.z * axisNormalized.z
            return r_m11_1 - r_m11_2 - r_m11_3
        }()
        let r_m12 = 2 * axisNormalized.x * axisNormalized.y
        let r_m13 = 2 * axisNormalized.x * axisNormalized.z
        
        let r_m21 = 2 * axisNormalized.x * axisNormalized.y
        let r_m22 = { () -> Float in
            let r_m22_1 = -(axisNormalized.x * axisNormalized.x)
            let r_m22_2 = axisNormalized.y * axisNormalized.y
            let r_m22_3 = axisNormalized.z * axisNormalized.z
            return r_m22_1 + r_m22_2 - r_m22_3
        }()
        let r_m23 = 2 * axisNormalized.y * axisNormalized.z
        
        let r_m31 = 2 * axisNormalized.x * axisNormalized.z
        let r_m32 = 2 * axisNormalized.y * axisNormalized.z
        let r_m33 = { () -> Float in
            let r_m33_1 = -(axisNormalized.x * axisNormalized.x)
            let r_m33_2 = axisNormalized.y * axisNormalized.y
            let r_m33_3 = axisNormalized.z * axisNormalized.z
            return r_m33_1 - r_m33_2 + r_m33_3
        }()
        
        line.transform = { () -> SCNMatrix4 in
            return SCNMatrix4.init(m11: r_m11, m12: r_m12, m13: r_m13, m14: 0.0,
                                   m21: r_m21, m22: r_m22, m23: r_m23, m24: 0.0,
                                   m31: r_m31, m32: r_m32, m33: r_m33, m34: 0.0,
                                   m41: (self.position.x + endPosition.x) / 2.0,
                                   m42: (self.position.y + endPosition.y) / 2.0,
                                   m43: (self.position.z + endPosition.z) / 2.0,
                                   m44: 1.0)
        }()
        
        return line
    }
}

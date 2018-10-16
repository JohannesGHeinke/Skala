//
//  MeasureLogicExtension_SCNVector3.swift
//  Skala
//
//  Created by Johannes Heinke Business on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import SceneKit

internal let SCNVector3One: SCNVector3 = SCNVector3(1.0, 1.0, 1.0)

extension SCNVector3: CustomStringConvertible {
    public var description: String {
        return "(\(String(format: "%.2f", self.x)), \(String(format: "%.2f", self.y)), \(String(format: "%.2f", self.z)))"
    }
}

internal extension SCNVector3 {
    
    init(_ vec: vector_float3) {
        self.init()
        self.x = vec.x
        self.y = vec.y
        self.z = vec.z
    }
    
    internal nonmutating func distance(from position: SCNVector3) -> Float {
        let diff = SCNVector3(self.x - position.x, self.y - position.y, self.z - position.z);
        return diff.length
    }
    
    internal var length: Float {
        return sqrtf(self.x * self.x + self.y * self.y + self.z * self.z)
    }
    
    internal mutating func setLength(_ length: Float) {
        self.normalize()
        self *= length
    }
    
    internal mutating func setMaximumLength(_ maxLength: Float) {
        if self.length <= maxLength {
            return
        } else {
            self.normalize()
            self *= maxLength
        }
    }
    
    internal mutating func normalize() {
        self = { () -> SCNVector3 in
            guard self.length == 0  else {
                return self / self.length
            }
            return self
        }()
    }
    
    internal static func position(from transform: matrix_float4x4) -> SCNVector3 {
        return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    }
    
    internal nonmutating func dot(_ vec: SCNVector3) -> Float {
        return (self.x * vec.x) + (self.y * vec.y) + (self.z * vec.z)
    }
    
    internal nonmutating func cross(_ vec: SCNVector3) -> SCNVector3 {
        return SCNVector3(self.y * vec.z - self.z * vec.y, self.z * vec.x - self.x * vec.z, self.x * vec.y - self.y * vec.x)
    }
    
    internal nonmutating func SCNVector3Uniform(_ value: Float) -> SCNVector3 {
        return SCNVector3Make(value, value, value)
    }
    
    internal nonmutating func SCNVector3Uniform(_ value: CGFloat) -> SCNVector3 {
        return SCNVector3Make(Float(value), Float(value), Float(value))
    }
    
    internal static func +(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }
    
    internal static func -(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }
    
    internal static func +=(lhs: inout SCNVector3, rhs: SCNVector3) {
        lhs = lhs + rhs
    }
    
    internal static func -=(lhs: inout SCNVector3, rhs: SCNVector3) {
        lhs = lhs - rhs
    }
    
    internal static func /(lhs: SCNVector3, rhs: Float) -> SCNVector3 {
        return SCNVector3Make(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
    }
    
    internal static func *(lhs: SCNVector3, rhs: Float) -> SCNVector3 {
        return SCNVector3Make(lhs.x * rhs, lhs.y * rhs, lhs.z * rhs)
    }
    
    internal static func /=(lhs: inout SCNVector3, rhs: Float) {
        lhs = lhs / rhs
    }
    
    internal static func *=(lhs: inout SCNVector3, rhs: Float) {
        lhs = lhs * rhs
    }
}

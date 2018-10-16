//
//  MeasureLogicExtension_CGPoint.swift
//  Skala
//
//  Created by Johannes Heinke on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import CoreGraphics
import SceneKit

extension CGPoint: CustomStringConvertible {
    public var description: String {
       return "(\(String(format: "%.2f", self.x)), \(String(format: "%.2f", self.y)))"
    }
}

internal extension CGPoint {
    
    //: Basic Calculations
    internal static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    internal static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    internal static func +=(lhs: inout CGPoint, rhs: CGPoint) {
        lhs = lhs + rhs
    }
    
    internal static func -=(lhs: inout CGPoint, rhs: CGPoint) {
        lhs = lhs - rhs
    }
    
    internal static func /(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
    
    internal static func *(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
    
    internal static func /=(lhs: inout CGPoint, rhs: CGFloat) {
        lhs = lhs / rhs
    }
    
    internal static func *= (left: inout CGPoint, right: CGFloat) {
        left = left * right
    }

    init(_ size: CGSize) {
        self.init()
        self.x = size.width
        self.y = size.height
    }
    
    init(_ vector: SCNVector3) {
        self.init()
        self.x = CGFloat(vector.x)
        self.y = CGFloat(vector.y)
    }
    
    internal nonmutating func distance(to point: CGPoint) -> CGFloat {
        return (self - point).length
    }
    
    internal var length: CGFloat {
        return sqrt(self.x * self.x + self.y * self.y)
    }
    
    internal nonmutating func midpoint(_ point: CGPoint) -> CGPoint {
        return (self + point) / 2
    }
}

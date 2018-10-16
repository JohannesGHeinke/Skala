//
//  MeasureLogicExtension_CGSize.swift
//  Skala
//
//  Created by Johannes Heinke on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGSize: CustomStringConvertible {
    public var description: String {
        return "(\(String(format: "%.2f", self.width)), \(String(format: "%.2f", self.height)))"
    }
}

internal extension CGSize {
    init(_ point: CGPoint) {
        self.init()
        self.width = point.x
        self.height = point.y
    }
    
    internal static func +(lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    
    internal static func -(lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    
    internal static func +=(lhs: inout CGSize, rhs: CGSize) {
        lhs = lhs + rhs
    }
    
   internal static func -=(lhs: inout CGSize, rhs: CGSize) {
        lhs = lhs - rhs
    }
    
    internal static func /(lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
    }
    
    internal static func *(lhs: CGSize, rhs: CGFloat) -> CGSize {
        return CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    
    internal static func /=(lhs: inout CGSize, rhs: CGFloat) {
        lhs = lhs / rhs
    }
    
    internal static func *=(lhs: inout CGSize, rhs: CGFloat) {
        lhs = lhs * rhs
    }
}

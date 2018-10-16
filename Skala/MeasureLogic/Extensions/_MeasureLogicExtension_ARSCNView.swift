//
//  MeasureLogicExtension_ARSCNView.swift
//  Skala
//
//  Created by Johannes Heinke Business on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

// MARK: - SCNNode extension
extension SCNNode {
    
    func setUniformScale(_ scale: Float) {
        self.scale = SCNVector3Make(scale, scale, scale)
    }
    
    func renderOnTop() {
        self.renderingOrder = 2
        if let geom = self.geometry {
            for material in geom.materials {
                material.readsFromDepthBuffer = false
            }
        }
        for child in self.childNodes {
            child.renderOnTop()
        }
    }
    
    func setPivot() {
        let minVec = self.boundingBox.min
        let maxVec = self.boundingBox.max
        let bound = SCNVector3Make( maxVec.x - minVec.x, maxVec.y - minVec.y, maxVec.z - minVec.z);
        self.pivot = SCNMatrix4MakeTranslation(bound.x / 2, bound.y, bound.z / 2);
    }
}

// MARK: - SCNVector3 extensions


// MARK: - SCNMaterial extensions
extension SCNMaterial {
    
    static func material(withDiffuse diffuse: Any?, respondsToLighting: Bool = true) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = diffuse
        material.isDoubleSided = true
        if respondsToLighting {
            material.locksAmbientWithDiffuse = true
        } else {
            material.ambient.contents = UIColor.black
            material.lightingModel = .constant
            material.emission.contents = diffuse
        }
        return material
    }
}

// MARK: - Collection extensions
extension Array where Iterator.Element == CGFloat {
    var average: CGFloat? {
        guard !isEmpty else {
            return nil
        }
        
        var ret = self.reduce(CGFloat(0)) { (cur, next) -> CGFloat in
            var cur = cur
            cur += next
            return cur
        }
        let fcount = CGFloat(count)
        ret /= fcount
        return ret
    }
}


extension RangeReplaceableCollection where IndexDistance == Int {
    mutating func keepLast(_ elementsToKeep: Int) {
        if count > elementsToKeep {
            self.removeFirst(count - elementsToKeep)
        }
    }
}

// MARK: - CGRect extensions
extension CGRect {
    
    var mid: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}


func != (lhs: ARCamera.TrackingState, rhs: ARCamera.TrackingState) -> Bool {
    switch (lhs, rhs) {
    case (ARCamera.TrackingState.normal, ARCamera.TrackingState.normal):
        return false
    case (ARCamera.TrackingState.notAvailable, ARCamera.TrackingState.notAvailable):
        return false
    case (ARCamera.TrackingState.limited(let lhsr), ARCamera.TrackingState.limited(let rhsr)):
        return lhsr != rhsr
    default:
        return true
    }
}



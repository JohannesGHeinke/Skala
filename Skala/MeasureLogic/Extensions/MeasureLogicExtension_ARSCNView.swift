//
//  MeasureLogicExtension_ARSCNView.swift
//  Skala
//
//  Created by Johannes Heinke on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import ARKit

internal extension ARSCNView {
    internal final func worldPosition(from touchPosition: CGPoint) -> (position: SCNVector3, planeAnchor: ARPlaneAnchor?)? {
        
        let planeHitTestResults = self.hitTest(touchPosition, types: .existingPlaneUsingExtent)
        if let concreteResult = planeHitTestResults.first {
            let planeHitTestPosition = SCNVector3.position(from: concreteResult.worldTransform)
            let planeAnchor = concreteResult.anchor
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor)
        } else {
            
            let highQualityfeatureHitTestResults = self.hitTestWithFeatures(touchPosition, coneOpeningAngleInDegrees: 5, minDistance: 0.1, maxDistance: 3.0)
            let featureCloud = self.fliterWithFeatures(highQualityfeatureHitTestResults)
            
            guard featureCloud.count >= 3 else {
                
                var featureHitTestPosition: SCNVector3?
                var highQualityFeatureHitTestResult = false
                
                if !featureCloud.isEmpty {
                    featureHitTestPosition = featureCloud.average
                    highQualityFeatureHitTestResult = true
                } else if !highQualityfeatureHitTestResults.isEmpty {
                    featureHitTestPosition = highQualityfeatureHitTestResults.map { (featureHitTestResult) -> SCNVector3 in
                        return featureHitTestResult.position
                    }.average
                    highQualityFeatureHitTestResult = true
                }
                
                if !highQualityFeatureHitTestResult {
                    let pointOnInfinitePlane = self.hitTestWithInfiniteHorizontalPlane(touchPosition, SCNVector3Zero)
                    
                    if let concretePointOnInfinitePlane = pointOnInfinitePlane {
                        return (concretePointOnInfinitePlane, nil)
                    }
                }
                
                if highQualityFeatureHitTestResult, let hitTestPosition = featureHitTestPosition {
                    return (hitTestPosition, nil)
                }
                
                let unfilteredFeatureHitTestResults = self.hitTestWithFeatures(touchPosition)
                guard !unfilteredFeatureHitTestResults.isEmpty else {
                    return nil
                }
                let result = unfilteredFeatureHitTestResults[0]
                return (result.position, nil)
            }
            return (featureCloud.average!, nil)
        }
    }
    
    fileprivate struct HitTestRay {
        fileprivate let origin: SCNVector3
        fileprivate let direction: SCNVector3
    }
    
    private final func hitTestRayFromScreenPos(_ point: CGPoint) -> HitTestRay? {
        
        guard let frame = self.session.currentFrame else {
            return nil
        }
        
        let cameraPos = SCNVector3.position(from: frame.camera.transform)
        
        // Note: z: 1.0 will unproject() the screen position to the far clipping plane.
        let positionVec = SCNVector3(x: Float(point.x), y: Float(point.y), z: 1.0)
        let screenPosOnFarClippingPlane = self.unprojectPoint(positionVec)
        
        var rayDirection = screenPosOnFarClippingPlane - cameraPos
        rayDirection.normalize()
        
        return HitTestRay(origin: cameraPos, direction: rayDirection)
    }
    
    private final func hitTestWithInfiniteHorizontalPlane(_ point: CGPoint, _ pointOnPlane: SCNVector3) -> SCNVector3? {
        
        guard let ray = hitTestRayFromScreenPos(point) else {
            return nil
        }
        guard ray.direction.y > -0.03 else {
            return rayIntersectionWithHorizontalPlane(rayOrigin: ray.origin, direction: ray.direction, planeY: pointOnPlane.y)
        }
        return nil
    }
    
    private final func rayIntersectionWithHorizontalPlane(rayOrigin: SCNVector3, direction: SCNVector3, planeY: Float) -> SCNVector3? {
        let direction = { () -> SCNVector3 in
            var tmp = direction
            tmp.normalize()
            return tmp
        }()
        if direction.y == 0 {
            if rayOrigin.y == planeY {
                return rayOrigin
            } else {
                return nil
            }
        }
        let dist = (planeY - rayOrigin.y) / direction.y
        guard dist < 0 else {
            return rayOrigin + (direction * dist)
        }
        return nil
    }
    
    fileprivate struct FeatureHitTestResult {
        fileprivate let position: SCNVector3
        fileprivate let distanceToRayOrigin: Float
        fileprivate let featureHit: SCNVector3
        fileprivate let featureDistanceToHitResult: Float
    }
    
    private final func hitTestWithFeatures(_ point: CGPoint, coneOpeningAngleInDegrees: Float,
                             minDistance: Float = 0,
                             maxDistance: Float = Float.greatestFiniteMagnitude,
                             maxResults: Int = 40) -> [FeatureHitTestResult] {
        
        var results = [FeatureHitTestResult]()
        
        guard let features = self.session.currentFrame?.rawFeaturePoints else {
            return results
        }
        
        guard let ray = hitTestRayFromScreenPos(point) else {
            return results
        }
        
        let maxAngleInDeg = min(coneOpeningAngleInDegrees, 360) / 2
        let maxAngle = ((maxAngleInDeg / 180) * Float.pi)
        
        let points = features.__points
        
        for i in 0...features.__count {
            
            let feature = points.advanced(by: Int(i))
            let featurePos = SCNVector3(feature.pointee)
            
            let originToFeature = featurePos - ray.origin
            
            let crossProduct = originToFeature.cross(ray.direction)
            let featureDistanceFromResult = crossProduct.length
            
            let hitTestResult = ray.origin + (ray.direction * ray.direction.dot(originToFeature))
            let hitTestResultDistance = (hitTestResult - ray.origin).length
            
            if hitTestResultDistance < minDistance || hitTestResultDistance > maxDistance {
                continue
            }
            
            let originToFeatureNormalized = { () -> SCNVector3 in
                var tmp = originToFeature
                tmp.normalize()
                return tmp
            }()
            let angleBetweenRayAndFeature = acos(ray.direction.dot(originToFeatureNormalized))
            
            if angleBetweenRayAndFeature > maxAngle {
                continue
            }
            
            results.append(FeatureHitTestResult(position: hitTestResult,
                                                distanceToRayOrigin: hitTestResultDistance,
                                                featureHit: featurePos,
                                                featureDistanceToHitResult: featureDistanceFromResult))
        }
        
        
        if results.count < maxResults {
            return results
        }
        
        var cappedResults = [FeatureHitTestResult]()
        var i = 0
        while i < maxResults && i < results.count {
            cappedResults.append(results[i])
            i += 1
        }
        
        return cappedResults
    }
    
    private final func hitTestWithFeatures(_ point: CGPoint) -> [FeatureHitTestResult] {
        
        var results = [FeatureHitTestResult]()
        
        guard let ray = hitTestRayFromScreenPos(point) else {
            return results
        }
        
        if let result = self.hitTestFromOrigin(origin: ray.origin, direction: ray.direction) {
            results.append(result)
        }
        
        return results
    }
    
    private final func hitTestFromOrigin(origin: SCNVector3, direction: SCNVector3) -> FeatureHitTestResult? {
        
        guard let features = self.session.currentFrame?.rawFeaturePoints else {
            return nil
        }
        
        let points = features.__points
        
        // Determine the point from the whole point cloud which is closest to the hit test ray.
        var closestFeaturePoint = origin
        var minDistance = Float.greatestFiniteMagnitude
        
        for i in 0...features.__count {
            let feature = points.advanced(by: Int(i))
            let featurePos = SCNVector3(feature.pointee)
            
            let originVector = origin - featurePos
            let crossProduct = originVector.cross(direction)
            let featureDistanceFromResult = crossProduct.length
            
            if featureDistanceFromResult < minDistance {
                closestFeaturePoint = featurePos
                minDistance = featureDistanceFromResult
            }
        }
        
        let originToFeature = closestFeaturePoint - origin
        let hitTestResult = origin + (direction * direction.dot(originToFeature))
        let hitTestResultDistance = (hitTestResult - origin).length
        
        return FeatureHitTestResult(position: hitTestResult,
                                    distanceToRayOrigin: hitTestResultDistance,
                                    featureHit: closestFeaturePoint,
                                    featureDistanceToHitResult: minDistance)
    }
    
    private final func fliterWithFeatures(_ features:[FeatureHitTestResult]) -> [SCNVector3] {
        guard features.count >= 3 else {
            return features.map { (featureHitTestResult) -> SCNVector3 in
                return featureHitTestResult.position
            };
        }
        
        var points = features.map { (featureHitTestResult) -> SCNVector3 in
            return featureHitTestResult.position
        }
        let average = points.average!
        let variance = sqrtf(points.reduce(0) { (sum, point) -> Float in
            var sum = sum
            sum += (point - average).length * 100 * (point - average).length * 100
            return sum
            } / Float(points.count-1))
        let standard = sqrtf(variance)
        let σ = variance / standard
        points = points.filter { (point) -> Bool in
            if (point - average).length * 100 > 3 * σ {
                print(point,average)
            }
            return (point - average).length * 100 < 3 * σ
        }
        return points
    }
}


//
//  MeasureLogicExtension_ARSCNView.swift
//  Skala
//
//  Created by Johannes Heinke Business on 16.10.18.
//  Copyright © 2018 Mikavaa. All rights reserved.
//

import Foundation
import ARKit

extension ARSCNView {
    func worldPositionFromScreenPosition(_ position: CGPoint,
                                         objectPos: SCNVector3?,
                                         infinitePlane: Bool = false) -> (position: SCNVector3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
        
        let sceneView = self
        let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {
            
            let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let planeAnchor = result.anchor
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }
        
        var featureHitTestPosition: SCNVector3?
        var highQualityFeatureHitTestResult = false
        
        let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 5, minDistance: 0.1, maxDistance: 3.0)
        let featureCloud = sceneView.fliterWithFeatures(highQualityfeatureHitTestResults)
        
        if featureCloud.count >= 3 {
            
            let (detectPlane, planePoint) = planeDetectWithFeatureCloud(featureCloud: featureCloud)
            
            let ray = sceneView.hitTestRayFromScreenPos(position)
            let crossPoint = planeLineIntersectPoint(planeVector: detectPlane, planePoint: planePoint, lineVector: ray!.direction, linePoint: ray!.origin)
            if crossPoint != nil {
                return (crossPoint, nil, false)
            }else{
                return (featureCloud.average!, nil, false)
            }
        }
        
        if !featureCloud.isEmpty {
            featureHitTestPosition = featureCloud.average
            highQualityFeatureHitTestResult = true
        }else if !highQualityfeatureHitTestResults.isEmpty {
            featureHitTestPosition = highQualityfeatureHitTestResults.map { (featureHitTestResult) -> SCNVector3 in
                return featureHitTestResult.position
                }.average
            highQualityFeatureHitTestResult = true
        }
        
        if infinitePlane || !highQualityFeatureHitTestResult {
            
            let pointOnPlane = objectPos ?? SCNVector3Zero
            
            let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
            if pointOnInfinitePlane != nil {
                return (pointOnInfinitePlane, nil, true)
            }
        }
        
        if highQualityFeatureHitTestResult {
            return (featureHitTestPosition, nil, false)
        }
        
        let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
        if !unfilteredFeatureHitTestResults.isEmpty {
            let result = unfilteredFeatureHitTestResults[0]
            return (result.position, nil, false)
        }
        
        return (nil, nil, false)
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


extension ARSCNView {
    
    struct HitTestRay {
        let origin: SCNVector3
        let direction: SCNVector3
    }
    
    func hitTestRayFromScreenPos(_ point: CGPoint) -> HitTestRay? {
        
        guard let frame = self.session.currentFrame else {
            return nil
        }
        
        let cameraPos = SCNVector3.positionFromTransform(frame.camera.transform)
        
        // Note: z: 1.0 will unproject() the screen position to the far clipping plane.
        let positionVec = SCNVector3(x: Float(point.x), y: Float(point.y), z: 1.0)
        let screenPosOnFarClippingPlane = self.unprojectPoint(positionVec)
        
        var rayDirection = screenPosOnFarClippingPlane - cameraPos
        rayDirection.normalize()
        
        return HitTestRay(origin: cameraPos, direction: rayDirection)
    }
    
    func hitTestWithInfiniteHorizontalPlane(_ point: CGPoint, _ pointOnPlane: SCNVector3) -> SCNVector3? {
        
        guard let ray = hitTestRayFromScreenPos(point) else {
            return nil
        }
        if ray.direction.y > -0.03 {
            return nil
        }
        return rayIntersectionWithHorizontalPlane(rayOrigin: ray.origin, direction: ray.direction, planeY: pointOnPlane.y)
    }
    
    struct FeatureHitTestResult {
        let position: SCNVector3
        let distanceToRayOrigin: Float
        let featureHit: SCNVector3
        let featureDistanceToHitResult: Float
    }
    
    func hitTestWithFeatures(_ point: CGPoint, coneOpeningAngleInDegrees: Float,
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
            let featureDistanceFromResult = crossProduct.length()
            
            let hitTestResult = ray.origin + (ray.direction * ray.direction.dot(originToFeature))
            let hitTestResultDistance = (hitTestResult - ray.origin).length()
            
            if hitTestResultDistance < minDistance || hitTestResultDistance > maxDistance {
                continue
            }
            
            let originToFeatureNormalized = originToFeature.normalized()
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
    
    func hitTestWithFeatures(_ point: CGPoint) -> [FeatureHitTestResult] {
        
        var results = [FeatureHitTestResult]()
        
        guard let ray = hitTestRayFromScreenPos(point) else {
            return results
        }
        
        if let result = self.hitTestFromOrigin(origin: ray.origin, direction: ray.direction) {
            results.append(result)
        }
        
        return results
    }
    
    func hitTestFromOrigin(origin: SCNVector3, direction: SCNVector3) -> FeatureHitTestResult? {
        
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
            let featureDistanceFromResult = crossProduct.length()
            
            if featureDistanceFromResult < minDistance {
                closestFeaturePoint = featurePos
                minDistance = featureDistanceFromResult
            }
        }
        
        let originToFeature = closestFeaturePoint - origin
        let hitTestResult = origin + (direction * direction.dot(originToFeature))
        let hitTestResultDistance = (hitTestResult - origin).length()
        
        return FeatureHitTestResult(position: hitTestResult,
                                    distanceToRayOrigin: hitTestResultDistance,
                                    featureHit: closestFeaturePoint,
                                    featureDistanceToHitResult: minDistance)
    }
    
    func fliterWithFeatures(_ features:[FeatureHitTestResult]) -> [SCNVector3] {
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
            sum += (point-average).length()*100*(point-average).length()*100
            return sum
            }/Float(points.count-1))
        let standard = sqrtf(variance)
        let σ = variance/standard
        points = points.filter { (point) -> Bool in
            if (point-average).length()*100 > 3*σ {
                print(point,average)
            }
            return (point-average).length()*100 < 3*σ
        }
        return points
    }
}

func planeDetectWithFeatureCloud(featureCloud: [SCNVector3]) -> (detectPlane: SCNVector3, planePoint: SCNVector3) {
    let warpFeatures = featureCloud.map({ (feature) -> NSValue in
        return NSValue(scnVector3: feature)
    })
    let result = PlaneDetector.detectPlane(withPoints: warpFeatures)
    var planePoint = SCNVector3Zero
    if result.x != 0 {
        planePoint = SCNVector3(result.w/result.x,0,0)
    }else if result.y != 0 {
        planePoint = SCNVector3(0,result.w/result.y,0)
    }else {
        planePoint = SCNVector3(0,0,result.w/result.z)
    }
    let detectPlane = SCNVector3(result.x, result.y, result.z)
    return (detectPlane, planePoint)
}

/// 根据直线上的点和向量及平面上的点和法向量计算交点
/// - Parameters:
///   - planeVector: 平面法向量
///   - planePoint: 平面上一点
///   - lineVector: 直线向量
///   - linePoint: 直线上一点
/// - Returns: 交点
func planeLineIntersectPoint(planeVector: SCNVector3 , planePoint: SCNVector3, lineVector: SCNVector3, linePoint: SCNVector3) -> SCNVector3? {
    let vpt = planeVector.x * lineVector.x + planeVector.y * lineVector.y + planeVector.z * lineVector.z
    if vpt != 0 {
        let t = ((planePoint.x-linePoint.x)*planeVector.x + (planePoint.y-linePoint.y)*planeVector.y + (planePoint.z-linePoint.z)*planeVector.z)/vpt
        let cross = SCNVector3Make(linePoint.x + lineVector.x*t, linePoint.y + lineVector.y*t, linePoint.z + lineVector.z*t)
        if (cross-linePoint).length() < 5 {
            return cross
        }
    }
    return nil
}


// 点云拟合多边形求面积
/// - Parameters:
///   - points: 顶点坐标
/// - Returns: 面积
func area3DPolygonFormPointCloud(points: [SCNVector3]) -> Float32 {
    let (detectPlane, planePoint) = planeDetectWithFeatureCloud(featureCloud: points)
    var newPoints = [SCNVector3]()
    for p in points {
        guard let ip = planeLineIntersectPoint(planeVector: detectPlane, planePoint: planePoint, lineVector: detectPlane, linePoint: p) else {
            return 0
        }
        newPoints.append(ip)
    }
    return area3DPolygon(points: newPoints, plane: detectPlane)
}

// 空间多边形面积
/// - Parameters:
///   - points: 顶点坐标
///   - plane: 多边形所在平面法向量
/// - Returns: 面积
func area3DPolygon(points: [SCNVector3], plane: SCNVector3 ) -> Float32 {
    let n = points.count
    guard n >= 3 else { return 0 }
    var V = points
    V.append(points[0])
    V.append(points[1])
    let N = plane
    var area = Float(0)
    var (an, ax, ay, az) = (Float(0), Float(0), Float(0), Float(0))
    var coord = 0   // 1=x, 2=y, 3=z
    var (i, j, k) = (0, 0, 0)
    
    ax = (N.x>0 ? N.x : -N.x)
    ay = (N.y>0 ? N.y : -N.y)
    az = (N.z>0 ? N.z : -N.z)
    
    coord = 3;
    if (ax > ay) {
        if (ax > az) {
            coord = 1
        }
    } else if (ay > az) {
        coord = 2
    }
    
    (i, j, k) = (1, 2, 0)
    while i<=n {
        switch (coord) {
        case 1:
            area += (V[i].y * (V[j].z - V[k].z))
        case 2:
            area += (V[i].x * (V[j].z - V[k].z))
        case 3:
            area += (V[i].x * (V[j].y - V[k].y))
        default:
            break
        }
        i += 1
        j += 1
        k += 1
    }
    
    an = sqrt( ax*ax + ay*ay + az*az)
    switch (coord) {
    case 1:
        area *= (an / (2*ax))
    case 2:
        area *= (an / (2*ay))
    case 3:
        area *= (an / (2*az))
    default:
        break
    }
    return area
}


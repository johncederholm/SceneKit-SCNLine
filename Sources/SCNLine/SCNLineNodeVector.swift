//
//  SCNLineNodeVector.swift
//  Wunderdraw
//
//  Created by John Cederholm on 8/9/20.
//  Copyright © 2020 d2i LLC. All rights reserved.
//

import Foundation
import SceneKit

public class SCNLineNodeVector {
    
    enum VectorType {
        case first
        case middle
        case last
    }
    
    let vector:SCNVector3
    var individualTrueNormals:[SCNVector3]
    var individualTrueUVMap:[CGPoint]
    var individualTrueVs:[SCNVector3]
    var lineLength:CGFloat
    var lastLocation:SCNVector3
    var cPoints:[SCNVector3]
    var lastForward:SCNVector3
    var indices:[UInt32]
    var vectorType:VectorType
    
    init(first vector:SCNVector3, second secondVector:SCNVector3, radius:Float, edges:Int) {
        let startDirection = (secondVector - vector).normalized()
        let lastLocation = vector
        var lastForward = SCNVector3(0, 1, 0)
        let orientation = simd_quaternion(simd_float3([lastForward.x, lastForward.y, lastForward.z]), simd_float3([startDirection.x, startDirection.y, startDirection.z]))
        var cPoints = SCNGeometry.getCircularPoints(radius: radius, edges: edges, orientation: orientation)
        
        let cPointsInitial = SCNGeometry.getCircularPoints(radius: radius, edges: edges)
        let textureXs = cPointsInitial.enumerated().map({val -> CGFloat in
            return CGFloat(val.offset) / CGFloat(edges - 1)
        })
        lastForward = startDirection.normalized()
        let newRotation = simd_quatf.zero()
        cPoints = cPoints.map({newRotation.act($0)})
        lastForward = newRotation.act(lastForward)
        
        let lineLength:CGFloat = 0
        
        self.vector = vector
        
        
        var trueNormals = [SCNVector3]()
        
        trueNormals.append(contentsOf: cPoints.map({$0.normalized()}))
        self.individualTrueNormals = trueNormals
        
        var trueUVMap = [CGPoint]()
        trueUVMap.append(contentsOf: textureXs.map({CGPoint(x: $0, y: lineLength)}))
        self.individualTrueUVMap = trueUVMap
        
        var trueVs = [SCNVector3]()
        trueVs.append(contentsOf: cPoints.map({$0 + vector}))
        self.individualTrueVs = trueVs
        
        self.lineLength = lineLength
        
        self.lastLocation = lastLocation
        
        self.cPoints = cPoints
        
        self.lastForward = lastForward
        
        self.indices = []
        
        self.vectorType = .first
    }
    
    init(last vector:SCNVector3,
         previousVector:SCNLineNodeVector,
         edges:Int,
         radius:Float,
         maxTurning:Int,
         totalTrueNormals:[SCNVector3],
         totalTrueVs:[SCNVector3],
         totalTrueUVMap:[CGPoint],
         totalTrueInds:[UInt32],
         totalCPoints:[SCNVector3],
         totalLineLength:CGFloat) {
        
        self.vector = vector
        self.vectorType = .last
        
        let newRotation = simd_quatf(angle: 0, axis: SIMD3<Float>([1, 0, 0]))
        
        var totalTrueNormals = totalTrueNormals
        var totalTrueVs = totalTrueVs
        var totalTrueUVMap = totalTrueUVMap
        var totalTrueInds = totalTrueInds
        var totalLineLength = totalLineLength
        var totalCPoints = totalCPoints
        
        var trueNormals = [SCNVector3]()
        var trueVs = [SCNVector3]()
        var trueUVMap = [CGPoint]()
        var trueInds = [UInt32]()
        var cPoints = [SCNVector3]()
        
        var lineLength:CGFloat = 0
        
        var lastLocation = previousVector.lastLocation
        var lastForward = previousVector.lastForward
        
        let cPointsInitial = SCNGeometry.getCircularPoints(radius: radius, edges: edges)
        let textureXs = cPointsInitial.enumerated().map({val -> CGFloat in
            return CGFloat(val.offset) / CGFloat(edges - 1)
        })
        
        let halfRotation = newRotation.split(by: 2)
        
        if vector.distance(to: previousVector.vector) > (radius * 2) {
            let mTurn = max(1, min(newRotation.angle / .pi, 1) * Float(maxTurning))
            if mTurn > 1 {
                let partRotation = newRotation.split(by: Float(mTurn))
                let halfForward = newRotation.split(by: 2).act(lastForward)
                for i in 0..<Int(mTurn) {
                    
                    totalTrueNormals.append(contentsOf: totalCPoints.map({$0.normalized()}))
                    trueNormals.append(contentsOf: totalCPoints.map({$0.normalized()}))
                    
                    let angleProgress = Float(i) / Float(mTurn - 1) - 0.5
                    let tangle = radius * angleProgress
                    let nextLocation = vector + (halfForward.normalized() * tangle)
                    
                    totalLineLength += CGFloat(lastLocation.distance(to: nextLocation))
                    lineLength += CGFloat(lastLocation.distance(to: nextLocation))
                    
                    lastLocation = nextLocation
                    
                    totalTrueVs.append(contentsOf: totalCPoints.map({$0 + nextLocation}))
                    trueVs.append(contentsOf: totalCPoints.map({$0 + nextLocation}))
                    
                    totalTrueUVMap.append(contentsOf: textureXs.map ({ CGPoint(x: $0, y: lineLength) }))
                    trueUVMap.append(contentsOf: textureXs.map ({ CGPoint(x: $0, y: lineLength) }))
                    
                    SCNLineNodeVector.addCylinderVerts(to: &trueInds, startingAt: totalTrueVs.count - edges * 4, edges: edges)
                    SCNLineNodeVector.addCylinderVerts(to: &totalTrueInds, startingAt: totalTrueVs.count - edges * 4, edges: edges)
                    
                    totalCPoints = totalCPoints.map({partRotation.normalized.act($0)})
                    
                    lastForward = partRotation.normalized.act(lastForward)
                }
                self.individualTrueNormals = trueNormals
                self.individualTrueUVMap = trueUVMap
                self.individualTrueVs = trueVs
                self.lineLength = lineLength
                self.lastLocation = lastLocation
                self.cPoints = totalCPoints
                self.lastForward = lastForward
                self.indices = trueInds
                return
            }
        }
        
        totalCPoints = totalCPoints.map({halfRotation.normalized.act($0)})
        lastForward = halfRotation.normalized.act(lastForward)
        
        totalTrueNormals.append(contentsOf: totalCPoints.map({$0.normalized()}))
        trueNormals.append(contentsOf: totalCPoints.map({$0.normalized()}))
        
        totalTrueVs.append(contentsOf: totalCPoints.map({$0 + vector}))
        trueVs.append(contentsOf: totalCPoints.map({$0 + vector}))
        
        lineLength += CGFloat(lastLocation.distance(to: vector))
        lastLocation = vector
        
        totalTrueUVMap.append(contentsOf: textureXs.map({CGPoint(x: $0, y: lineLength)}))
        trueUVMap.append(contentsOf: textureXs.map({CGPoint(x: $0, y: lineLength)}))
        
        SCNLineNodeVector.addCylinderVerts(to: &trueInds, startingAt: totalTrueVs.count - edges * 4, edges: edges)
        SCNLineNodeVector.addCylinderVerts(to: &totalTrueInds, startingAt: totalTrueVs.count - edges * 4, edges: edges)
        
        totalCPoints = totalCPoints.map({halfRotation.normalized.act($0)})
        cPoints = totalCPoints.map({halfRotation.normalized.act($0)})
        
        lastForward = halfRotation.normalized.act(lastForward)
        
        self.individualTrueNormals = trueNormals
        self.individualTrueUVMap = trueUVMap
        self.individualTrueVs = trueVs
        self.lineLength = lineLength
        self.lastLocation = lastLocation
        self.cPoints = cPoints
        self.lastForward = lastForward
        self.indices = trueInds
    }
    
    private func rotationBetween2Vectors(start: SCNVector3, end: SCNVector3) -> simd_quatf {
        return simd_quaternion(simd_float3([start.x, start.y, start.z]), simd_float3([end.x, end.y, end.z]))
    }
    
    func change(to type:VectorType,
                previousVector:SCNLineNodeVector,
                edges:Int,
                radius:Float,
                maxTurning:Int,
                totalTrueNormals:[SCNVector3],
                totalTrueVs:[SCNVector3],
                totalTrueUVMap:[CGPoint],
                totalTrueInds:[UInt32],
                totalCPoints:[SCNVector3],
                totalLineLength:CGFloat,
                nextVector:SCNVector3?) {
        
        switch type {
        case .first:
            return
        case .middle:
            guard let nextVector = nextVector else {return}
            setMiddle(previousVector: previousVector,
                      edges:edges,
                      radius:radius,
                      maxTurning:maxTurning,
                      totalTrueNormals:totalTrueNormals,
                      totalTrueVs:totalTrueVs,
                      totalTrueUVMap:totalTrueUVMap,
                      totalTrueInds:totalTrueInds,
                      totalCPoints:totalCPoints,
                      totalLineLength:totalLineLength,
                      nextVector: nextVector)
        case .last:
            setLast(previousVector: previousVector,
                    edges:edges,
                    radius:radius,
                    maxTurning:maxTurning,
                    totalTrueNormals:totalTrueNormals,
                    totalTrueVs:totalTrueVs,
                    totalTrueUVMap:totalTrueUVMap,
                    totalTrueInds:totalTrueInds,
                    totalCPoints:totalCPoints,
                    totalLineLength:totalLineLength)
        }
        self.vectorType = type
    }
    
    func setLast(previousVector:SCNLineNodeVector,
                 edges:Int,
                 radius:Float,
                 maxTurning:Int,
                 totalTrueNormals:[SCNVector3],
                 totalTrueVs:[SCNVector3],
                 totalTrueUVMap:[CGPoint],
                 totalTrueInds:[UInt32],
                 totalCPoints:[SCNVector3],
                 totalLineLength:CGFloat) {
        let newRotation = simd_quatf(angle: 0, axis: SIMD3<Float>([1, 0, 0]))
        
        var totalTrueNormals = totalTrueNormals
        var totalTrueVs = totalTrueVs
        var totalTrueUVMap = totalTrueUVMap
        var totalTrueInds = totalTrueInds
        var totalLineLength = totalLineLength
        var totalCPoints = totalCPoints
        
        var trueNormals = [SCNVector3]()
        var trueVs = [SCNVector3]()
        var trueUVMap = [CGPoint]()
        var trueInds = [UInt32]()
        var cPoints = [SCNVector3]()
        
        var lineLength:CGFloat = 0
        
        var lastLocation = previousVector.lastLocation
        var lastForward = previousVector.lastForward
        
        let cPointsInitial = SCNGeometry.getCircularPoints(radius: radius, edges: edges)
        let textureXs = cPointsInitial.enumerated().map({val -> CGFloat in
            return CGFloat(val.offset) / CGFloat(edges - 1)
        })
        
        let halfRotation = newRotation.split(by: 2)
        
        if vector.distance(to: previousVector.vector) > (radius * 2) {
            let mTurn = max(1, min(newRotation.angle / .pi, 1) * Float(maxTurning))
            if mTurn > 1 {
                let partRotation = newRotation.split(by: Float(mTurn))
                let halfForward = newRotation.split(by: 2).act(lastForward)
                for i in 0..<Int(mTurn) {
                    
                    totalTrueNormals.append(contentsOf: totalCPoints.map({$0.normalized()}))
                    trueNormals.append(contentsOf: totalCPoints.map({$0.normalized()}))
                    
                    let angleProgress = Float(i) / Float(mTurn - 1) - 0.5
                    let tangle = radius * angleProgress
                    let nextLocation = vector + (halfForward.normalized() * tangle)
                    
                    totalLineLength += CGFloat(lastLocation.distance(to: nextLocation))
                    lineLength += CGFloat(lastLocation.distance(to: nextLocation))
                    
                    lastLocation = nextLocation
                    
                    totalTrueVs.append(contentsOf: totalCPoints.map({$0 + nextLocation}))
                    trueVs.append(contentsOf: totalCPoints.map({$0 + nextLocation}))
                    
                    totalTrueUVMap.append(contentsOf: textureXs.map ({ CGPoint(x: $0, y: lineLength) }))
                    trueUVMap.append(contentsOf: textureXs.map ({ CGPoint(x: $0, y: lineLength) }))
                    
                    SCNLineNodeVector.addCylinderVerts(to: &trueInds, startingAt: totalTrueVs.count - edges * 4, edges: edges)
                    SCNLineNodeVector.addCylinderVerts(to: &totalTrueInds, startingAt: totalTrueVs.count - edges * 4, edges: edges)
                    
                    totalCPoints = totalCPoints.map({partRotation.normalized.act($0)})
                    
                    lastForward = partRotation.normalized.act(lastForward)
                }
                self.individualTrueNormals = trueNormals
                self.individualTrueUVMap = trueUVMap
                self.individualTrueVs = trueVs
                self.lineLength = lineLength
                self.lastLocation = lastLocation
                self.cPoints = totalCPoints
                self.lastForward = lastForward
                self.indices = trueInds
                return
            }
        }
        
        totalCPoints = totalCPoints.map({halfRotation.normalized.act($0)})
        lastForward = halfRotation.normalized.act(lastForward)
        
        totalTrueNormals.append(contentsOf: totalCPoints.map({$0.normalized()}))
        trueNormals.append(contentsOf: totalCPoints.map({$0.normalized()}))
        
        totalTrueVs.append(contentsOf: totalCPoints.map({$0 + vector}))
        trueVs.append(contentsOf: totalCPoints.map({$0 + vector}))
        
        lineLength += CGFloat(lastLocation.distance(to: vector))
        lastLocation = vector
        
        totalTrueUVMap.append(contentsOf: textureXs.map({CGPoint(x: $0, y: lineLength)}))
        trueUVMap.append(contentsOf: textureXs.map({CGPoint(x: $0, y: lineLength)}))
        
        SCNLineNodeVector.addCylinderVerts(to: &trueInds, startingAt: totalTrueVs.count - edges * 4, edges: edges)
        SCNLineNodeVector.addCylinderVerts(to: &totalTrueInds, startingAt: totalTrueVs.count - edges * 4, edges: edges)
        
        totalCPoints = totalCPoints.map({halfRotation.normalized.act($0)})
        cPoints = totalCPoints.map({halfRotation.normalized.act($0)})
        
        lastForward = halfRotation.normalized.act(lastForward)
        
        self.individualTrueNormals = trueNormals
        self.individualTrueUVMap = trueUVMap
        self.individualTrueVs = trueVs
        self.lineLength = lineLength
        self.lastLocation = lastLocation
        self.cPoints = cPoints
        self.lastForward = lastForward
        self.indices = trueInds
        
    }
    
    func setMiddle(previousVector:SCNLineNodeVector,
                   edges:Int,
                   radius:Float,
                   maxTurning:Int,
                   totalTrueNormals:[SCNVector3],
                   totalTrueVs:[SCNVector3],
                   totalTrueUVMap:[CGPoint],
                   totalTrueInds:[UInt32],
                   totalCPoints:[SCNVector3],
                   totalLineLength:CGFloat,
                   nextVector:SCNVector3) {

        var totalTrueNormals = totalTrueNormals
        var totalTrueVs = totalTrueVs
        var totalTrueUVMap = totalTrueUVMap
        var totalTrueInds = totalTrueInds
        var totalLineLength = totalLineLength
        var totalCPoints = totalCPoints
        var lastForward = previousVector.lastForward
        
        var trueNormals = [SCNVector3]()
        var trueVs = [SCNVector3]()
        var trueUVMap = [CGPoint]()
        var trueInds = [UInt32]()
        var cPoints = [SCNVector3]()
        
        var lineLength:CGFloat = 0
        
        var lastLocation = previousVector.vector
        
        let textureXs = self.getTextureXs(radius: radius, edges: edges)
        
        let v = totalTrueVs[(totalTrueVs.count - edges * 2)...]
        let u = Array(v)
        
        totalTrueVs.append(contentsOf: u)
        totalTrueUVMap.append(contentsOf: Array(totalTrueUVMap[(totalTrueUVMap.count - edges * 2)...]))
        totalTrueNormals.append(contentsOf: totalCPoints.map({$0.normalized()}))
        
        let newRotation = rotationBetween2Vectors(start: lastForward, end: (nextVector - self.vector.normalized()))
        
        let halfRotation = newRotation.split(by: 2)
        
        if vector.distance(to: previousVector.vector) > (radius * 2) {
            let mTurn = max(1, min(newRotation.angle / .pi, 1) * Float(maxTurning))
            if mTurn > 1 {
                let partRotation = newRotation.split(by: Float(mTurn))
                let halfForward = newRotation.split(by: 2).act(lastForward)
                for i in 0..<Int(mTurn) {
                    
                    totalTrueNormals.append(contentsOf: totalCPoints.map({$0.normalized()}))
                    trueNormals.append(contentsOf: totalCPoints.map({$0.normalized()}))
                    
                    let angleProgress = Float(i) / Float(mTurn - 1) - 0.5
                    let tangle = radius * angleProgress
                    let nextLocation = vector + (halfForward.normalized() * tangle)
                    
                    totalLineLength += CGFloat(lastLocation.distance(to: nextLocation))
                    lineLength += CGFloat(lastLocation.distance(to: nextLocation))
                    
                    lastLocation = nextLocation
                    
                    totalTrueVs.append(contentsOf: totalCPoints.map({$0 + nextLocation}))
                    trueVs.append(contentsOf: totalCPoints.map({$0 + nextLocation}))
                    
                    totalTrueUVMap.append(contentsOf: textureXs.map ({ CGPoint(x: $0, y: lineLength) }))
                    trueUVMap.append(contentsOf: textureXs.map ({ CGPoint(x: $0, y: lineLength) }))
                    
                    addCylinderVerts(to: &totalTrueInds, startingAt: totalTrueVs.count - edges * 4, edges: edges)
                    
                    totalCPoints = totalCPoints.map({partRotation.normalized.act($0)})
                    
                    lastForward = partRotation.normalized.act(lastForward)
                }
                self.individualTrueNormals = trueNormals
                self.individualTrueUVMap = trueUVMap
                self.individualTrueVs = trueVs
                self.lineLength = lineLength
                self.lastLocation = lastLocation
                self.cPoints = totalCPoints
                self.lastForward = lastForward
                self.indices = totalTrueInds
                return
            }
        }
        
        totalCPoints = totalCPoints.map({halfRotation.normalized.act($0)})
        lastForward = halfRotation.normalized.act(lastForward)
        
        totalTrueNormals.append(contentsOf: totalCPoints.map({$0.normalized()}))
        trueNormals.append(contentsOf: totalCPoints.map({$0.normalized()}))
        
        totalTrueVs.append(contentsOf: totalCPoints.map({$0 + vector}))
        trueVs.append(contentsOf: totalCPoints.map({$0 + vector}))
        
        lineLength += CGFloat(lastLocation.distance(to: vector))
        lastLocation = vector
        
        totalTrueUVMap.append(contentsOf: textureXs.map({CGPoint(x: $0, y: lineLength)}))
        trueUVMap.append(contentsOf: textureXs.map({CGPoint(x: $0, y: lineLength)}))
        
        addCylinderVerts(to: &trueInds, startingAt: totalTrueVs.count - edges * 4, edges: edges)
        addCylinderVerts(to: &totalTrueInds, startingAt: totalTrueVs.count - edges * 4, edges: edges)
        
        totalCPoints = totalCPoints.map({halfRotation.normalized.act($0)})
        cPoints = totalCPoints.map({halfRotation.normalized.act($0)})
        
        lastForward = halfRotation.normalized.act(lastForward)
        
        self.individualTrueNormals = trueNormals
        self.individualTrueUVMap = trueUVMap
        self.individualTrueVs = trueVs
        self.lineLength = lineLength
        self.lastLocation = lastLocation
        self.cPoints = cPoints
        self.lastForward = lastForward
        self.indices = trueInds
    }
    
    static private func addCylinderVerts(
        to array: inout [UInt32], startingAt: Int, edges: Int
    ) {
        for i in 0..<edges {
            let fourI = 2 * i + startingAt
            let rv = Int(edges * 2)
            array.append(UInt32(1 + fourI + rv))
            array.append(UInt32(1 + fourI))
            array.append(UInt32(0 + fourI))
            array.append(UInt32(0 + fourI))
            array.append(UInt32(0 + fourI + rv))
            array.append(UInt32(1 + fourI + rv))
        }
        
    }
    
    private func getTextureXs(radius:Float, edges:Int) -> [CGFloat] {
        let cPoints = SCNGeometry.getCircularPoints(radius: radius, edges: edges)
        let textureXs = cPoints.enumerated().map { (val) -> CGFloat in
            return CGFloat(val.offset) / CGFloat(edges - 1)
        }
        return textureXs
    }
    
    func addCylinderVerts(
        to array: inout [UInt32], startingAt: Int, edges: Int
    ) {
        for i in 0..<edges {
            let fourI = 2 * i + startingAt
            let rv = Int(edges * 2)
            array.append(UInt32(1 + fourI + rv))
            array.append(UInt32(1 + fourI))
            array.append(UInt32(0 + fourI))
            array.append(UInt32(0 + fourI))
            array.append(UInt32(0 + fourI + rv))
            array.append(UInt32(1 + fourI + rv))
        }
    }
}

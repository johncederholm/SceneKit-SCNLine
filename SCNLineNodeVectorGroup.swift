//
//  SCNLineNodeVectorGroup.swift
//  Wunderdraw
//
//  Created by John Cederholm on 8/10/20.
//  Copyright © 2020 d2i LLC. All rights reserved.
//

import Foundation
import SceneKit

class SCNLineNodeVectorGroup {
    
    private var vectors:[SCNLineNodeVector] = []
    
    private var trueVs:[SCNVector3] = []
    private var trueNormals:[SCNVector3] = []
    private var trueUVMap:[CGPoint] = []
    private var trueIndices:[UInt32] = []
    private var lineLength:CGFloat = 0
    private var cPoints:[SCNVector3] = []
    
    private let firstVector:SCNVector3
    private let edges:Int
    private var radius:Float
    private let maxTurning:Int
    
    init(firstVector:SCNVector3, edges:Int, radius:Float, maxTurning:Int) {
        self.firstVector = firstVector
        self.edges = edges
        self.radius = radius
        self.maxTurning = maxTurning
    }
    
    public func changeRadius(newRadius:Float) {
        self.radius = newRadius
    }
    
    private func popTrueNormals(normals:[SCNVector3], oldValue:SCNLineNodeVector) -> [SCNVector3] {
        var trueNormals = normals
        if oldValue.individualTrueNormals.count > 0 {
            trueNormals.removeSubrange(normals.count - oldValue.individualTrueNormals.count..<normals.count)
        }
        return trueNormals
    }
    
    private func popTrueVs(vs:[SCNVector3], oldValue:SCNLineNodeVector) -> [SCNVector3] {
        var trueVs = vs
        if oldValue.individualTrueVs.count > 0 {
            trueVs.removeSubrange(vs.count - oldValue.individualTrueVs.count..<vs.count)
        }
        return trueVs
    }
    
    private func popTrueUVMap(uvMap:[CGPoint], oldValue:SCNLineNodeVector) -> [CGPoint] {
        var trueUVMap = uvMap
        if oldValue.individualTrueUVMap.count > 0 {
            trueUVMap.removeSubrange(uvMap.count - oldValue.individualTrueUVMap.count..<uvMap.count)
        }
        return trueUVMap
    }
    
    private func popTrueIndices(indices:[UInt32], oldValue:SCNLineNodeVector) -> [UInt32] {
        var trueIndices = indices
        if oldValue.indices.count > 0 {
            let oldValueInd = indices.count - oldValue.indices.count >= 0 ? indices.count - oldValue.indices.count : 0
            trueIndices.removeSubrange(oldValueInd..<indices.count)
        }
        return trueIndices
    }
    
    public func add(vector:SCNVector3) {
        if self.vectors.count == 0 {
            if self.firstVector == vector {return}
            let newVector = SCNLineNodeVector(first: self.firstVector, second: vector, radius: self.radius, edges: self.edges)
            self.trueVs.append(contentsOf: newVector.individualTrueVs)
            self.trueNormals.append(contentsOf: newVector.individualTrueNormals)
            self.trueUVMap.append(contentsOf: newVector.individualTrueUVMap)
            self.trueIndices.append(contentsOf: newVector.indices)
            self.lineLength += newVector.lineLength
            self.cPoints = newVector.cPoints
            self.vectors.append(newVector)
        }
        
        guard let previousVector = self.vectors.last else {return}
        
        if self.vectors.count < 2 {
            let newVector = SCNLineNodeVector(last: vector,
                                              previousVector: previousVector,
                                              edges: self.edges,
                                              radius: self.radius,
                                              maxTurning: self.maxTurning,
                                              totalTrueNormals: self.trueNormals,
                                              totalTrueVs: self.trueVs,
                                              totalTrueUVMap: self.trueUVMap,
                                              totalTrueInds: self.trueIndices,
                                              totalCPoints: self.cPoints,
                                              totalLineLength: self.lineLength)
            
            self.trueVs.append(contentsOf: newVector.individualTrueVs)
            self.trueNormals.append(contentsOf: newVector.individualTrueNormals)
            self.trueUVMap.append(contentsOf: newVector.individualTrueUVMap)
            self.trueIndices.append(contentsOf: newVector.indices)
            self.lineLength += newVector.lineLength
            self.cPoints = newVector.cPoints
            
            self.vectors.append(newVector)
            return
        } else {
            if !self.vectors.indices.contains(self.vectors.count - 2) {return}
            
            let secondVector = self.vectors[self.vectors.count - 2]
            
            self.trueVs = self.popTrueVs(vs: self.trueVs, oldValue: previousVector)
            self.trueNormals = self.popTrueNormals(normals: self.trueNormals, oldValue: previousVector)
            self.trueUVMap = self.popTrueUVMap(uvMap: self.trueUVMap, oldValue: previousVector)
            self.trueIndices = self.popTrueIndices(indices: self.trueIndices, oldValue: previousVector)
            
            self.lineLength -= previousVector.lineLength
            self.cPoints = secondVector.cPoints
            
            
            
            previousVector.change(to: .middle,
                                  previousVector: secondVector,
                                  edges: self.edges,
                                  radius: self.radius,
                                  maxTurning: self.maxTurning,
                                  totalTrueNormals: self.trueNormals,
                                  totalTrueVs: self.trueVs,
                                  totalTrueUVMap: self.trueUVMap,
                                  totalTrueInds: self.trueIndices,
                                  totalCPoints: self.cPoints,
                                  totalLineLength: self.lineLength,
                                  nextVector: vector)
            
            self.trueVs.append(contentsOf: previousVector.individualTrueVs)
            self.trueNormals.append(contentsOf: previousVector.individualTrueNormals)
            self.trueUVMap.append(contentsOf: previousVector.individualTrueUVMap)
            self.trueIndices.append(contentsOf: previousVector.indices)
            self.lineLength += previousVector.lineLength
            self.cPoints = previousVector.cPoints
            
            let newVector = SCNLineNodeVector(last: vector,
                                              previousVector: previousVector,
                                              edges: self.edges,
                                              radius: self.radius,
                                              maxTurning: self.maxTurning,
                                              totalTrueNormals: self.trueNormals,
                                              totalTrueVs: self.trueVs,
                                              totalTrueUVMap: self.trueUVMap,
                                              totalTrueInds: self.trueIndices,
                                              totalCPoints: self.cPoints,
                                              totalLineLength: self.lineLength)
            
            self.trueVs.append(contentsOf: newVector.individualTrueVs)
            self.trueNormals.append(contentsOf: newVector.individualTrueNormals)
            self.trueUVMap.append(contentsOf: newVector.individualTrueUVMap)
            self.trueIndices.append(contentsOf: newVector.indices)
            self.lineLength += newVector.lineLength
            self.cPoints = newVector.cPoints
            self.vectors.append(newVector)
        }
    }
    
    public func remove(vectors:Int) {
        for _ in 0..<vectors {
            if self.vectors.count <= 0 {
                return
            } else if self.vectors.count == 1 {
                self.vectors.removeAll()
                return
            } else if self.vectors.count == 2 {
                self.vectors.remove(at: 1)
                continue
            } else {
                guard let vector = self.vectors.last else {continue}
                if !self.vectors.indices.contains(self.vectors.count - 2) {continue}
                if !self.vectors.indices.contains(self.vectors.count - 3) {continue}
                let secondVector = self.vectors[self.vectors.count - 2]
                let thirdVector = self.vectors[self.vectors.count - 3]

                self.trueVs = self.popTrueVs(vs: self.trueVs, oldValue: vector)
                self.trueNormals = self.popTrueNormals(normals: self.trueNormals, oldValue: vector)
                self.trueUVMap = self.popTrueUVMap(uvMap: self.trueUVMap, oldValue: vector)
                self.trueIndices = self.popTrueIndices(indices: self.trueIndices, oldValue: vector)
                
                self.lineLength -= vector.lineLength
                self.cPoints = secondVector.cPoints
                
                self.trueVs = self.popTrueVs(vs: self.trueVs, oldValue: secondVector)
                self.trueNormals = self.popTrueNormals(normals: self.trueNormals, oldValue: secondVector)
                self.trueUVMap = self.popTrueUVMap(uvMap: self.trueUVMap, oldValue: secondVector)
                self.trueIndices = self.popTrueIndices(indices: self.trueIndices, oldValue: secondVector)
                
                self.lineLength -= secondVector.lineLength
                self.cPoints = thirdVector.cPoints
                
                secondVector.change(to: .last,
                                    previousVector: thirdVector,
                                    edges: self.edges,
                                    radius: self.radius,
                                    maxTurning: self.maxTurning,
                                    totalTrueNormals: self.trueNormals,
                                    totalTrueVs: self.trueVs,
                                    totalTrueUVMap: self.trueUVMap,
                                    totalTrueInds: self.trueIndices,
                                    totalCPoints: self.cPoints,
                                    totalLineLength: self.lineLength,
                                    nextVector: nil)
                
                self.trueVs.append(contentsOf: secondVector.individualTrueVs)
                self.trueNormals.append(contentsOf: secondVector.individualTrueNormals)
                self.trueUVMap.append(contentsOf: secondVector.individualTrueUVMap)
                self.trueIndices.append(contentsOf: secondVector.indices)
                self.lineLength += secondVector.lineLength
                self.cPoints = secondVector.cPoints
                
                self.vectors.removeLast()
            }
        }
    }
    
    public func getGeometryParts() -> (GeometryParts, CGFloat) {
        return (GeometryParts(vertices: self.trueVs, normals: self.trueNormals, uvs: self.trueUVMap, indices: self.trueIndices), self.lineLength)
    }
    
}

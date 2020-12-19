//
//  SCNLineNode.swift
//  SCNLine
//
//  Created by Max Cobb on 1/23/19.
//  Copyright © 2019 Max Cobb. All rights reserved.
//

import SceneKit

public class SCNLineNode: SCNNode {
    
    private var vertices = [SCNVector3]()
    
    public private(set) var length:CGFloat = 0
    
    var points: [SCNVector3] {
        didSet {
            if oldValue.count > self.points.count {
                self.removed(vectors: oldValue.count - self.points.count)
            } else {
                guard let v = self.points.last else {return}
                self.added(newValue: v)
            }
        }
    }
    
    public var radius: Float {
        didSet {
            self.nodeGroup?.changeRadius(newRadius: self.radius)
//            self.performUpdate()
        }
    }
    
    public var edges: Int {
        didSet {
            self.performUpdate()
        }
    }
    
    public var lineMaterials = [SCNMaterial()]
    
    public var maxTurning: Int {
        didSet {
            self.performUpdate()
        }
    }
    
    public private(set) var gParts: GeometryParts?
    
    /// Initialiser for a SCNLineNode
    ///
    /// - Parameters:
    ///   - points: array of points to be joined up to form the line
    ///   - radius: radius of the line
    ///   - edges: number of edges around the line/tube at every point
    ///   - maxTurning: multiplier to dictate how smooth the turns should be
    private var nodeGroup:SCNLineNodeVectorGroup!
    
    public init(with points: [SCNVector3] = [], radius: Float = 1, edges: Int = 12, maxTurning: Int = 4) {
        self.points = points
        self.radius = radius
        self.edges = edges
        self.maxTurning = maxTurning
        super.init()
        if !points.isEmpty {
            let (geomParts, len) = SCNGeometry.getAllLineParts(
                points: points, radius: radius,
                edges: edges, maxTurning: maxTurning
            )
            self.gParts = geomParts
            self.geometry = geomParts.buildGeometry()
            self.length = len
        }
    }
    
    /// Add a point to the collection for this SCNLineNode
    ///
    /// - Parameter point: point to be added to the line
    public func add(point: SCNVector3, withPrevious:SCNVector3?) {
        // TODO: optimise this function to not recalculate all points
        if let withPrevious = withPrevious {
            self.points.append(withPrevious)
        }
        self.points.append(point)
    }
    
    public func remove(numberOfPoints:Int) {
        if self.points.count >= 10 {
            if self.points.count < numberOfPoints {
                self.points.removeLast(self.points.count)
            } else {
                self.points.removeLast(numberOfPoints)
            }
        } else if points.count > 0 {
            self.points.removeAll()
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func added(newValue:SCNVector3) {
        if points.count > 1 {
            if self.nodeGroup == nil {
                self.nodeGroup = SCNLineNodeVectorGroup(firstVector: newValue, edges: self.edges, radius: self.radius, maxTurning: self.maxTurning)
            } else {
                self.nodeGroup.add(vector: newValue)
            }
            
            let (geomParts, len) = self.nodeGroup.getGeometryParts()
            
            self.gParts = geomParts
            self.geometry = geomParts.buildGeometry()
            self.geometry?.materials = self.lineMaterials
            self.length = len
        } else {
            self.geometry = nil
            self.length = 0
        }
    }
    
    private func performUpdate() {
        if points.count > 1 {
            let (geomParts, len) = self.nodeGroup.getGeometryParts()
            
            self.gParts = geomParts
            self.geometry = geomParts.buildGeometry()
            self.geometry?.materials = self.lineMaterials
            self.length = len
        } else {
            self.geometry = nil
            self.length = 0
        }
    }
    
    private func removed(vectors:Int) {
        if points.count > 1 {
            self.nodeGroup.remove(vectors: vectors)
            
            let (geomParts, len) = self.nodeGroup.getGeometryParts()
            
            self.gParts = geomParts
            self.geometry = geomParts.buildGeometry()
            self.geometry?.materials = self.lineMaterials
            self.length = len
        } else {
            self.geometry = nil
            self.length = 0
        }
    }
    
    private func getlastAverages() -> SCNVector3 {
        let len = self.gParts!.vertices.count - 1
        let lastPoints = self.gParts?.vertices[(len - self.edges * 4)...(len - self.edges * 2)]
        let avg = lastPoints!.reduce(SCNVector3Zero, { (total, npoint) -> SCNVector3 in
            return total + npoint
        }) / Float(self.edges * 2)
        return avg
    }
}

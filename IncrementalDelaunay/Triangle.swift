//
//  Triangle.swift
//  Polygo
//
//  Created by Luiz Veloso on 23/03/18.
//  Copyright © 2018 Luiz Veloso. All rights reserved.
//

import UIKit

class Triangle {
    fileprivate let _vertexes: [CGPoint]
    
    var vertexes: Set<CGPoint> = [] //Could use a computed property but my main goal is reduce possible little overhead. For when I had thousands of points.
    let edges: Set<Edge>
    
    var active: Bool = false
    
    var path: CGPath!
    
    var tag: Int = 0
    
    init(edges: Set<Edge>) {
        self.edges = edges
        
        for edge in edges {
            self.vertexes.formUnion(edge.vertexes)
        }

        
        self._vertexes = Array(self.vertexes)

        let _path = CGMutablePath()
            
        _path.move(to:     _vertexes[0])
        _path.addLine(to:  _vertexes[1])
        _path.addLine(to:  _vertexes[2])
        _path.addLine(to:  _vertexes[0])
        _path.closeSubpath()
        
        path = _path
        
        guard edges.count == 3 || vertexes.count == 3  else {
            fatalError("You are shure that \(edges) make a triangle?")
        }
    }
    

    func oppositeEdge(from vertex: Vertex) -> Edge {
        guard vertexes.contains(vertex) else {
            fatalError("This vertex doesn't belong to this triangle.")
        }
        
        for edge in edges {
            if !edge.vertexes.contains(vertex) {
                return edge
            }
        }
    
        fatalError("It should have one opposite edge. 🤕")
    }
    
    
    func oppositeTriangle(from edge: Edge) -> Triangle? {
        return edge.oppositeTriangle(from: self)
    }

    
    func oppositeTriangle(from vertex: Vertex) -> Triangle? {
        let edge = self.oppositeEdge(from: vertex)
        let triangle = self.oppositeTriangle(from: edge)
        return triangle
    } //😬

    
    func oppositeVertex(from edge: Edge) -> Vertex {
        guard edges.contains(edge) else {
            fatalError("This edge doesn't belong to this triangle.")
        }
        
        return vertexes.subtracting(edge.vertexes).first!

    }
    
    func contains(vertex: Vertex) -> Bool {
        return self.path.contains(vertex)
    }
    
    func add() {
       // print(String(format: "TRIANGLE ADD: A:(%.9f, %.9f) B:(%.9f, %.0f) C:(%.9f, %.9f)", self._vertexes[0].x, self._vertexes[0].y, self._vertexes[1].x, self._vertexes[1].y, self._vertexes[2].x, self._vertexes[2].y))
        for edge in edges {
            edge.insertAdjacent(triangle: self)
        }
        self.active = true
        DelaunayTriangulation.triangles.insert(self)
    }
    
    func destroy() {
       // print(String(format: "TRIANGLE REMOVE: A:(%.9f, %.9f) B:(%.9f, %.0f) C:(%.9f, %.9f)", self._vertexes[0].x, self._vertexes[0].y, self._vertexes[1].x, self._vertexes[1].y, self._vertexes[2].x, self._vertexes[2].y))
        for edge in self.edges {
            edge.removeAdjacent(triangle: self)
        }
        self.active = false
        DelaunayTriangulation.triangles.remove(self)
    }

//    // ♥️ Learned from this great explanation of baricentric coordinates: http://blackpawn.com/texts/pointinpoly/
//    func baricentricDirections(to destination: CGPoint) -> (triangle: Triangle, success: Bool) {
//        let _v = self.vertexes
//
//
//        let A = _v.first!
//        let B = _v.dropFirst().first!
//        let C = _v.dropFirst().dropFirst().first!
//
//        let v0 = C - A
//        let v1 = B - A
//        let v2 = destination - A
//
//        let dot00 = Double(v0 * v0)
//        let dot01 = Double(v0 * v1)
//        let dot02 = Double(v0 * v2)
//        let dot11 = Double(v1 * v1)
//        let dot12 = Double(v1 * v2)
//
//
//       // let u1 = Double(v1*v1) * Double(v2*v0) - Double(v1*v0) * Double(v2*v1)
//       // let w1 = Double(v0*v0) * Double(v2*v1) - Double(v0*v1) * Double(v2*v0)
//       // let denominator = Double(v0*v0) * Double(v1*v1) - Double(v0*v1) * Double(v1*v0)
//       // let u = u1/denominator //direction AC
//       // let v = w1/denominator //direction AB
//
//        let invDenom: Double = 1 / (dot00 * dot11 - dot01 * dot01)
//
//        let u = (dot11 * dot02 - dot01 * dot12) * invDenom
//        let v = (dot00 * dot12 - dot01 * dot02) * invDenom
//
//
//        let colinear = abs(A.x * (B.y - C.y) + B.x * (C.y - A.y) + C.x * (A.y - B.y)) < 0.0001
//
////        //if u < 0,
////        print("\nTRIANGLE: A:\(A),B:\(B),C:\(C)")
////        print("u: \(u)")
////        print("v: \(v)")
////        print(String(format: "u+v: %.30f", u+v))
////        print("u >= 0: \(u >= 0)")
////        print("v >= 0: \(v >= 0)")
////        print("u+v <= 1: \(u+v <= 0)")
////
////        print("destination \(destination)")
////
//        if u >= -Double.ulpOfOne && v >= -Double.ulpOfOne && u+v <= 1+Double.ulpOfOne {
//            return (triangle: self, success: true)
//        } else if colinear {
//            return (triangle: self.oppositeTriangle(from: self._vertexes[Int(arc4random_uniform(3))])!, success: false)
//        } else if u >= -Double.ulpOfOne && v >= -Double.ulpOfOne && u+v > 1+Double.ulpOfOne {
//            return (triangle: self.oppositeTriangle(from: A)!, success: false)
//        } else if u < -Double.ulpOfOne {
//            return (triangle: self.oppositeTriangle(from: C)!, success: false)
//        } else { // here will fall only the case where v < 0
//            return (triangle: self.oppositeTriangle(from: B)!, success: false)
//        }
//
//
//
//
//
//    }
//
//
//    func adjacentEdges(from point: CGPoint) -> Set<Edge> {
//        let _edges = self.edges
//
//        return _edges.filter{$0.vertexes.contains(point)}
//
//    }


}

//MARK: - Equatable & Hashble
//To use set and to speed things up.

extension Triangle: Equatable {
    static func == (lhs: Triangle, rhs: Triangle) -> Bool {
        return lhs.vertexes == rhs.vertexes
    }
    
}

///https://developer.apple.com/documentation/swift/hashable
///https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/AdvancedOperators.html
extension Triangle: Hashable {
    var hashValue: Int {
        //Since order doesn't matter for uniqueness here, I believe this way it will do.
        return _vertexes[0].hashValue ^ _vertexes[1].hashValue ^ _vertexes[2].hashValue
    }
}

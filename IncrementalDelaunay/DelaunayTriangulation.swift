//
//  DelaunayTriangulation.swift
//  Polygo
//
//  Created by Luiz Veloso on 19/03/18.
//  Copyright © 2018 Luiz Veloso. All rights reserved.
//
 

// "If you wish to make an apple pie from scratch,
//        you must first invent the universe."
//                                    - Carl Sagan


import Foundation
import UIKit
import Darwin

public typealias Vertex   = CGPoint

/// Implements Delaunay Triangulation incrementally.
/// What is it: https://en.wikipedia.org/wiki/Delaunay_triangulation (19/03/18)
/// How to make it efficient: http://www.karlchenofhell.org/cppswp/lischinski.pdf (19/03/18)
/// The Delaunay Triangulation is an well know heuristic to create a mesh of triangles from a set of points. It's a bit painful to implement, but easy to understand and well know in the trigonometry community. The biggest advantage of a Delaunay Triangulation is that it generate triangles with angles more evenly distributed.
/// This particular implementation will be prepared to receive points in a given area and then will construct the mesh incrementally, point by point.
/// Also, when add new points to the mesh it will rearrange itself.
/// - Author: Luiz Veloso
//  - Date: 19/03/18
public class DelaunayTriangulation {
    
    //MARK: - STATIC VARIABLES
    static var superTriangle: Triangle?
    static var triangles: Set<Triangle> = []
    static var vertexes: Set<Vertex> = []
    
    
    //MARK: - SUPERTRIANGLE
    /// Creates supertriangle to start delaunay's mesh subdivisions inside.
    static func superTriangle(for area: CGRect) -> Triangle {
        
        let w = max(area.width, area.height)
        
        let a = Vertex(x: w*3 , y: 0)
        let b = Vertex(x: 0   , y: w*3)
        let c = Vertex(x: -w*3, y: -w*3)
        
        let edgeAB = Edge(vertexes:[a,b])
        let edgeBC = Edge(vertexes:[b,c])
        let edgeCA = Edge(vertexes:[c,a])

        let superTriangle = Triangle(edges: [edgeAB, edgeBC, edgeCA])
        /*print(String(format: "SUPERTRIANGLE: A:(%.0f, %.0f) B:(%.0f, %.0f) C:(%.0f, %.0f)",
              superTriangle.points[0].x,
              superTriangle.points[0].y,
              superTriangle.points[1].x,
              superTriangle.points[1].y,
              superTriangle.points[2].x,
              superTriangle.points[2].y))*/
        
        DelaunayTriangulation.superTriangle = superTriangle
        DelaunayTriangulation.add(triangle: superTriangle)
        superTriangle.add()
        
        return superTriangle
    }
    
    
    //MARK: - INCREMENTAL DELAUNAY
    static func incrementalDelaunay(vertex: CGPoint) -> (remove: [Triangle], add: [Triangle])? {
    //print("\n\n.............................................................")
        //print("\n\nNEW TOUCH")
     
        
        guard !DelaunayTriangulation.vertexes.contains(vertex) else {
            // print("!: TOUCH ON EXISTING VERTEX")
            return nil
        }
        
        //#1 Try to get the triangle
        guard let triangle = getTouchedTriangle(on: vertex) else {
            //print("!: NO TRIANGLE ON (\(vertex.x),\(vertex.y)) POSITION.")
            return nil // User doesn't touch a triangle.
        }
        
      
        
        //print(String(format: "TOUCH: %.2f,%.2f", vertex.x, vertex.y))
        //print(String(format: "TRIANGLE:  a:(%.2f,%.2f), b:(%.2f,%.2f), c:(%.2f,%.2f)", triangle.points[0].x, triangle.points[0].y, triangle.points[1].x, triangle.points[1].y, triangle.points[2].x, triangle.points[2].y))
        
        //Remove from triangle data array
        DelaunayTriangulation.remove(triangle: triangle)
        triangle.destroy()
        
        //Triangles to be tested
        var triangleCandidates: [Triangle]   = []
        //triangleCandidates.reserveCapacity(3)

        //Triangles to be added to view
        var addTriangles: [Triangle]    = []
        
        //Triangles to be removed from view
        var removeTriangles: [Triangle] = [triangle]
        
        
        //#2 Get Edges
        let edges = triangle.edges

        var newEdges: Set<Edge> = []
            newEdges.reserveCapacity(3)
        
        //print("\n OLD EDGES: \(edges.count)")
        //#3 Create New Edges First, to ensure they will be uniquely referenced.
        for edge in edges {
               // print(String(format: "[E:] (%.1f, %.1f) (%.1f, %.1f)", edge.vertexes.first!.x, edge.vertexes.first!.y, edge.vertexes.dropFirst().first!.x, edge.vertexes.dropFirst().first!.y))

            let edgeA = Edge(vertexes: [vertex, edge.vertexes.dropFirst().first!])
            let edgeB = Edge(vertexes: [vertex, edge.vertexes.dropLast().first!]) // Since it's lenght is two, it's inexpensive
            newEdges.formUnion([edgeA, edgeB])
        }
        
        //for edge in newEdges {
            //print(String(format: "[NE:] (%.1f, %.1f) (%.1f, %.1f)", edge.vertexes.first!.x, edge.vertexes.first!.y, edge.vertexes.dropFirst().first!.x, edge.vertexes.dropFirst().first!.y))
        //}
        
        //print("\nTRIANGLES FROM EDGES:")
        //#4 Now that they are unique, we can reference the same edges in multiple triangles.
        for edge in edges {
            var triangleEdges: Set<Edge> = [edge]
            triangleEdges.reserveCapacity(3)
            
            for newEdge in newEdges {
                if edge.vertexes.intersection(newEdge.vertexes).count == 1 {
                    triangleEdges.insert(newEdge)
                }
            }
            
            guard triangleEdges.count == 3 else {
                fatalError("A triangle ~usually has 3 sides. You'll need to investigate. 🤔")
            }
            
            let candidate = Triangle(edges: triangleEdges)
            candidate.tag = triangle.tag
            DelaunayTriangulation.add(triangle: candidate)
            triangleCandidates.append(candidate)
            candidate.add()
            
            /*print(String(format: "\n[E]:  a:(%.1f, %.1f), b:(%.1f, %.1f)",
                         triangleEdges.dropFirst().first!.vertexes.first!.x,
                         triangleEdges.dropFirst().first!.vertexes.first!.y,
                         triangleEdges.dropLast().first!.vertexes.first!.x,
                         triangleEdges.dropLast().first!.vertexes.first!.y))
            */
            /*print(String(format: "[T CANDIDATE]:  a:(%.1f, %.1f), b:(%.1f, %.1f), c:(%.1f, %.1f)",
                         candidate.points[0].x, candidate.points[0].y, candidate.points[1].x,
                         candidate.points[1].y, candidate.points[2].x, candidate.points[2].y))*/

        } // first triangleCandidates are populated.
        
        
        var counter: Int = 0
        
        //print("\nCHECK TRIANGLES:")
        //#4 Test Candidates
        while (triangleCandidates.count != 0) {
            counter += 1

            //#5 Get next triangle in the test queue, and remove from triangleCandidates.
            let candidate = triangleCandidates.removeFirst()
            candidate.destroy()
           /* print(String(format: "\n[-CANDIDATE %d]:  a:(%.1f, %.1f), b:(%.1f, %.1f), c:(%.1f, %.1f)", counter,
                         candidate.points[0].x, candidate.points[0].y, candidate.points[1].x,
                         candidate.points[1].y, candidate.points[2].x, candidate.points[2].y))*/
            
          //  for edge in candidate.edges {
                //print(String(format: "[--CANDIDATE EDGE:] (%.1f, %.1f) (%.1f, %.1f)", edge.vertexes.first!.x, edge.vertexes.first!.y, edge.vertexes.dropFirst().first!.x, edge.vertexes.dropFirst().first!.y))
          //      for triangle in edge.triangles {
                /*print(String(format: "[--EDGE TRIANGLES]:  a:(%.1f, %.1f), b:(%.1f, %.1f), c:(%.1f, %.1f)",
                             triangle.points[0].x, triangle.points[0].y, triangle.points[1].x,
                             triangle.points[1].y, triangle.points[2].x, triangle.points[2].y))*/
            //    }

           // }
            
            //print("\n-EVALUATION:")
            if self.shareEdgeWithSupertriangle(triangle: candidate) {
                //print("[--CANDIDATE \(counter): OK]: SHARE EDGE WITH SUPER TRIANGLE")
                DelaunayTriangulation.add(triangle: candidate)
                candidate.add()
                addTriangles.append(candidate)
            } else if (self.circunscribeOnly(triangle: candidate, vertex: vertex)) {
                //print("[--CANDIDATE \(counter): OK]: DELAUNAY'S TRIANGLE  [CIRCLE IS EMPTY]")
                DelaunayTriangulation.add(triangle: candidate)
                candidate.add()
                addTriangles.append(candidate)
            } else {
                //print("[--CANDIDATE \(counter): NOT OK]: TRYING TO FLIP")
                let flippedTriangles = flipTriangles(triangle: candidate, vertex: vertex)
                //print("NEW FLIPPED:", flippedTriangles.new.count)
                for tn in flippedTriangles.new {
                    tn.tag = candidate.tag
                    DelaunayTriangulation.add(triangle: tn)
                    //print(String(format: "[---T TEMP CREATED]:  a:(%.1f, %.1f), b:(%.1f, %.1f), c:(%.1f, %.1f)", tn.points[0].x, tn.points[0].y, tn.points[1].x, tn.points[1].y ,tn.points[2].x, tn.points[2].y))

                    triangleCandidates.append(tn)
                    tn.add()
                }
                
                for to in flippedTriangles.old {
                    triangleCandidates = triangleCandidates.filter{$0 != to}
                    removeTriangles.append(to)
                    DelaunayTriangulation.remove(triangle: to)
                    to.destroy()
                    //print(String(format: "[---T REMOVED]:  a:(%.1f, %.1f), b:(%.1f, %.1f), c:(%.1f, %.1f)", to.points[0].x, to.points[0].y, to.points[1].x, to.points[1].y ,to.points[2].x, to.points[2].y))
                }
            
            }
        }
        
        return (remove: removeTriangles, add: addTriangles)
    }
    
    
    static func getTouchedTriangle(on vertex: Vertex) -> Triangle? {
        let triangleSet = DelaunayTriangulation.triangles
        
        guard triangleSet.count != 0 else {
            return nil
        }
        
        for t in triangleSet {
            if t.path.contains(vertex) {
                return t
            }
        }
        
        return nil
        
// FOR BARICENTRIC COORDINATES... not working yet.
//        var triangle = triangleSet.first!
//        var searching = true
//
//        while searching {
//            let compass: (triangle: Triangle, success: Bool) = triangle.baricentricDirections(to: vertex)
//                triangle = compass.triangle
//                searching = !compass.success
//        }
//
//        return triangle
        
    }
    
    
    static func flipTriangles(triangle: Triangle, vertex: Vertex) -> (old: Set<Triangle>, new: Set<Triangle>) {
        var result: (old: Set<Triangle>, new: Set<Triangle>) = (old: [], new: [])
        //add triangle in the old triangles list

        let oldEdge = triangle.oppositeEdge(from: vertex)

        
        if let oppositeTriangle = triangle.oppositeTriangle(from: vertex) {
            
            let oppositeVertex = oppositeTriangle.oppositeVertex(from: oldEdge)

            let newEdge = Edge(vertexes: [vertex, oppositeVertex])
            
            let triangleRemainingEdges = triangle.edges.subtracting([oldEdge])
            let oppositeTriangleRemainingEdges = oppositeTriangle.edges.subtracting([oldEdge])

            //let testEdge = triangleRemainingEdges.popFirst()

            let oldEdgePointA: CGPoint = oldEdge.vertexes.dropFirst().first!
            let oldEdgePointB: CGPoint = oldEdge.vertexes.dropLast().first!
        
            var candidateTriangleAEdges: Set<Edge> = [newEdge]
            var candidateTriangleBEdges: Set<Edge> = [newEdge]
            
            for tEdge in triangleRemainingEdges {
                if tEdge.vertexes.contains(oldEdgePointA) {
                    candidateTriangleAEdges.insert(tEdge)
                } else if tEdge.vertexes.contains(oldEdgePointB) {
                    candidateTriangleBEdges.insert(tEdge)
                }
            }
            
            for otEdge in oppositeTriangleRemainingEdges {
                if otEdge.vertexes.contains(oldEdgePointA) {
                    candidateTriangleAEdges.insert(otEdge)
                } else if otEdge.vertexes.contains(oldEdgePointB) {
                    candidateTriangleBEdges.insert(otEdge)
                }
            }
            
            let candidateTriangleA = Triangle(edges: candidateTriangleAEdges)
            let candidateTriangleB = Triangle(edges: candidateTriangleBEdges)
            
            
            result.new.insert(candidateTriangleA)
            result.new.insert(candidateTriangleB)
            
            result.old.insert(oppositeTriangle)
            result.old.insert(triangle)
            
            
        } else {
            fatalError("👮: No Opposite Triangle. If it's adjacent to border, should have been filtered earlier.")
        }
        
        return result
    }
    
    //CHECK IF IS INSIDE CIRCLE: https://stackoverflow.com/a/481150/6704959
    static func circunscribeOnly(triangle: Triangle, vertex: Vertex) -> Bool {
        //Draw a circle over triangle
        let circle = createCircle(over: triangle)
        //print(String(format: "CIRCLE: (x:%.2f, y: %.2f, radius: %.2f)", circle.x, circle.y, sqrt(circle.rsqr)))
        //print(String(format: "VERTEX: (x:%.2f, y: %.2f)", vertex.x, vertex.y))

        if let oppositeTriangle = DelaunayTriangulation.getOppositeTriangle(triangle: triangle, vertex: vertex) {
            //If have opposite triangle, do:
            
            let v = oppositeTriangle.vertex
            
            let dx = (v.x - circle.x)*(v.x - circle.x)
            let dy = (v.y - circle.y)*(v.y - circle.y)
            //check if one of the opposite vertex is inside delaunays
            if  (dx + dy < circle.rsqr) {
                //if finds the point inside circle, return false.
                return false
            }
        }
        //else, return true.
        return true
        
        
    }
    
    /* Calculate a circumcircle for a set of 3 vertices */
    static func createCircle(over triangle: Triangle) -> Circle {
        let v1 = triangle.vertexes.first!
        let v2 = triangle.vertexes.dropFirst().first!
        let v3 = triangle.vertexes.dropFirst().dropFirst().first!
        
        let xc: CGFloat
        let yc: CGFloat

        let y1y2 = abs(v1.y - v2.y)
        let y2y3 = abs(v2.y - v3.y)

        if y1y2 < CGFloat.ulpOfOne {
            let m2 = -((v3.x - v2.x) / (v3.y - v2.y))
            let mx2 = (v2.x + v3.x) / 2
            let my2 = (v2.y + v3.y) / 2
            xc = (v2.x + v1.x) / 2
            yc = m2 * (xc - mx2) + my2
    } else if y2y3 < CGFloat.ulpOfOne {
            let m1 = -((v2.x - v1.x) / (v2.y - v1.y))
            let mx1 = (v1.x + v2.x) / 2
            let my1 = (v1.y + v2.y) / 2
            xc = (v3.x + v2.x) / 2
            yc = m1 * (xc - mx1) + my1
        } else {
            let m1 = -((v2.x - v1.x) / (v2.y - v1.y))
            let m2 = -((v3.x - v2.x) / (v3.y - v2.y))
            let mx1 = (v1.x + v2.x) / 2
            let mx2 = (v2.x + v3.x) / 2
            let my1 = (v1.y + v2.y) / 2
            let my2 = (v2.y + v3.y) / 2
            xc = (m1 * mx1 - m2 * mx2 + my2 - my1) / (m1 - m2)
            
            if y1y2 > y2y3 {
                yc = m1 * (xc - mx1) + my1
            } else {
                yc = m2 * (xc - mx2) + my2
            }
        }
        
        let dx = v1.x - xc
        let dy = v1.y - yc
        let rsqr = dx * dx + dy * dy
        
        return Circle(vertexes: triangle.vertexes, x: xc, y: yc, rsqr: rsqr)
    }
    
    
    
    //MARK: SAVE & DELETE
    static func add(triangle: Triangle) {
        DelaunayTriangulation.vertexes.formUnion(triangle.vertexes)
        DelaunayTriangulation.triangles.insert(triangle)
    }
    static func remove(triangle: Triangle) {
        triangle.destroy()
        
    }
    
    
    static func shareEdgeWithSupertriangle(triangle: Triangle) -> Bool {
        let superTriangle = DelaunayTriangulation.superTriangle!
        let superVertexes = triangle.vertexes.intersection(superTriangle.vertexes)
        
        return (superVertexes.count == 2)
    }
    
    static func getOppositeTriangle(triangle: Triangle, vertex: Vertex) -> (triangle: Triangle?, vertex: Vertex)?{
        //find shared edge
        let edge = triangle.oppositeEdge(from: vertex)
        
        let oppositeTriangle = triangle.oppositeTriangle(from: edge)
        let oppositeVertex   = oppositeTriangle!.oppositeVertex(from: edge)
        
        return (triangle: oppositeTriangle, vertex: oppositeVertex)
    }
    
    static func reset() {
        DelaunayTriangulation.triangles = []
        DelaunayTriangulation.vertexes = []
        DelaunayTriangulation.superTriangle = nil
    }
}






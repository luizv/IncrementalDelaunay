//
//  Edge.swift
//  Polygo
//
//  Created by Luiz Veloso on 23/03/18.
//  Copyright © 2018 Luiz Veloso. All rights reserved.
//

import Foundation

class Edge {
    let vertexes: Set<Vertex>!
    var triangles: Set<Triangle> = []

    init(vertexes: Set<Vertex>) {
        guard vertexes.count == 2 else {
            fatalError("You are shure that \(vertexes) make an edge?")
        }
        guard vertexes.count <= 2 else {
            fatalError("An edge can have only one or two triangles. :(")
        }
        self.vertexes = vertexes
    }
    
    func oppositeTriangle(from triangle: Triangle) -> Triangle? {
        let triangle = triangles.subtracting([triangle])
        if triangle.count == 0 {
            return nil //in case it's was boarder triangle
        } else if triangle.count == 1 {
            return triangle.first!
        } else {
            fatalError("Sorry. 🤖 You can't have more than 2 triangles at the same edge.")
        }
    }
    
    func insertAdjacent(triangle: Triangle) {
        self.triangles.insert(triangle)
    }

    func insertAdjacent(triangles: Set<Triangle>) {
        self.triangles.formUnion(triangles)
    }

    func removeAdjacent(triangle: Triangle) {
        self.triangles.remove(triangle)
    }
    
    func removeAdjacent(triangles: Set<Triangle>) {
        self.triangles.subtract(triangles)
    }
}

extension Edge: Equatable {
    static func == (lhs: Edge, rhs: Edge) -> Bool {
        return lhs.vertexes.symmetricDifference(rhs.vertexes).count == 0
    }
}

///https://developer.apple.com/documentation/swift/hashable
///https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/AdvancedOperators.html
extension Edge: Hashable {
    var hashValue: Int {
        //Since order doesn't matter for uniqueness here, I believe this way it will do.
        return vertexes.first!.hashValue ^ vertexes.dropFirst().first!.hashValue
    }
}




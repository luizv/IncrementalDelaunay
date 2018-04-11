# Incremental Delaunay Triangulation
Incremental Delaunay Triangulation implemented in **Swift 4.0**. It a kind-of a math library that implements a 2D Delaunay Triangulation incrementally, one point at time, making it fast to generate a 2D triangle mesh dynamically, with the interaction of users.

>To my knowledge, it's the first open-sourced incremental implementation of this algoritmn for iOS.

>This framework was developed to make the [**Poly World Canvas**](https://www.youtube.com/watch?v=xSDhIO81kHk) app, my submission to the _WWDC 2018 Scholarship_.

---

## Features:
- [x] Adds points and create triangles incrementally;
- [x] Keeps track of all triangles generated;
- [x] At each interaction, keeps track of each created and deleted triangle;
- [x] _Circle_, _Triangle_ &_ Edge_ especialized classes;
- [x] _CGPoint_ typealiased to _Vertex_;
- [x] Intense use of _Set Data Collections_ , to ultraquick compare vertexes, edges and triangles, without looping through each element;
- [x] Reset command;
- [x] MIT Licensed.

## Roadmap:
- [ ] Rename classes (Triangle, Circle, etc) to make difficult to conflict with _user-created-and-named_ objects.
- [ ] _Investigate known bug:_ when vertexes are too close positioned or almost aligned, sometimes triangles appear to be formed violating the delaunay criteria. It's a rare event, probably related to rounding errors while placing points with touch pan gestures to close to one another. Nevertheless it's important to fix. Maybe a simpler fix would be multiply all cartesian plane's coordinates by a big number and make the calculations without incurring in rounding errors;
- [ ] _Implement baricentric coordinates:_ touched triangles are, for now, found by testing each triangle _UIBelzierPath_ `.contains()` function. Performance-wise, it's not the best way of doing this. The best way would be implementing baricentric coordinates. It's already implemented but commented out from main code because the known bug mentioned earlier. Baricentric coordinates needed to have triangles with area different from zero;
- [ ] Create & export proper .framework (maybe a pod?);
- [ ] Make possible to remove points from mesh;
- [ ] Change logic to encapsulate the generation of Supertriangle at the start of a new triangulation mesh.
- [ ] Change _DelaunayTriangulation Class_ to permit multiple instances, and stop looking so much like a Singleton.

---

## Installing
It's a simple project. Just copy and paste the folder to your project and you're set.

## How To Use It
- **First:** add the DelaunayTriangulation.superTriangle, passing as argument the area where all your points will be contained. Usually it will be your screen:
    `DelaunayTriangulation.superTriangle(for: self.frame)`

- **Second:** for each point added, you got a list of new generated triangles and the old ones, removed in the process. Please, see _Triangle Class_ to learn what kind of data you can obtain from _Triangle_ instances.
```Swift
    if let triangles = DelaunayTriangulation.incrementalDelaunay(vertex: t) {
        for triangle in triangles.add {
            // do stuff with new triangles data
        }
        for triangle in triangles.remove {
            // do stuff with old triangles data
        }
    }
```
- **Third:** to start again, you could simply call:
    `DelaunayTriangulation.reset()`

---

## Collaborations
I'm new to Github and open-source collaborations. All GitHub members interessed are welcome to submit roadmap suggestions and contribute improving the project.

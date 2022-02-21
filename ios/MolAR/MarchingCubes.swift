//
//  MarchingCubes.swift
//  MolAR
//
//  Created by Sukolsak on 10/10/21.
//

// Ported from https://github.com/molstar/molstar/tree/master/src/mol-geo/util/marching-cubes
// Copyright (c) 2018-2020 mol* contributors, licensed under MIT.
// @author David Sehnal <david.sehnal@gmail.com>
// @author Alexander Rose <alexander.rose@weirdbyte.de>

import Foundation

class MCMesh {
    var vertices: [Vec3]
    let normals: [Vec3]
    let indices: ContiguousArray<Int>

    init(vertices: [Vec3], normals: [Vec3], indices: ContiguousArray<Int>) {
        self.vertices = vertices
        self.normals = normals
        self.indices = indices
    }
}

private struct MCIndex {
    let i: Int
    let j: Int
    let k: Int
}

private struct MCIndexPair {
    let a: MCIndex
    let b: MCIndex
}

private let CubeVertices = [
    MCIndex(i: 0, j: 0, k: 0), // a
    MCIndex(i: 1, j: 0, k: 0), // b
    MCIndex(i: 1, j: 1, k: 0), // c
    MCIndex(i: 0, j: 1, k: 0), // d
    MCIndex(i: 0, j: 0, k: 1), // e
    MCIndex(i: 1, j: 0, k: 1), // f
    MCIndex(i: 1, j: 1, k: 1), // g
    MCIndex(i: 0, j: 1, k: 1), // h
]

private let CubeEdges = [
    MCIndexPair(a: CubeVertices[0], b: CubeVertices[1]),
    MCIndexPair(a: CubeVertices[1], b: CubeVertices[2]),
    MCIndexPair(a: CubeVertices[2], b: CubeVertices[3]),
    MCIndexPair(a: CubeVertices[3], b: CubeVertices[0]),

    MCIndexPair(a: CubeVertices[4], b: CubeVertices[5]),
    MCIndexPair(a: CubeVertices[5], b: CubeVertices[6]),
    MCIndexPair(a: CubeVertices[6], b: CubeVertices[7]),
    MCIndexPair(a: CubeVertices[7], b: CubeVertices[4]),

    MCIndexPair(a: CubeVertices[0], b: CubeVertices[4]),
    MCIndexPair(a: CubeVertices[1], b: CubeVertices[5]),
    MCIndexPair(a: CubeVertices[2], b: CubeVertices[6]),
    MCIndexPair(a: CubeVertices[3], b: CubeVertices[7]),
]

private struct EdgeIdInfo {
    let index: MCIndex
    let e: Int
}

private let EdgeIdInfos: [EdgeIdInfo] = [
    EdgeIdInfo(index: MCIndex(i: 0, j: 0, k: 0), e: 0),
    EdgeIdInfo(index: MCIndex(i: 1, j: 0, k: 0), e: 1),
    EdgeIdInfo(index: MCIndex(i: 0, j: 1, k: 0), e: 0),
    EdgeIdInfo(index: MCIndex(i: 0, j: 0, k: 0), e: 1),

    EdgeIdInfo(index: MCIndex(i: 0, j: 0, k: 1), e: 0),
    EdgeIdInfo(index: MCIndex(i: 1, j: 0, k: 1), e: 1),
    EdgeIdInfo(index: MCIndex(i: 0, j: 1, k: 1), e: 0),
    EdgeIdInfo(index: MCIndex(i: 0, j: 0, k: 1), e: 1),

    EdgeIdInfo(index: MCIndex(i: 0, j: 0, k: 0), e: 2),
    EdgeIdInfo(index: MCIndex(i: 1, j: 0, k: 0), e: 2),
    EdgeIdInfo(index: MCIndex(i: 1, j: 1, k: 0), e: 2),
    EdgeIdInfo(index: MCIndex(i: 0, j: 1, k: 0), e: 2)
]

// Tables EdgeTable and TriTable taken from http://paulbourke.net/geometry/polygonise/
private let EdgeTable: [Int] = [
    0x0, 0x109, 0x203, 0x30a, 0x406, 0x50f, 0x605, 0x70c,
    0x80c, 0x905, 0xa0f, 0xb06, 0xc0a, 0xd03, 0xe09, 0xf00,
    0x190, 0x99, 0x393, 0x29a, 0x596, 0x49f, 0x795, 0x69c,
    0x99c, 0x895, 0xb9f, 0xa96, 0xd9a, 0xc93, 0xf99, 0xe90,
    0x230, 0x339, 0x33, 0x13a, 0x636, 0x73f, 0x435, 0x53c,
    0xa3c, 0xb35, 0x83f, 0x936, 0xe3a, 0xf33, 0xc39, 0xd30,
    0x3a0, 0x2a9, 0x1a3, 0xaa, 0x7a6, 0x6af, 0x5a5, 0x4ac,
    0xbac, 0xaa5, 0x9af, 0x8a6, 0xfaa, 0xea3, 0xda9, 0xca0,
    0x460, 0x569, 0x663, 0x76a, 0x66, 0x16f, 0x265, 0x36c,
    0xc6c, 0xd65, 0xe6f, 0xf66, 0x86a, 0x963, 0xa69, 0xb60,
    0x5f0, 0x4f9, 0x7f3, 0x6fa, 0x1f6, 0xff, 0x3f5, 0x2fc,
    0xdfc, 0xcf5, 0xfff, 0xef6, 0x9fa, 0x8f3, 0xbf9, 0xaf0,
    0x650, 0x759, 0x453, 0x55a, 0x256, 0x35f, 0x55, 0x15c,
    0xe5c, 0xf55, 0xc5f, 0xd56, 0xa5a, 0xb53, 0x859, 0x950,
    0x7c0, 0x6c9, 0x5c3, 0x4ca, 0x3c6, 0x2cf, 0x1c5, 0xcc,
    0xfcc, 0xec5, 0xdcf, 0xcc6, 0xbca, 0xac3, 0x9c9, 0x8c0,
    0x8c0, 0x9c9, 0xac3, 0xbca, 0xcc6, 0xdcf, 0xec5, 0xfcc,
    0xcc, 0x1c5, 0x2cf, 0x3c6, 0x4ca, 0x5c3, 0x6c9, 0x7c0,
    0x950, 0x859, 0xb53, 0xa5a, 0xd56, 0xc5f, 0xf55, 0xe5c,
    0x15c, 0x55, 0x35f, 0x256, 0x55a, 0x453, 0x759, 0x650,
    0xaf0, 0xbf9, 0x8f3, 0x9fa, 0xef6, 0xfff, 0xcf5, 0xdfc,
    0x2fc, 0x3f5, 0xff, 0x1f6, 0x6fa, 0x7f3, 0x4f9, 0x5f0,
    0xb60, 0xa69, 0x963, 0x86a, 0xf66, 0xe6f, 0xd65, 0xc6c,
    0x36c, 0x265, 0x16f, 0x66, 0x76a, 0x663, 0x569, 0x460,
    0xca0, 0xda9, 0xea3, 0xfaa, 0x8a6, 0x9af, 0xaa5, 0xbac,
    0x4ac, 0x5a5, 0x6af, 0x7a6, 0xaa, 0x1a3, 0x2a9, 0x3a0,
    0xd30, 0xc39, 0xf33, 0xe3a, 0x936, 0x83f, 0xb35, 0xa3c,
    0x53c, 0x435, 0x73f, 0x636, 0x13a, 0x33, 0x339, 0x230,
    0xe90, 0xf99, 0xc93, 0xd9a, 0xa96, 0xb9f, 0x895, 0x99c,
    0x69c, 0x795, 0x49f, 0x596, 0x29a, 0x393, 0x99, 0x190,
    0xf00, 0xe09, 0xd03, 0xc0a, 0xb06, 0xa0f, 0x905, 0x80c,
    0x70c, 0x605, 0x50f, 0x406, 0x30a, 0x203, 0x109, 0x0
]

private let TriTable: [[Int]] = [
    [],
    [0, 8, 3],
    [0, 1, 9],
    [1, 8, 3, 9, 8, 1],
    [1, 2, 10],
    [0, 8, 3, 1, 2, 10],
    [9, 2, 10, 0, 2, 9],
    [2, 8, 3, 2, 10, 8, 10, 9, 8],
    [3, 11, 2],
    [0, 11, 2, 8, 11, 0],
    [1, 9, 0, 2, 3, 11],
    [1, 11, 2, 1, 9, 11, 9, 8, 11],
    [3, 10, 1, 11, 10, 3],
    [0, 10, 1, 0, 8, 10, 8, 11, 10],
    [3, 9, 0, 3, 11, 9, 11, 10, 9],
    [9, 8, 10, 10, 8, 11],
    [4, 7, 8],
    [4, 3, 0, 7, 3, 4],
    [0, 1, 9, 8, 4, 7],
    [4, 1, 9, 4, 7, 1, 7, 3, 1],
    [1, 2, 10, 8, 4, 7],
    [3, 4, 7, 3, 0, 4, 1, 2, 10],
    [9, 2, 10, 9, 0, 2, 8, 4, 7],
    [2, 10, 9, 2, 9, 7, 2, 7, 3, 7, 9, 4],
    [8, 4, 7, 3, 11, 2],
    [11, 4, 7, 11, 2, 4, 2, 0, 4],
    [9, 0, 1, 8, 4, 7, 2, 3, 11],
    [4, 7, 11, 9, 4, 11, 9, 11, 2, 9, 2, 1],
    [3, 10, 1, 3, 11, 10, 7, 8, 4],
    [1, 11, 10, 1, 4, 11, 1, 0, 4, 7, 11, 4],
    [4, 7, 8, 9, 0, 11, 9, 11, 10, 11, 0, 3],
    [4, 7, 11, 4, 11, 9, 9, 11, 10],
    [9, 5, 4],
    [9, 5, 4, 0, 8, 3],
    [0, 5, 4, 1, 5, 0],
    [8, 5, 4, 8, 3, 5, 3, 1, 5],
    [1, 2, 10, 9, 5, 4],
    [3, 0, 8, 1, 2, 10, 4, 9, 5],
    [5, 2, 10, 5, 4, 2, 4, 0, 2],
    [2, 10, 5, 3, 2, 5, 3, 5, 4, 3, 4, 8],
    [9, 5, 4, 2, 3, 11],
    [0, 11, 2, 0, 8, 11, 4, 9, 5],
    [0, 5, 4, 0, 1, 5, 2, 3, 11],
    [2, 1, 5, 2, 5, 8, 2, 8, 11, 4, 8, 5],
    [10, 3, 11, 10, 1, 3, 9, 5, 4],
    [4, 9, 5, 0, 8, 1, 8, 10, 1, 8, 11, 10],
    [5, 4, 0, 5, 0, 11, 5, 11, 10, 11, 0, 3],
    [5, 4, 8, 5, 8, 10, 10, 8, 11],
    [9, 7, 8, 5, 7, 9],
    [9, 3, 0, 9, 5, 3, 5, 7, 3],
    [0, 7, 8, 0, 1, 7, 1, 5, 7],
    [1, 5, 3, 3, 5, 7],
    [9, 7, 8, 9, 5, 7, 10, 1, 2],
    [10, 1, 2, 9, 5, 0, 5, 3, 0, 5, 7, 3],
    [8, 0, 2, 8, 2, 5, 8, 5, 7, 10, 5, 2],
    [2, 10, 5, 2, 5, 3, 3, 5, 7],
    [7, 9, 5, 7, 8, 9, 3, 11, 2],
    [9, 5, 7, 9, 7, 2, 9, 2, 0, 2, 7, 11],
    [2, 3, 11, 0, 1, 8, 1, 7, 8, 1, 5, 7],
    [11, 2, 1, 11, 1, 7, 7, 1, 5],
    [9, 5, 8, 8, 5, 7, 10, 1, 3, 10, 3, 11],
    [5, 7, 0, 5, 0, 9, 7, 11, 0, 1, 0, 10, 11, 10, 0],
    [11, 10, 0, 11, 0, 3, 10, 5, 0, 8, 0, 7, 5, 7, 0],
    [11, 10, 5, 7, 11, 5],
    [10, 6, 5],
    [0, 8, 3, 5, 10, 6],
    [9, 0, 1, 5, 10, 6],
    [1, 8, 3, 1, 9, 8, 5, 10, 6],
    [1, 6, 5, 2, 6, 1],
    [1, 6, 5, 1, 2, 6, 3, 0, 8],
    [9, 6, 5, 9, 0, 6, 0, 2, 6],
    [5, 9, 8, 5, 8, 2, 5, 2, 6, 3, 2, 8],
    [2, 3, 11, 10, 6, 5],
    [11, 0, 8, 11, 2, 0, 10, 6, 5],
    [0, 1, 9, 2, 3, 11, 5, 10, 6],
    [5, 10, 6, 1, 9, 2, 9, 11, 2, 9, 8, 11],
    [6, 3, 11, 6, 5, 3, 5, 1, 3],
    [0, 8, 11, 0, 11, 5, 0, 5, 1, 5, 11, 6],
    [3, 11, 6, 0, 3, 6, 0, 6, 5, 0, 5, 9],
    [6, 5, 9, 6, 9, 11, 11, 9, 8],
    [5, 10, 6, 4, 7, 8],
    [4, 3, 0, 4, 7, 3, 6, 5, 10],
    [1, 9, 0, 5, 10, 6, 8, 4, 7],
    [10, 6, 5, 1, 9, 7, 1, 7, 3, 7, 9, 4],
    [6, 1, 2, 6, 5, 1, 4, 7, 8],
    [1, 2, 5, 5, 2, 6, 3, 0, 4, 3, 4, 7],
    [8, 4, 7, 9, 0, 5, 0, 6, 5, 0, 2, 6],
    [7, 3, 9, 7, 9, 4, 3, 2, 9, 5, 9, 6, 2, 6, 9],
    [3, 11, 2, 7, 8, 4, 10, 6, 5],
    [5, 10, 6, 4, 7, 2, 4, 2, 0, 2, 7, 11],
    [0, 1, 9, 4, 7, 8, 2, 3, 11, 5, 10, 6],
    [9, 2, 1, 9, 11, 2, 9, 4, 11, 7, 11, 4, 5, 10, 6],
    [8, 4, 7, 3, 11, 5, 3, 5, 1, 5, 11, 6],
    [5, 1, 11, 5, 11, 6, 1, 0, 11, 7, 11, 4, 0, 4, 11],
    [0, 5, 9, 0, 6, 5, 0, 3, 6, 11, 6, 3, 8, 4, 7],
    [6, 5, 9, 6, 9, 11, 4, 7, 9, 7, 11, 9],
    [10, 4, 9, 6, 4, 10],
    [4, 10, 6, 4, 9, 10, 0, 8, 3],
    [10, 0, 1, 10, 6, 0, 6, 4, 0],
    [8, 3, 1, 8, 1, 6, 8, 6, 4, 6, 1, 10],
    [1, 4, 9, 1, 2, 4, 2, 6, 4],
    [3, 0, 8, 1, 2, 9, 2, 4, 9, 2, 6, 4],
    [0, 2, 4, 4, 2, 6],
    [8, 3, 2, 8, 2, 4, 4, 2, 6],
    [10, 4, 9, 10, 6, 4, 11, 2, 3],
    [0, 8, 2, 2, 8, 11, 4, 9, 10, 4, 10, 6],
    [3, 11, 2, 0, 1, 6, 0, 6, 4, 6, 1, 10],
    [6, 4, 1, 6, 1, 10, 4, 8, 1, 2, 1, 11, 8, 11, 1],
    [9, 6, 4, 9, 3, 6, 9, 1, 3, 11, 6, 3],
    [8, 11, 1, 8, 1, 0, 11, 6, 1, 9, 1, 4, 6, 4, 1],
    [3, 11, 6, 3, 6, 0, 0, 6, 4],
    [6, 4, 8, 11, 6, 8],
    [7, 10, 6, 7, 8, 10, 8, 9, 10],
    [0, 7, 3, 0, 10, 7, 0, 9, 10, 6, 7, 10],
    [10, 6, 7, 1, 10, 7, 1, 7, 8, 1, 8, 0],
    [10, 6, 7, 10, 7, 1, 1, 7, 3],
    [1, 2, 6, 1, 6, 8, 1, 8, 9, 8, 6, 7],
    [2, 6, 9, 2, 9, 1, 6, 7, 9, 0, 9, 3, 7, 3, 9],
    [7, 8, 0, 7, 0, 6, 6, 0, 2],
    [7, 3, 2, 6, 7, 2],
    [2, 3, 11, 10, 6, 8, 10, 8, 9, 8, 6, 7],
    [2, 0, 7, 2, 7, 11, 0, 9, 7, 6, 7, 10, 9, 10, 7],
    [1, 8, 0, 1, 7, 8, 1, 10, 7, 6, 7, 10, 2, 3, 11],
    [11, 2, 1, 11, 1, 7, 10, 6, 1, 6, 7, 1],
    [8, 9, 6, 8, 6, 7, 9, 1, 6, 11, 6, 3, 1, 3, 6],
    [0, 9, 1, 11, 6, 7],
    [7, 8, 0, 7, 0, 6, 3, 11, 0, 11, 6, 0],
    [7, 11, 6],
    [7, 6, 11],
    [3, 0, 8, 11, 7, 6],
    [0, 1, 9, 11, 7, 6],
    [8, 1, 9, 8, 3, 1, 11, 7, 6],
    [10, 1, 2, 6, 11, 7],
    [1, 2, 10, 3, 0, 8, 6, 11, 7],
    [2, 9, 0, 2, 10, 9, 6, 11, 7],
    [6, 11, 7, 2, 10, 3, 10, 8, 3, 10, 9, 8],
    [7, 2, 3, 6, 2, 7],
    [7, 0, 8, 7, 6, 0, 6, 2, 0],
    [2, 7, 6, 2, 3, 7, 0, 1, 9],
    [1, 6, 2, 1, 8, 6, 1, 9, 8, 8, 7, 6],
    [10, 7, 6, 10, 1, 7, 1, 3, 7],
    [10, 7, 6, 1, 7, 10, 1, 8, 7, 1, 0, 8],
    [0, 3, 7, 0, 7, 10, 0, 10, 9, 6, 10, 7],
    [7, 6, 10, 7, 10, 8, 8, 10, 9],
    [6, 8, 4, 11, 8, 6],
    [3, 6, 11, 3, 0, 6, 0, 4, 6],
    [8, 6, 11, 8, 4, 6, 9, 0, 1],
    [9, 4, 6, 9, 6, 3, 9, 3, 1, 11, 3, 6],
    [6, 8, 4, 6, 11, 8, 2, 10, 1],
    [1, 2, 10, 3, 0, 11, 0, 6, 11, 0, 4, 6],
    [4, 11, 8, 4, 6, 11, 0, 2, 9, 2, 10, 9],
    [10, 9, 3, 10, 3, 2, 9, 4, 3, 11, 3, 6, 4, 6, 3],
    [8, 2, 3, 8, 4, 2, 4, 6, 2],
    [0, 4, 2, 4, 6, 2],
    [1, 9, 0, 2, 3, 4, 2, 4, 6, 4, 3, 8],
    [1, 9, 4, 1, 4, 2, 2, 4, 6],
    [8, 1, 3, 8, 6, 1, 8, 4, 6, 6, 10, 1],
    [10, 1, 0, 10, 0, 6, 6, 0, 4],
    [4, 6, 3, 4, 3, 8, 6, 10, 3, 0, 3, 9, 10, 9, 3],
    [10, 9, 4, 6, 10, 4],
    [4, 9, 5, 7, 6, 11],
    [0, 8, 3, 4, 9, 5, 11, 7, 6],
    [5, 0, 1, 5, 4, 0, 7, 6, 11],
    [11, 7, 6, 8, 3, 4, 3, 5, 4, 3, 1, 5],
    [9, 5, 4, 10, 1, 2, 7, 6, 11],
    [6, 11, 7, 1, 2, 10, 0, 8, 3, 4, 9, 5],
    [7, 6, 11, 5, 4, 10, 4, 2, 10, 4, 0, 2],
    [3, 4, 8, 3, 5, 4, 3, 2, 5, 10, 5, 2, 11, 7, 6],
    [7, 2, 3, 7, 6, 2, 5, 4, 9],
    [9, 5, 4, 0, 8, 6, 0, 6, 2, 6, 8, 7],
    [3, 6, 2, 3, 7, 6, 1, 5, 0, 5, 4, 0],
    [6, 2, 8, 6, 8, 7, 2, 1, 8, 4, 8, 5, 1, 5, 8],
    [9, 5, 4, 10, 1, 6, 1, 7, 6, 1, 3, 7],
    [1, 6, 10, 1, 7, 6, 1, 0, 7, 8, 7, 0, 9, 5, 4],
    [4, 0, 10, 4, 10, 5, 0, 3, 10, 6, 10, 7, 3, 7, 10],
    [7, 6, 10, 7, 10, 8, 5, 4, 10, 4, 8, 10],
    [6, 9, 5, 6, 11, 9, 11, 8, 9],
    [3, 6, 11, 0, 6, 3, 0, 5, 6, 0, 9, 5],
    [0, 11, 8, 0, 5, 11, 0, 1, 5, 5, 6, 11],
    [6, 11, 3, 6, 3, 5, 5, 3, 1],
    [1, 2, 10, 9, 5, 11, 9, 11, 8, 11, 5, 6],
    [0, 11, 3, 0, 6, 11, 0, 9, 6, 5, 6, 9, 1, 2, 10],
    [11, 8, 5, 11, 5, 6, 8, 0, 5, 10, 5, 2, 0, 2, 5],
    [6, 11, 3, 6, 3, 5, 2, 10, 3, 10, 5, 3],
    [5, 8, 9, 5, 2, 8, 5, 6, 2, 3, 8, 2],
    [9, 5, 6, 9, 6, 0, 0, 6, 2],
    [1, 5, 8, 1, 8, 0, 5, 6, 8, 3, 8, 2, 6, 2, 8],
    [1, 5, 6, 2, 1, 6],
    [1, 3, 6, 1, 6, 10, 3, 8, 6, 5, 6, 9, 8, 9, 6],
    [10, 1, 0, 10, 0, 6, 9, 5, 0, 5, 6, 0],
    [0, 3, 8, 5, 6, 10],
    [10, 5, 6],
    [11, 5, 10, 7, 5, 11],
    [11, 5, 10, 11, 7, 5, 8, 3, 0],
    [5, 11, 7, 5, 10, 11, 1, 9, 0],
    [10, 7, 5, 10, 11, 7, 9, 8, 1, 8, 3, 1],
    [11, 1, 2, 11, 7, 1, 7, 5, 1],
    [0, 8, 3, 1, 2, 7, 1, 7, 5, 7, 2, 11],
    [9, 7, 5, 9, 2, 7, 9, 0, 2, 2, 11, 7],
    [7, 5, 2, 7, 2, 11, 5, 9, 2, 3, 2, 8, 9, 8, 2],
    [2, 5, 10, 2, 3, 5, 3, 7, 5],
    [8, 2, 0, 8, 5, 2, 8, 7, 5, 10, 2, 5],
    [9, 0, 1, 5, 10, 3, 5, 3, 7, 3, 10, 2],
    [9, 8, 2, 9, 2, 1, 8, 7, 2, 10, 2, 5, 7, 5, 2],
    [1, 3, 5, 3, 7, 5],
    [0, 8, 7, 0, 7, 1, 1, 7, 5],
    [9, 0, 3, 9, 3, 5, 5, 3, 7],
    [9, 8, 7, 5, 9, 7],
    [5, 8, 4, 5, 10, 8, 10, 11, 8],
    [5, 0, 4, 5, 11, 0, 5, 10, 11, 11, 3, 0],
    [0, 1, 9, 8, 4, 10, 8, 10, 11, 10, 4, 5],
    [10, 11, 4, 10, 4, 5, 11, 3, 4, 9, 4, 1, 3, 1, 4],
    [2, 5, 1, 2, 8, 5, 2, 11, 8, 4, 5, 8],
    [0, 4, 11, 0, 11, 3, 4, 5, 11, 2, 11, 1, 5, 1, 11],
    [0, 2, 5, 0, 5, 9, 2, 11, 5, 4, 5, 8, 11, 8, 5],
    [9, 4, 5, 2, 11, 3],
    [2, 5, 10, 3, 5, 2, 3, 4, 5, 3, 8, 4],
    [5, 10, 2, 5, 2, 4, 4, 2, 0],
    [3, 10, 2, 3, 5, 10, 3, 8, 5, 4, 5, 8, 0, 1, 9],
    [5, 10, 2, 5, 2, 4, 1, 9, 2, 9, 4, 2],
    [8, 4, 5, 8, 5, 3, 3, 5, 1],
    [0, 4, 5, 1, 0, 5],
    [8, 4, 5, 8, 5, 3, 9, 0, 5, 0, 3, 5],
    [9, 4, 5],
    [4, 11, 7, 4, 9, 11, 9, 10, 11],
    [0, 8, 3, 4, 9, 7, 9, 11, 7, 9, 10, 11],
    [1, 10, 11, 1, 11, 4, 1, 4, 0, 7, 4, 11],
    [3, 1, 4, 3, 4, 8, 1, 10, 4, 7, 4, 11, 10, 11, 4],
    [4, 11, 7, 9, 11, 4, 9, 2, 11, 9, 1, 2],
    [9, 7, 4, 9, 11, 7, 9, 1, 11, 2, 11, 1, 0, 8, 3],
    [11, 7, 4, 11, 4, 2, 2, 4, 0],
    [11, 7, 4, 11, 4, 2, 8, 3, 4, 3, 2, 4],
    [2, 9, 10, 2, 7, 9, 2, 3, 7, 7, 4, 9],
    [9, 10, 7, 9, 7, 4, 10, 2, 7, 8, 7, 0, 2, 0, 7],
    [3, 7, 10, 3, 10, 2, 7, 4, 10, 1, 10, 0, 4, 0, 10],
    [1, 10, 2, 8, 7, 4],
    [4, 9, 1, 4, 1, 7, 7, 1, 3],
    [4, 9, 1, 4, 1, 7, 0, 8, 1, 8, 7, 1],
    [4, 0, 3, 7, 4, 3],
    [4, 8, 7],
    [9, 10, 8, 10, 11, 8],
    [3, 0, 9, 3, 9, 11, 11, 9, 10],
    [0, 1, 10, 0, 10, 8, 8, 10, 11],
    [3, 1, 10, 11, 3, 10],
    [1, 2, 11, 1, 11, 9, 9, 11, 8],
    [3, 0, 9, 3, 9, 11, 1, 2, 9, 2, 11, 9],
    [0, 2, 11, 8, 0, 11],
    [3, 2, 11],
    [2, 3, 8, 2, 8, 10, 10, 8, 9],
    [9, 10, 2, 0, 9, 2],
    [2, 3, 8, 2, 8, 10, 0, 1, 8, 1, 10, 8],
    [1, 10, 2],
    [1, 3, 8, 9, 1, 8],
    [0, 9, 1],
    [0, 3, 8],
    []
]


func computeMarchingCubesMesh(data: [Float], dimensions: [Int], isoLevel: Float) -> MCMesh {
    let mc = MarchingCubes(data: data, dimensions: dimensions, isoLevel: isoLevel)
    mc.run()
    return mc.get()
}


private class MarchingCubes {
    private let state: MarchingCubesState
    private let minX: Int
    private let minY: Int
    private let minZ: Int
    private let maxX: Int
    private let maxY: Int
    private let maxZ: Int

    init(data: [Float], dimensions: [Int], isoLevel: Float) {
        state = MarchingCubesState(data: data, dimensions: dimensions, isoLevel: isoLevel)
        minX = 0
        minY = 0
        minZ = 0
        maxX = dimensions[0] - 1
        maxY = dimensions[1] - 1
        maxZ = dimensions[2] - 1
    }

    private func slice(_ k: Int) {
        for j in minY ..< maxY {
            for i in minX ..< maxX {
                state.processCell(i, j, k)
            }
        }
        state.clearEdgeVertexIndexSlice(k)
    }

    func run() {
        for k in minZ ..< maxZ {
            slice(k)
        }
    }

    func get() -> MCMesh {
        return MCMesh(vertices: state.vertices, normals: state.normals, indices: state.indices)
    }
}

private final class MarchingCubesState {
    private var vertList: [Int] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    private var i = 0
    private var j = 0
    private var k = 0

    private let data: [Float]
    private let nX: Int
    private let nY: Int
    private let nZ: Int
    private let isoLevel: Float

    var vertexCount = 0
    // var triangleCount = 0
    var vertices = [Vec3]()
    var normals = [Vec3]()
    var indices = ContiguousArray<Int>()

    // two layers of vertex indices. Each vertex has 3 edges associated.
    private var verticesOnEdges: [Int]

    init(data: [Float], dimensions: [Int], isoLevel: Float) {
        self.data = data
        nX = dimensions[0]
        nY = dimensions[1]
        nZ = dimensions[2]
        self.isoLevel = isoLevel
        verticesOnEdges = [Int](repeating: 0, count: 3 * nX * nY * 2)
    }

    private func get3dOffsetFromEdgeInfo(_ index: MCIndex) -> Int {
        return nX * (((k + index.k) % 2) * nY + j + index.j) + i + index.i
    }

    /**
     * This clears the "vertex index buffer" for the slice that will not be accessed anymore.
     */
    func clearEdgeVertexIndexSlice(_ k: Int) {
        // clear either the top or bottom half of the buffer...
        let start = k % 2 == 0 ? 0 : 3 * nX * nY
        let end = k % 2 == 0 ? 3 * nX * nY : verticesOnEdges.count
        verticesOnEdges.replaceSubrange(start..<end, with: [Int](repeating: 0, count: end - start))
    }

    private func interpolate(_ edgeNum: Int) -> Int {
        let info = EdgeIdInfos[edgeNum]
        let edgeId = 3 * get3dOffsetFromEdgeInfo(info.index) + info.e

        let ret = verticesOnEdges[edgeId]
        if ret > 0 { return ret - 1 }

        let edge = CubeEdges[edgeNum]
        let a = edge.a, b = edge.b
        let li = a.i + self.i, lj = a.j + self.j, lk = a.k + self.k
        let hi = b.i + self.i, hj = b.j + self.j, hk = b.k + self.k
        let v0 = self.get(li, lj, lk)
        let v1 = self.get(hi, hj, hk)
        let t = (isoLevel - v0) / (v0 - v1)

        let id = addVertex(
            Float(li) + t * Float(li - hi),
            Float(lj) + t * Float(lj - hj),
            Float(lk) + t * Float(lk - hk)
        )
        verticesOnEdges[edgeId] = id + 1

        // TODO cache scalarField differences for slices
        // TODO make calculation optional
        let n0x = self.get(max(0, li - 1), lj, lk) - self.get(min(nX - 1, li + 1), lj, lk)
        let n0y = self.get(li, max(0, lj - 1), lk) - self.get(li, min(nY - 1, lj + 1), lk)
        let n0z = self.get(li, lj, max(0, lk - 1)) - self.get(li, lj, min(nZ, lk + 1))

        let n1x = self.get(max(0, hi - 1), hj, hk) - self.get(min(nX - 1, hi + 1), hj, hk)
        let n1y = self.get(hi, max(0, hj - 1), hk) - self.get(hi, min(nY - 1, hj + 1), hk)
        let n1z = self.get(hi, hj, max(0, hk - 1)) - self.get(hi, hj, min(nZ - 1, hk + 1))

        let nx = n0x + t * (n0x - n1x)
        let ny = n0y + t * (n0y - n1y)
        let nz = n0z + t * (n0z - n1z)

        // ensure normal-direction is the same for negative and positive iso-levels
        if isoLevel >= 0 {
            addNormal(nx, ny, nz)
        } else {
            addNormal(-nx, -ny, -nz)
        }

        return id
    }

    private func get(_ i: Int, _ j: Int, _ k: Int) -> Float {
        //return this.scalarFieldGet(this.scalarField, i, j, k)
        return data[i * nY * nZ + j * nZ + k]
    }

    func processCell(_ i: Int, _ j: Int, _ k: Int) {
        var tableIndex = 0

        if self.get(i, j, k) < isoLevel { tableIndex |= 1 }
        if self.get(i + 1, j, k) < isoLevel { tableIndex |= 2 }
        if self.get(i + 1, j + 1, k) < isoLevel { tableIndex |= 4 }
        if self.get(i, j + 1, k) < isoLevel { tableIndex |= 8 }
        if self.get(i, j, k + 1) < isoLevel { tableIndex |= 16 }
        if self.get(i + 1, j, k + 1) < isoLevel { tableIndex |= 32 }
        if self.get(i + 1, j + 1, k + 1) < isoLevel { tableIndex |= 64 }
        if self.get(i, j + 1, k + 1) < isoLevel { tableIndex |= 128 }

        if tableIndex == 0 || tableIndex == 255 { return }

        self.i = i
        self.j = j
        self.k = k
        let edgeInfo = EdgeTable[tableIndex]
        if (edgeInfo & 1) > 0 { vertList[0] = interpolate(0) } // 0 1
        if (edgeInfo & 2) > 0 { vertList[1] = interpolate(1) } // 1 2
        if (edgeInfo & 4) > 0 { vertList[2] = interpolate(2) } // 2 3
        if (edgeInfo & 8) > 0 { vertList[3] = interpolate(3) } // 0 3
        if (edgeInfo & 16) > 0 { vertList[4] = interpolate(4) } // 4 5
        if (edgeInfo & 32) > 0 { vertList[5] = interpolate(5) } // 5 6
        if (edgeInfo & 64) > 0 { vertList[6] = interpolate(6) } // 6 7
        if (edgeInfo & 128) > 0 { vertList[7] = interpolate(7) } // 4 7
        if (edgeInfo & 256) > 0 { vertList[8] = interpolate(8) } // 0 4
        if (edgeInfo & 512) > 0 { vertList[9] = interpolate(9) } // 1 5
        if (edgeInfo & 1024) > 0 { vertList[10] = interpolate(10) } // 2 6
        if (edgeInfo & 2048) > 0 { vertList[11] = interpolate(11) } // 3 7

        let triInfo = TriTable[tableIndex]
        for t in stride(from: 0, to: triInfo.count, by: 3) {
            let l = triInfo[t], m = triInfo[t + 1], n = triInfo[t + 2]
            // ensure winding-order is the same for negative and positive iso-levels
            if isoLevel >= 0 {
                addTriangle(vertList, l, m, n)
            } else {
                addTriangle(vertList, n, m, l)
            }
        }
    }



    private func addVertex(_ x: Float, _ y: Float, _ z: Float) -> Int {
        let ret = vertexCount
        vertexCount += 1
        vertices.append((x, y, z))
        return ret
    }

    private func addNormal(_ x: Float, _ y: Float, _ z: Float) {
        normals.append((x, y, z))
    }

    private func addTriangle(_ vertList: [Int], _ a: Int, _ b: Int, _ c: Int) {
        let i = vertList[a], j = vertList[b], k = vertList[c]
        indices.append(i)
        indices.append(j)
        indices.append(k)
    }
}

//
//  SDFGeoGen.swift
//  MolAR
//
//  Created by Sukolsak on 10/8/21.
//

import Foundation
import simd


enum MolecularModelMode: Int {
    case ballAndStick = 0
    case spaceFilling = 1
    case skeletal = 2
}

enum MolecularOrbitalMode: Int {
    case none = 0
    case HOMO = 1 // highest occupied molecular orbital
    case LUMO = 2 // lowest unoccupied molecular orbital
}

enum PolymerMode: Int {
    case cartoon = 0
    case gaussianSurface = 1
}


private let colorMap: [String: Int] = ["H": 0xFFFFFF, "D": 0xFFFFC0, "T": 0xFFFFA0, "HE": 0xD9FFFF, "LI": 0xCC80FF, "BE": 0xC2FF00, "B": 0xFFB5B5, "C": 0x909090, "N": 0x3050F8, "O": 0xFF0D0D, "F": 0x90E050, "NE": 0xB3E3F5, "NA": 0xAB5CF2, "MG": 0x8AFF00, "AL": 0xBFA6A6, "SI": 0xF0C8A0, "P": 0xFF8000, "S": 0xFFFF30, "CL": 0x1FF01F, "AR": 0x80D1E3, "K": 0x8F40D4, "CA": 0x3DFF00, "SC": 0xE6E6E6, "TI": 0xBFC2C7, "V": 0xA6A6AB, "CR": 0x8A99C7, "MN": 0x9C7AC7, "FE": 0xE06633, "CO": 0xF090A0, "NI": 0x50D050, "CU": 0xC88033, "ZN": 0x7D80B0, "GA": 0xC28F8F, "GE": 0x668F8F, "AS": 0xBD80E3, "SE": 0xFFA100, "BR": 0xA62929, "KR": 0x5CB8D1, "RB": 0x702EB0, "SR": 0x00FF00, "Y": 0x94FFFF, "ZR": 0x94E0E0, "NB": 0x73C2C9, "MO": 0x54B5B5, "TC": 0x3B9E9E, "RU": 0x248F8F, "RH": 0x0A7D8C, "PD": 0x006985, "AG": 0xC0C0C0, "CD": 0xFFD98F, "IN": 0xA67573, "SN": 0x668080, "SB": 0x9E63B5, "TE": 0xD47A00, "I": 0x940094, "XE": 0x940094, "CS": 0x57178F, "BA": 0x00C900, "LA": 0x70D4FF, "CE": 0xFFFFC7, "PR": 0xD9FFC7, "ND": 0xC7FFC7, "PM": 0xA3FFC7, "SM": 0x8FFFC7, "EU": 0x61FFC7, "GD": 0x45FFC7, "TB": 0x30FFC7, "DY": 0x1FFFC7, "HO": 0x00FF9C, "ER": 0x00E675, "TM": 0x00D452, "YB": 0x00BF38, "LU": 0x00AB24, "HF": 0x4DC2FF, "TA": 0x4DA6FF, "W": 0x2194D6, "RE": 0x267DAB, "OS": 0x266696, "IR": 0x175487, "PT": 0xD0D0E0, "AU": 0xFFD123, "HG": 0xB8B8D0, "TL": 0xA6544D, "PB": 0x575961, "BI": 0x9E4FB5, "PO": 0xAB5C00, "AT": 0x754F45, "RN": 0x428296, "FR": 0x420066, "RA": 0x007D00, "AC": 0x70ABFA, "TH": 0x00BAFF, "PA": 0x00A1FF, "U": 0x008FFF, "NP": 0x0080FF, "PU": 0x006BFF, "AM": 0x545CF2, "CM": 0x785CE3, "BK": 0x8A4FE3, "CF": 0xA136D4, "ES": 0xB31FD4, "FM": 0xB31FBA, "MD": 0xB30DA6, "NO": 0xBD0D87, "LR": 0xC70066, "RF": 0xCC0059, "DB": 0xD1004F, "SG": 0xD90045, "BH": 0xE00038, "HS": 0xE6002E, "MT": 0xEB0026, "DS": 0xFFFFFF, "RG": 0xFFFFFF, "CN": 0xFFFFFF, "UUT": 0xFFFFFF, "FL": 0xFFFFFF, "UUP": 0xFFFFFF, "LV": 0xFFFFFF, "UUH": 0xFFFFFF]
private func getColor(_ element: String) -> Int {
    return colorMap[element] ?? 0xFFFFFF
}

private let radiusMap: [String: Float] = ["H": 1.1, "D": 1.1, "T": 1.1, "HE": 1.4, "LI": 1.81, "BE": 1.53, "B": 1.92, "C": 1.7, "N": 1.55, "O": 1.52, "F": 1.47, "NE": 1.54, "NA": 2.27, "MG": 1.73, "AL": 1.84, "SI": 2.1, "P": 1.8, "S": 1.8, "CL": 1.75, "AR": 1.88, "K": 2.75, "CA": 2.31, "SC": 2.3, "TI": 2.15, "V": 2.05, "CR": 2.05, "MN": 2.05, "FE": 2.05, "CO": 2, "NI": 2, "CU": 2, "ZN": 2.1, "GA": 1.87, "GE": 2.11, "AS": 1.85, "SE": 1.9, "BR": 1.83, "KR": 2.02, "RB": 3.03, "SR": 2.49, "Y": 2.4, "ZR": 2.3, "NB": 2.15, "MO": 2.1, "TC": 2.05, "RU": 2.05, "RH": 2, "PD": 2.05, "AG": 2.1, "CD": 2.2, "IN": 2.2, "SN": 1.93, "SB": 2.17, "TE": 2.06, "I": 1.98, "XE": 2.16, "CS": 3.43, "BA": 2.68, "LA": 2.5, "CE": 2.48, "PR": 2.47, "ND": 2.45, "PM": 2.43, "SM": 2.42, "EU": 2.4, "GD": 2.38, "TB": 2.37, "DY": 2.35, "HO": 2.33, "ER": 2.32, "TM": 2.3, "YB": 2.28, "LU": 2.27, "HF": 2.25, "TA": 2.2, "W": 2.1, "RE": 2.05, "OS": 2, "IR": 2, "PT": 2.05, "AU": 2.1, "HG": 2.05, "TL": 1.96, "PB": 2.02, "BI": 2.07, "PO": 1.97, "AT": 2.02, "RN": 2.2, "FR": 3.48, "RA": 2.83, "AC": 2, "TH": 2.4, "PA": 2, "U": 2.3, "NP": 2, "PU": 2, "AM": 2, "CM": 2, "BK": 2, "CF": 2, "ES": 2, "FM": 2, "MD": 2, "NO": 2, "LR": 2, "RF": 2, "DB": 2, "SG": 2, "BH": 2, "HS": 2, "MT": 2, "DS": 1, "RG": 1, "CN": 1, "UUT": 1, "FL": 1, "UUP": 1, "LV": 1, "UUH": 1]
private func getRadius(_ element: String) -> Float {
    return radiusMap[element] ?? 1.0
}

private let weightMap: [String: Float] = [ "H": 1.008, "D": 2, "T": 3, "HE": 4.002, "LI": 6.9675, "BE": 9.012, "B": 10.8135, "C": 12.0106, "N": 14.006, "O": 15.999, "F": 18.998, "NE": 20.1797, "NA": 22.989, "MG": 24.307, "AL": 26.981, "SI": 28.084, "P": 30.973, "S": 32.059, "CL": 35.4515, "AR": 39.948, "K": 39.0983, "CA": 40.078, "SC": 44.955, "TI": 47.867, "V": 50.9415, "CR": 51.9961, "MN": 54.938, "FE": 55.845, "CO": 58.933, "NI": 58.6934, "CU": 63.546, "ZN": 65.38, "GA": 69.723, "GE": 72.63, "AS": 74.921, "SE": 78.971, "BR": 79.904, "KR": 83.798, "RB": 85.4678, "SR": 87.62, "Y": 88.905, "ZR": 91.224, "NB": 92.906, "MO": 95.95, "TC": 98.91, "RU": 101.07, "RH": 102.905, "PD": 106.42, "AG": 107.8682, "CD": 112.414, "IN": 114.818, "SN": 118.71, "SB": 121.76, "TE": 127.6, "I": 126.904, "XE": 131.293, "CS": 132.905, "BA": 137.327, "LA": 138.905, "CE": 140.116, "PR": 140.907, "ND": 144.242, "PM": 144.9, "SM": 150.36, "EU": 151.964, "GD": 157.25, "TB": 158.925, "DY": 162.5, "HO": 164.93, "ER": 167.259, "TM": 168.934, "YB": 173.054, "LU": 174.9668, "HF": 178.49, "TA": 180.947, "W": 183.84, "RE": 186.207, "OS": 190.23, "IR": 192.217, "PT": 195.084, "AU": 196.966, "HG": 200.592, "TL": 204.3835, "PB": 207.2, "BI": 208.98, "PO": 210, "AT": 210, "RN": 222, "FR": 223, "RA": 226.03, "AC": 227.03, "TH": 232.0377, "PA": 231.035, "U": 238.028, "NP": 237.05, "PU": 239.1, "AM": 243.1, "CM": 247.1, "BK": 247.1, "CF": 252.1, "ES": 252.1, "FM": 257.1, "MD": 256.1, "NO": 259.1, "LR": 260.1, "RF": 261, "DB": 262, "SG": 263, "BH": 262, "HS": 265, "MT": 268, "DS": 0, "RG": 0, "CN": 0, "UUT": 0, "FL": 0, "UUP": 0, "LV": 0, "UUH": 0 ]
private func getWeight(_ element: String) -> Float {
    return weightMap[element] ?? 0.0
}


// FIXME: Just use simd for everything
private func toSIMD3(_ a: Vec3) -> SIMD3<Float> {
    return simd_float3(a.0, a.1, a.2)
}
private func toVec3(_ a: SIMD3<Float>) -> Vec3 {
    return Vec3(a.x, a.y, a.z)
}

private func calculateShiftDir(_ v1: SIMD3<Float>, _ v2: SIMD3<Float>, _ v3: SIMD3<Float>?) -> SIMD3<Float> {
    let tmpShiftV12 = simd_normalize(v2 - v1)
    var tmpShiftV13: SIMD3<Float>
    if let v3 = v3 {
        tmpShiftV13 = v3 - v1
    } else {
        // FIXME: THIS is wrong if v1 is (0,0,0)
        tmpShiftV13 = v1    // no reference point, use v1
    }
    tmpShiftV13 = simd_normalize(tmpShiftV13)

    // ensure v13 and v12 are not colinear
    var dp = simd_dot(tmpShiftV12, tmpShiftV13)
    if 1 - abs(dp) < 1e-5 { // If they are colinear
        tmpShiftV13 = simd_float3(1, 0, 0)
        dp = simd_dot(tmpShiftV12, tmpShiftV13)
        if 1 - abs(dp) < 1e-5 { // If they are still colinear
            tmpShiftV13 = simd_float3(0, 1, 0)
            dp = simd_dot(tmpShiftV12, tmpShiftV13)
        }
    }

    return simd_normalize(tmpShiftV13 - simd_normalize(tmpShiftV12) * dp)
}

private func makeTranslationMatrix(_ v: SIMD3<Float>) -> simd_float4x4 {
    var matrix = matrix_identity_float4x4
    matrix[3, 0] = v.x
    matrix[3, 1] = v.y
    matrix[3, 2] = v.z
    return matrix
}

private func makeCylinderMatrix(_ start: simd_float3, _ end: simd_float3, _ vShift: simd_float3) -> simd_float4x4 {
    var vShift = vShift
    if vShift.x == 0 && vShift.y == 0 && vShift.z == 0 {
        vShift = simd_float3(0, 0, 1)
    }

    let newY = end - start
    let vTmp = simd_normalize(newY)
    let newX = simd_normalize(vShift - vTmp * simd_dot(vTmp, vShift)) // The component of vShift that is perpendicular to vTmp
    let newZ = simd_cross(newX, vTmp)
    let center = (start + end) * 0.5
    return simd_float4x4([
        simd_float4(newX.x, newX.y, newX.z, 0),
        simd_float4(newY.x, newY.y, newY.z, 0),
        simd_float4(newZ.x, newZ.y, newZ.z, 0),
        simd_float4(center.x, center.y, center.z, 1),
    ])
}


func convertSDFStructureToMYOBJ(_ structure: SDFStructure, molecularModelMode: MolecularModelMode, molden: MoldenFile?, molecularOrbitalMode: MolecularOrbitalMode, dipoleMoment: Vec3?, vibrations: [Vec3]?) -> MYOBJ {

    let elements = structure.elements
    let bonds = structure.bonds

    var shapes = [MYOBJShape]()

    let radiusFactor: Float = (molecularModelMode == .spaceFilling) ? 1.0 : 0.23

    // Determine the boundaries.
    // FIXME: Take molecularModelMode into account
    var boundaryMin = simd_float3(Float.infinity, Float.infinity, Float.infinity)
    var boundaryMax = simd_float3(-Float.infinity, -Float.infinity, -Float.infinity)
    for element in elements {
        let symbol = element.symbol, v = toSIMD3(element.position)
        let r = getRadius(symbol) * radiusFactor
        let rv = simd_float3(r, r, r)
        boundaryMin = simd_min(boundaryMin, v - rv)
        boundaryMax = simd_max(boundaryMax, v + rv)
    }


    // Create adjacency list
    var adjList = [Int: [Int]]()
    for bond in bonds {
        let a = bond.a, b = bond.b, order = bond.order

        if adjList[a] == nil { adjList[a] = [] }
        if adjList[b] == nil { adjList[b] = [] }
        if order != 4 {
            adjList[a]!.append(b)
            adjList[b]!.append(a)
        } else { // Prioritize aromatic bonds, so that when we calculate shift direction, they come up first.
            adjList[a]!.insert(b, at: 0)
            adjList[b]!.insert(a, at: 0)
        }
    }

    // Calculate element positions for vibrations
    var elementPositions = [[simd_float3]]()
    var keyframes = [Double]()
    if let vibrations = vibrations {
        let nFrames = 9
        let endTimeCode = 24
        for j in 0 ..< nFrames {
            let t: Float = Float(j) / Float(nFrames - 1)
            let keyframe = Double(endTimeCode) * Double(t)
            keyframes.append(keyframe)
        }

        for i in 0 ..< elements.count {
            let element = elements[i]
            let symbol = element.symbol, v = toSIMD3(element.position)
            var e = [simd_float3]()
            let displacement = toSIMD3(vibrations[i])
            let r = getRadius(symbol) * radiusFactor
            let rv = simd_float3(r, r, r)
            for j in 0 ..< nFrames {
                let t: Float = Float(j) / Float(nFrames - 1)
                let v2 = v + displacement * sin((t == 0.5 || t == 1) ? 0 : (2 * Float.pi * t))
                e.append(v2)
                boundaryMin = simd_min(boundaryMin, v2 - rv)
                boundaryMax = simd_max(boundaryMax, v2 + rv)
            }
            elementPositions.append(e)
        }
    }

    // Write atoms
    if molecularModelMode != .skeletal {
        for i in 0 ..< elements.count {
            let element = elements[i]
            let symbol = element.symbol, v = element.position
            let r = getRadius(symbol) * radiusFactor
            if vibrations == nil {
                shapes.append(MYOBJSphere(p: v, r: r, color: getColor(symbol)))
            } else {
                let e = elementPositions[i]
                var frames = [(Double, simd_float4x4)]()
                for j in 0 ..< keyframes.count {
                    frames.append((keyframes[j], makeTranslationMatrix(e[j])))
                }
                shapes.append(MYOBJSphere(p: Vec3(0, 0, 0), r: r, color: getColor(symbol), frames: frames))
            }
        }
    }


    // Write bonds
    if molecularModelMode != .spaceFilling {
        for bond in bonds {
            let a = bond.a, b = bond.b, order = bond.order
            let symbol1 = elements[a].symbol, va = toSIMD3(elements[a].position)
            let symbol2 = elements[b].symbol, vb = toSIMD3(elements[b].position)

            let vShift: SIMD3<Float>
            if order == 2 || order == 3 {
                let tmp = simd_cross(simd_normalize(vb - va), simd_float3(0, 0, 1))
                if simd_length_squared(tmp) < 1e-5 {
                    vShift = simd_float3(1, 0, 0)
                } else {
                    vShift = simd_normalize(tmp)
                }
            } else if order == 4 { // Aromatic
                var ref: Int? = nil
                for c in adjList[a]! {
                    if c != b { ref = c; break }
                }
                if ref == nil {
                    for c in adjList[b]! {
                        if c != a { ref = c; break }
                    }
                }
                vShift = calculateShiftDir(va, vb, (ref != nil) ? toSIMD3(elements[ref!].position) : nil)
            } else {
                vShift = simd_float3(0, 0, 0)
            }



            var gap: Float = 0.36 // can also be 0.35 - 0.45 when carbon both sides
            var radius: Float = 0.15
            if order == 2 {
                radius = 0.12
            } else if order >= 3 {
                gap = 0.25
                radius = 0.1
            }

            if vibrations == nil {
                let vm = 0.5 * (va + vb)
                if order <= 3 {
                    for i in 0 ..< order {
                        let tmp: Float = (Float(i) - Float(order) / 2 + 0.5) * gap
                        let vShift2 = vShift * tmp
                        let v1 = va + vShift2
                        let v2 = vm + vShift2
                        let v3 = vb + vShift2

                        shapes.append(MYOBJCylinder(p1: toVec3(v1), p2: (symbol1 == symbol2) ? toVec3(v3) : toVec3(v2), r: radius, caps: false, color: getColor(symbol1)))

                        if symbol1 != symbol2 {
                            shapes.append(MYOBJCylinder(p1: toVec3(v2), p2: toVec3(v3), r: radius, caps: false, color: getColor(symbol2)))
                        }

                        if molecularModelMode == .skeletal {
                            shapes.append(MYOBJSphere(p: toVec3(v1), r: radius, color: getColor(symbol1)))
                            shapes.append(MYOBJSphere(p: toVec3(v3), r: radius, color: getColor(symbol2)))
                        }
                    }
                } else if order == 4 { // aromatic bond. dashed.
                    let res = 4
                    let tt = Float(res * 4 + 1)
                    let vShift2 = vShift * 0.2
                    for i in 0 ..< res*2 {
                        let k1 = (2.0 * Float(i) + 1.0) / tt
                        let v1 = va * (1 - k1) + vb * k1 + vShift2
                        let k2 = (2.0 * Float(i) + 2.0) / tt
                        let v2 = va * (1 - k2) + vb * k2 + vShift2

                        shapes.append(MYOBJCylinder(p1: toVec3(v1), p2: toVec3(v2), r: 0.05, caps: true, color: getColor((i < res) ? symbol1 : symbol2)))
                    }

                    shapes.append(MYOBJCylinder(p1: toVec3(va), p2: (symbol1 == symbol2) ? toVec3(vb) : toVec3(vm), r: radius, caps: false, color: getColor(symbol1)))

                    if symbol1 != symbol2 {
                        shapes.append(MYOBJCylinder(p1: toVec3(vm), p2: toVec3(vb), r: radius, caps: false, color: getColor(symbol2)))
                    }

                    if molecularModelMode == .skeletal {
                        shapes.append(MYOBJSphere(p: toVec3(va), r: radius, color: getColor(symbol1)))
                        shapes.append(MYOBJSphere(p: toVec3(vb), r: radius, color: getColor(symbol2)))
                    }
                }
            } else {
                let vas = elementPositions[a], vbs = elementPositions[b]
                if order <= 3 {
                    for i in 0 ..< order {
                        let tmp: Float = (Float(i) - Float(order) / 2 + 0.5) * gap

                        var frames = [(Double, simd_float4x4)]()
                        for j in 0 ..< keyframes.count {
                            frames.append((keyframes[j], makeCylinderMatrix(vas[j], vbs[j], vShift)))
                        }
                        shapes.append(MYOBJCylinder(p1: Vec3(tmp, -0.5, 0), p2: Vec3(tmp, (symbol1 == symbol2) ? 0.5 : 0, 0), r: radius, caps: false, color: getColor(symbol1), frames: frames))

                        if symbol1 != symbol2 {
                            shapes.append(MYOBJCylinder(p1: Vec3(tmp, 0, 0), p2: Vec3(tmp, 0.5, 0), r: radius, caps: false, color: getColor(symbol2), frames: frames))
                        }

                        // FIXME
                        if molecularModelMode == .skeletal {
                            shapes.append(MYOBJSphere(p: Vec3(tmp, -0.5, 0), r: radius, color: getColor(symbol1), frames: frames))
                            shapes.append(MYOBJSphere(p: Vec3(tmp, 0.5, 0), r: radius, color: getColor(symbol2), frames: frames))
                        }
                    }
                } else if order == 4 { // aromatic bond. dashed.
                    // TODO: Implement
                }
            }
        }
    }



    if let molden = molden, molecularOrbitalMode != .none {
        var lumoLevel: Int!
        for i in 0 ..< molden.molecularOrbitals.count {
            if molden.molecularOrbitals[i].occupation == 0 {
                lumoLevel = i
                break
            }
        }
        let meshes = molden.getMeshes(orbitalLevel: (molecularOrbitalMode == .HOMO) ? lumoLevel - 1 : lumoLevel)
        shapes.append(MYOBJMesh(vertices: meshes[0].vertices, normals: meshes[0].normals, faces: meshes[0].indices, color: 0xFF0000FF))
        shapes.append(MYOBJMesh(vertices: meshes[1].vertices, normals: meshes[1].normals, faces: meshes[1].indices, color: 0xFFFF0000))
    }

    if let dipoleMoment = dipoleMoment {
        // Find the center of mass
        var sx: Float = 0.0, sy: Float = 0.0, sz: Float = 0.0
        var sw: Float = 0.0
        for element in elements {
            let v = element.position
            let w = getWeight(element.symbol)
            sx += v.0 * w
            sy += v.1 * w
            sz += v.2 * w
            sw += w
        }
        let cm = Vec3(sx / sw, sy / sw, sz / sw)

        shapes.append(MYOBJArrow(p1: cm, p2: Vec3(cm.0 + dipoleMoment.0 * 0.5, cm.1 + dipoleMoment.1 * 0.5, cm.2 + dipoleMoment.2 * 0.5), r: 0.06, color: 0x00FF00))
    }

    return MYOBJ(shapes: shapes, animationMode: (vibrations == nil) ? .none : .animation(endTimeCode: 24), boundaries: (min: toVec3(boundaryMin), max: toVec3(boundaryMax)))
}

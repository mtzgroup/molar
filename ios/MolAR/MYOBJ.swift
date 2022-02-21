//
//  MYOBJ.swift
//  MolAR
//
//  Created by Sukolsak on 3/20/21.
//

import Foundation
import simd


protocol MYOBJShape {
}

final class MYOBJSphere: MYOBJShape {
    let p: Vec3
    let r: Float
    let color: Int
    let frames: [(Double, simd_float4x4)]?
    init(p: Vec3, r: Float, color: Int, frames: [(Double, simd_float4x4)]? = nil) {
        self.p = p
        self.r = r
        self.color = color
        self.frames = frames
    }
}

final class MYOBJCylinder: MYOBJShape {
    let p1: Vec3
    let p2: Vec3
    let r: Float
    let caps: Bool
    let color: Int
    let frames: [(Double, simd_float4x4)]?
    init(p1: Vec3, p2: Vec3, r: Float, caps: Bool, color: Int, frames: [(Double, simd_float4x4)]? = nil) {
        self.p1 = p1
        self.p2 = p2
        self.r = r
        self.caps = caps
        self.color = color
        self.frames = frames
    }
}

final class MYOBJArrow: MYOBJShape {
    let p1: Vec3
    let p2: Vec3
    let r: Float
    let color: Int
    init(p1: Vec3, p2: Vec3, r: Float, color: Int) {
        self.p1 = p1
        self.p2 = p2
        self.r = r
        self.color = color
    }
}

final class MYOBJMesh: MYOBJShape {
    let vertices: [Vec3]
    let normals: [Vec3]
    let faces: ContiguousArray<Int>
    let color: Int
    init(vertices: [Vec3], normals: [Vec3], faces: ContiguousArray<Int>, color: Int) {
        self.vertices = vertices
        self.normals = normals
        self.faces = faces
        self.color = color
    }
}

enum MYOBJAnimationMode {
    case none
    case animation(endTimeCode: Int)
}

final class MYOBJ {
    let shapes: [MYOBJShape]
    let animationMode: MYOBJAnimationMode
    let boundaries: (min: Vec3, max: Vec3)
    init(shapes: [MYOBJShape], animationMode: MYOBJAnimationMode, boundaries: (min: Vec3, max: Vec3)) {
        self.shapes = shapes
        self.animationMode = animationMode
        self.boundaries = boundaries
    }
}


typealias Vec3 = (Float, Float, Float)

private final class Mesh {
    var points: [Vec3]
    var normals: [Vec3]
    var faceVertexCounts: ContiguousArray<Int>
    var faceVertexIndices: ContiguousArray<Int>
    let color: Int
    let frames: [(Double, simd_float4x4)]?

    init(_ points: [Vec3], _ normals: [Vec3], _ faceVertexCounts: ContiguousArray<Int>, _ faceVertexIndices: ContiguousArray<Int>, _ color: Int, _ frames: [(Double, simd_float4x4)]?) {
        self.points = points
        self.normals = normals
        self.faceVertexCounts = faceVertexCounts
        self.faceVertexIndices = faceVertexIndices
        self.color = color
        self.frames = frames
    }
}


private var unitSphereCache = [Int: ([Vec3], ContiguousArray<Int>, ContiguousArray<Int>)]()
private func genUnitSphere(_ u: Int, _ v: Int) -> ([Vec3], ContiguousArray<Int>, ContiguousArray<Int>) {
    let cacheKey = u * 10000 + v
    if let tmp = unitSphereCache[cacheKey] {
        return tmp
    }

    var faceVertexIndices = ContiguousArray<Int>()

    for i in 0 ..< u {
        for j in 0 ..< v {
            let k1 = (i - 1) * v + 1 + j
            let k1n =  (j != v-1) ? (k1 + 1) : (k1 - v + 1)

            let k2 = i * v + 1 + j
            let k2n = (j != v-1) ? (k2 + 1) : (k2 - v + 1)

            if i == 0 {
                faceVertexIndices += [0, k2n, k2]
            } else if i < u - 1 {
                faceVertexIndices += [k1, k1n, k2n, k2]
            } else {
                faceVertexIndices += [k1, k1n, (u-1) * v + 1]
            }
        }
    }
    let faceVertexCounts = ContiguousArray<Int>(repeating: 3, count: v) + ContiguousArray<Int>(repeating: 4, count: (u - 2) * v) + ContiguousArray<Int>(repeating: 3, count: v)

    var normals = [Vec3]()

    // normals.append((0, 0, 1))
    for i in 0...u {
        let z = cos(Float.pi * Float(i) / Float(u))
        let rr = sin(Float.pi * Float(i) / Float(u))
        for j in 0..<v {
            let x = sin(Float(j) * 2.0 * Float.pi / Float(v)) * rr
            let y = cos(Float(j) * 2.0 * Float.pi / Float(v)) * rr
            normals.append((x, y, z))
            if i == 0 || i == u {
                break
            }
        }
     }
   // normals.append((0, 0, -1))

    let ret = (normals, faceVertexCounts, faceVertexIndices)
    unitSphereCache[cacheKey] = ret
    return ret
}

private func genSphere(_ p: Vec3, _ r: Float, _ u: Int, _ v: Int, _ color: Int, _ frames: [(Double, simd_float4x4)]?) -> Mesh {
    let (normals, faceVertexCounts, faceVertexIndices) = genUnitSphere(u, v)
    let points = normals.map { normal -> Vec3 in
        return (p.0 + normal.0 * r, p.1 + normal.1 * r, p.2 + normal.2 * r)
    }
    return Mesh(points, normals, faceVertexCounts, faceVertexIndices, color, frames)
}


private var unitCylinderCache = [Int: ([(Float, Float)], ContiguousArray<Int>, ContiguousArray<Int>)]()
private func genUnitCylinder(_ segments: Int) -> ([(Float, Float)], ContiguousArray<Int>, ContiguousArray<Int>) {
    if let tmp = unitCylinderCache[segments] {
        return tmp
    }
    var points = [(Float, Float)]()
    var faceVertexIndices = ContiguousArray<Int>()
    for i in 0..<segments {
        let theta = 2.0 * Float.pi * Float(i) / Float(segments)
        let a = cos(theta)
        let b = sin(theta)
        points.append((a, b))
        let k1 = 2 * i
        let k1n = (2 * i + 2) % (2 * segments)
        let k2 = 2 * i + 1
        let k2n = (2 * i + 3) % (2 * segments)
        faceVertexIndices += [k1, k1n, k2n, k2]
    }
    let faceVertexCounts = ContiguousArray<Int>(repeating: 4, count: segments)

    let ret = (points, faceVertexCounts, faceVertexIndices)
    unitCylinderCache[segments] = ret
    return ret
}

private func genCylinder(_ p1: Vec3, _ p2: Vec3, _ r: Float, _ caps: Bool, _ segments: Int, _ color: Int, _ frames: [(Double, simd_float4x4)]?) -> Mesh {
    let (x1, y1, z1) = p1, (x2, y2, z2) = p2
    var (unit_points, faceVertexCounts, faceVertexIndices) = genUnitCylinder(segments)

    var x = x1 - x2
    var y = y1 - y2
    var z = z1 - z2
    var length = sqrt(x * x + y * y + z * z)
    if length == 0 {
      length = 1
    }
    x /= length
    y /= length
    z /= length

    // Find a vector perpendicular to (x, y, z)
    let u: [Float]
    let v: [Float]
    if x == 0 && y == 0 {
        u = [Float(1.0), Float(0.0), Float(0.0)]
    } else {
        let u_length = sqrt(x*x + y*y)
        u = [y / u_length, -x / u_length, 0]  // u = normalize((x, y, z) crosses (0, 0, 1))
    }
    v = [u[1] * z, -u[0] * z, u[0] * y - u[1] * x]  // v = u crosses (x, y, z)

    var points = [Vec3]()
    var normals = [Vec3]()
    for i in 0 ..< segments {
        let ab = unit_points[i]
        let a = ab.0
        let b = ab.1
        let nx = u[0]*a + v[0]*b
        let ny = u[1]*a + v[1]*b
        let nz = u[2]*a + v[2]*b
        points.append((nx*r + x1, ny*r + y1, nz*r + z1))
        points.append((nx*r + x2, ny*r + y2, nz*r + z2))
        let normal = (nx, ny, nz)
        normals.append(normal)
        normals.append(normal)
    }

    if caps {
        let normal = (x, y, z)
        let normal2 = (-x, -y, -z)
        for i in 0 ..< segments {
            let ab = unit_points[i]
            let a = ab.0
            let b = ab.1
            let nx = u[0]*a + v[0]*b
            let ny = u[1]*a + v[1]*b
            let nz = u[2]*a + v[2]*b
            points.append((nx*r + x1, ny*r + y1, nz*r + z1))
            points.append((nx*r + x2, ny*r + y2, nz*r + z2))
            normals.append(normal)
            normals.append(normal2)
        }

        let k = segments * 2
        points.append(p1)
        points.append(p2)
        normals.append(normal)
        normals.append(normal2)
        for i in 0 ..< segments {
            faceVertexCounts.append(3)
            faceVertexCounts.append(3)
            faceVertexIndices.append(k + k)
            faceVertexIndices.append(k + ((i * 2 + 2) % k))
            faceVertexIndices.append(k + i * 2)
            faceVertexIndices.append(k + k + 1)
            faceVertexIndices.append(k + i * 2 + 1)
            faceVertexIndices.append(k + ((i * 2 + 3) % k))
        }
    }

    return Mesh(points, normals, faceVertexCounts, faceVertexIndices, color, frames)
}

private func genArrow(_ p1: Vec3, _ p2: Vec3, _ r: Float, _ segments: Int, _ color: Int) -> Mesh {
    let (x1, y1, z1) = p1, (x2, y2, z2) = p2
    var (unit_points, faceVertexCounts, faceVertexIndices) = genUnitCylinder(segments)

    var x = x1 - x2
    var y = y1 - y2
    var z = z1 - z2
    var length = sqrt(x * x + y * y + z * z)
    if length == 0 {
      length = 1
    }
    x /= length
    y /= length
    z /= length

    // Find a vector perpendicular to (x, y, z)
    let u: [Float]
    let v: [Float]
    if x == 0 && y == 0 {
        u = [Float(1.0), Float(0.0), Float(0.0)]
    } else {
        let u_length = sqrt(x*x + y*y)
        u = [y / u_length, -x / u_length, 0]  // u = normalize((x, y, z) crosses (0, 0, 1))
    }
    v = [u[1] * z, -u[0] * z, u[0] * y - u[1] * x]  // v = u crosses (x, y, z)

    let p: Float = min(0.3, length) // length of the arrowhead

    var points = [Vec3]()
    var normals = [Vec3]()
    for i in 0 ..< segments {
        let ab = unit_points[i]
        let a = ab.0
        let b = ab.1
        let nx = u[0]*a + v[0]*b
        let ny = u[1]*a + v[1]*b
        let nz = u[2]*a + v[2]*b
        points.append((nx*r + x1, ny*r + y1, nz*r + z1))
        points.append((nx*r + x2 + p*x, ny*r + y2 + p*y, nz*r + z2 + p*z))
        let normal = (nx, ny, nz)
        normals.append(normal)
        normals.append(normal)
    }

    do {
        let normal = (x, y, z)
        let r2 = r * 3 // radius of the base of the arrowhead

        for i in 0 ..< segments {
            let ab = unit_points[i]
            let a = ab.0
            let b = ab.1
            let nx = u[0]*a + v[0]*b
            let ny = u[1]*a + v[1]*b
            let nz = u[2]*a + v[2]*b
            points.append((nx*r + x1, ny*r + y1, nz*r + z1))
            points.append((nx*r2 + x2 + p*x, ny*r2 + y2 + p*y, nz*r2 + z2 + p*z))
            normals.append(normal)
            normals.append(normal)
        }

        let k = segments * 2
        points.append(p1)
        points.append((x2 + p*x, y2 + p*y, z2 + p*z))
        normals.append(normal)
        normals.append(normal)
        for i in 0 ..< segments {
            faceVertexCounts.append(3)
            faceVertexCounts.append(3)
            faceVertexIndices.append(k + k)
            faceVertexIndices.append(k + ((i * 2 + 2) % k))
            faceVertexIndices.append(k + i * 2)
            faceVertexIndices.append(k + k + 1)
            faceVertexIndices.append(k + ((i * 2 + 3) % k))
            faceVertexIndices.append(k + i * 2 + 1)
        }


        // Arrowhead (cone)
        let q: Float = r2 / p
        let l = sqrt(1 + q * q)
        for i in 0 ..< segments {
            let ab = unit_points[i]
            let a = ab.0
            let b = ab.1
            let nx = u[0]*a + v[0]*b
            let ny = u[1]*a + v[1]*b
            let nz = u[2]*a + v[2]*b
            points.append((nx*r2 + x2 + p*x, ny*r2 + y2 + p*y, nz*r2 + z2 + p*z))
            let normal = ((nx - q * x) / l, (ny - q * y) / l, (nz - q * z) / l)
            normals.append(normal)
        }

        let tmp = segments * 4 + 2
        for i in 0 ..< segments {
            points.append(p2) // The tip
            let normal1 = normals[tmp + i]
            let normal2 = normals[tmp + ((i + 1) % segments)]
            normals.append(( // Should normalize
                (normal1.0 + normal2.0) * 0.5,
                (normal1.1 + normal2.1) * 0.5,
                (normal1.2 + normal2.2) * 0.5
            ))
        }

        for i in 0 ..< segments {
            faceVertexCounts.append(3)
            faceVertexIndices.append(tmp + i)
            faceVertexIndices.append(tmp + ((i + 1) % segments))
            faceVertexIndices.append(tmp + i + segments)
        }
    }

    return Mesh(points, normals, faceVertexCounts, faceVertexIndices, color, nil)
}

private func genMesh(_ vs: [Vec3], _ normals: [Vec3], _ faces: ContiguousArray<Int>, _ color: Int) -> Mesh {
    let faceVertexCounts = ContiguousArray<Int>(repeating: 3, count: faces.count / 3)

    return Mesh(vs, normals, faceVertexCounts, faces, color, nil)
}


private func insertMesh(_ meshes: inout [Mesh], _ meshByColor: inout [Int: Mesh], _ mesh: Mesh) {
    if mesh.frames == nil {
        if let mesh2 = meshByColor[mesh.color] {
            let offset = mesh2.points.count
            mesh2.points += mesh.points
            mesh2.normals += mesh.normals
            mesh2.faceVertexCounts += mesh.faceVertexCounts
            mesh2.faceVertexIndices += mesh.faceVertexIndices.map { offset &+ $0 }
        } else {
            meshByColor[mesh.color] = mesh
            meshes.append(mesh)
        }
    } else {
        meshes.append(mesh)
    }
}


func convertMYOBJToUSDZ(_ myobj: MYOBJ, defaultScale: Float = 8.0) -> Data {
    let shapes = myobj.shapes

    var meshByColor = [Int: Mesh]()
    var meshes = [Mesh]()

    /*
    var min_x = Float.infinity
    var min_y = Float.infinity
    var min_z = Float.infinity
    var max_x = -Float.infinity
    var max_y = -Float.infinity
    var max_z = -Float.infinity

    for shape in shapes {
        if let sphere = shape as? MYOBJSphere {
            let r = sphere.r
            let p = sphere.p
            if p.0 - r < min_x { min_x = p.0 - r }
            if p.1 - r < min_y { min_y = p.1 - r }
            if p.2 - r < min_z { min_z = p.2 - r }
            if p.0 + r > max_x { max_x = p.0 + r }
            if p.1 + r > max_y { max_y = p.1 + r }
            if p.2 + r > max_z { max_z = p.2 + r }
        } /*else if let cylinder = shape as? MYOBJCylinder {
            if cylinder.p1.0 - cylinder.r < min_x { min_x = cylinder.p1.0 - cylinder.r }
            if cylinder.p1.1 - cylinder.r < min_y { min_y = cylinder.p1.1 - cylinder.r }
            if cylinder.p1.2 - cylinder.r < min_z { min_z = cylinder.p1.2 - cylinder.r }
            if cylinder.p1.0 + cylinder.r > max_x { max_x = cylinder.p1.0 + cylinder.r }
            if cylinder.p1.1 + cylinder.r > max_y { max_y = cylinder.p1.1 + cylinder.r }
            if cylinder.p1.2 + cylinder.r > max_z { max_z = cylinder.p1.2 + cylinder.r }
            if cylinder.p2.0 - cylinder.r < min_x { min_x = cylinder.p2.0 - cylinder.r }
            if cylinder.p2.1 - cylinder.r < min_y { min_y = cylinder.p2.1 - cylinder.r }
            if cylinder.p2.2 - cylinder.r < min_z { min_z = cylinder.p2.2 - cylinder.r }
            if cylinder.p2.0 + cylinder.r > max_x { max_x = cylinder.p2.0 + cylinder.r }
            if cylinder.p2.1 + cylinder.r > max_y { max_y = cylinder.p2.1 + cylinder.r }
            if cylinder.p2.2 + cylinder.r > max_z { max_z = cylinder.p2.2 + cylinder.r }
        }*/
    }
     */

    for shape in shapes {
        let mesh: Mesh
        if let sphere = shape as? MYOBJSphere {
            mesh = genSphere(sphere.p, sphere.r, 16, 32, sphere.color, sphere.frames)
        } else if let cylinder = shape as? MYOBJCylinder {
            mesh = genCylinder(cylinder.p1, cylinder.p2, cylinder.r, cylinder.caps, 16, cylinder.color, cylinder.frames)
        } else if let mesh2 = shape as? MYOBJMesh {
            mesh = genMesh(mesh2.vertices, mesh2.normals, mesh2.faces, mesh2.color)
        } else if let arrow = shape as? MYOBJArrow {
            mesh = genArrow(arrow.p1, arrow.p2, arrow.r, 16, arrow.color)
        } else {
            fatalError()
        }
        insertMesh(&meshes, &meshByColor, mesh)
    }

    let (min: (min_x, min_y, min_z), max: (max_x, max_y, max_z)) = myobj.boundaries
    let translate: [Float] = [
        -(min_x + max_x) / Float(2.0),
        -min_y,
        -(min_z + max_z) / Float(2.0)
    ]

    let size = max(max_x - min_x, max_y - min_y, max_z - min_z)
    let scale = min(defaultScale, Float(40.0) / size)


    let root = UsdData("", "")

    if case .animation(let endTimeCode) = myobj.animationMode {
        root.metadata["startTimeCode"] = 0
        root.metadata["endTimeCode"] = endTimeCode
    }

    let usdObj = root.createChild("ar", "Xform")
    do {
        //usdObj.metadata["assetInfo"] = ["name": "ar"]
        //usdObj.metadata["kind"] = "component"
        usdObj.addAttribute(UsdAttribute("xformOp:scale", [scale, scale, scale], ValueType.vec3f, "float3"))
        usdObj.addAttribute(UsdAttribute("xformOp:translate", translate, ValueType.vec3f, "float3"))
        let tmp = UsdAttribute("xformOpOrder", ["xformOp:scale", "xformOp:translate"], ValueType.token, "token[]", true)
        tmp.addQualifier("uniform")
        usdObj.addAttribute(tmp)
    }

    let materialsScope = usdObj.createChild("Materials", "Scope")
    var materialMap = [Int: UsdPrim]()

    var refId = 0
    //for (color, mesh) in meshByColor {
    for mesh in meshes {
        let color = mesh.color
        var usdMaterial = materialMap[color]
        if usdMaterial == nil {
            let r = Float((color >> 16) & 255) / 255.0
            let g = Float((color >> 8) & 255) / 255.0
            let b = Float(color & 255) / 255.0
            let rgb = [r, g, b]
            usdMaterial = materialsScope.createChild("k" + String(refId), "Material")

            let usdShader = usdMaterial!.createChild("shader", "Shader")
            let tmp = UsdAttribute("info:id", "UsdPreviewSurface", ValueType.token, "token")
            tmp.addQualifier("uniform")
            usdShader.addAttribute(tmp)
            usdShader.addAttribute(UsdAttribute("inputs:diffuseColor", rgb, ValueType.vec3f, "color3f"))
            if (color >> 24) > 0 {
                usdShader.addAttribute(UsdAttribute("inputs:opacity", Float(0.5), ValueType.float, "float"))
            }
            usdShader.addAttribute(UsdAttribute("inputs:roughness", Float(0.2), ValueType.float, "float"))
            let surface = UsdAttribute("outputs:surface", nil, ValueType.token, "token")
            usdShader.addAttribute(surface)

            usdMaterial!.addAttribute(UsdAttribute("outputs:surface", surface, ValueType.Invalid, "token"))
            materialMap[color] = usdMaterial
        }

        let usdMesh = usdObj.createChild("m" + String(refId), "Mesh")
        usdMesh.addAttribute(UsdAttribute("material:binding", usdMaterial, ValueType.Invalid, "rel"))
        // usdMesh.addAttribute(UsdAttribute("doubleSided", false, ValueType.bool, "bool"))
        usdMesh.addAttribute(UsdAttribute("faceVertexCounts", mesh.faceVertexCounts, ValueType.int, "int[]", true))
        usdMesh.addAttribute(UsdAttribute("faceVertexIndices", mesh.faceVertexIndices, ValueType.int, "int[]", true))
        usdMesh.addAttribute(UsdAttribute("points", mesh.points, ValueType.vec3f, "point3f[]", true))
        let tmp2 = UsdAttribute("primvars:normals", mesh.normals, ValueType.vec3f, "normal3f[]", true)
        tmp2.metadata["interpolation"] = "vertex"
        usdMesh.addAttribute(tmp2)
        let tmp3 = UsdAttribute("subdivisionScheme", "none", ValueType.token, "token")
        tmp3.addQualifier("uniform")
        usdMesh.addAttribute(tmp3)

        if let frames = mesh.frames {
            let tmp4 = UsdAttribute("xformOp:transform:t", nil, ValueType.matrix4d, "matrix4d")
            for (frame, v) in frames {
                tmp4.addTimeSample(frame, v)
            }
            usdMesh.addAttribute(tmp4)

            let tmp5 = UsdAttribute("xformOpOrder", ["xformOp:transform:t"], ValueType.token, "token[]", true)
            tmp5.addQualifier("uniform")
            usdMesh.addAttribute(tmp5)
        }

        refId += 1
    }

    if case .animation(_) = myobj.animationMode {
        // Create a dummy invisible mesh to force iOS to use the correct bounds.
        // iOS seems to determine the bounds from only the 1st frame and ignore other frames.
        let usdMesh = usdObj.createChild("md", "Mesh")
        usdMesh.addAttribute(UsdAttribute("faceVertexCounts", ContiguousArray<Int>([3]), ValueType.int, "int[]", true))
        usdMesh.addAttribute(UsdAttribute("faceVertexIndices", ContiguousArray<Int>([0, 0, 0]), ValueType.int, "int[]", true))
        usdMesh.addAttribute(UsdAttribute("points", [Vec3(-translate[0], -translate[1], -translate[2])], ValueType.vec3f, "point3f[]", true))
        let tmp2 = UsdAttribute("primvars:normals", [Vec3(0, 1, 0)], ValueType.vec3f, "normal3f[]", true)
        tmp2.metadata["interpolation"] = "vertex"
        usdMesh.addAttribute(tmp2)
        let tmp3 = UsdAttribute("subdivisionScheme", "none", ValueType.token, "token")
        tmp3.addQualifier("uniform")
        usdMesh.addAttribute(tmp3)
    }

    let crateFile = CrateFile()
    crateFile.writeUsd(root)

    let usdzFile = UsdzFile()
    usdzFile.addFile(crateFile.bytes, "tmp.usdc")
    usdzFile.close()

    return Data(usdzFile.file.bytes)
}

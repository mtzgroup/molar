//
//  Molden.swift
//  MolAR
//
//  Created by Sukolsak on 10/10/21.
//

import Foundation
import simd


private let ONE_OVER_PI_TO_3_OVER_4: Float = 0.423777208123757596791 // 1 / PI ^ (3/4)
private let ANGSTROM2BOHR: Float = 1.889725989
private let ROOT3: Float = 1.7320508075688772935274

private func calculateNorm(azimuthalQuantumNumber: Int, exponent: Float, contraction: Float) -> Float {
    let tmp: Float
    if azimuthalQuantumNumber == 0 { // s
        tmp = pow(2 * exponent, 0.75) * ONE_OVER_PI_TO_3_OVER_4 // (2 * exponent / PI) ^ (3/4)
    } else if azimuthalQuantumNumber == 1 { // p
        tmp = pow(exponent, 1.25) * 3.36358566101485817212450 * ONE_OVER_PI_TO_3_OVER_4 // ( 128 * exponent^5 / PI^3) ^ (1/4)
    } else { // d
        tmp = pow(exponent, 1.75) * 6.72717132202971634424900 * ONE_OVER_PI_TO_3_OVER_4 // (2048 * exponent^7 / PI^3) ^ (1/4)
    }
    return contraction * tmp
}


private struct MoldenAtom {
    let position: SIMD3<Float>
}

private final class MoldenPrimitive {
    let exponent: Float
    // let contraction: Float
    let norm: Float

    internal init(exponent: Float, norm: Float) {
        self.exponent = exponent
        // self.contraction = contraction
        self.norm = norm
    }
}

private final class MoldenAtomicOrbital {
    internal init(azimuthalQuantumNumber: Int, atomIndex: Int, primitives: [MoldenPrimitive]) {
        self.azimuthalQuantumNumber = azimuthalQuantumNumber
        self.atomIndex = atomIndex
        self.primitives = primitives
    }

    let azimuthalQuantumNumber: Int
    let atomIndex: Int
    let primitives: [MoldenPrimitive]
}

final class MoldenMolecularOrbital {
    // var energy: Float
    var occupation: Int
    var coefficients: [Float]

    internal init(energy: Float, occupation: Int, coefficients: [Float]) {
        // self.energy = energy
        self.occupation = occupation
        self.coefficients = coefficients
    }
}

final class MoldenFile {
    private let atoms: [MoldenAtom]
    private let atomicOrbitals: [MoldenAtomicOrbital]
    let molecularOrbitals: [MoldenMolecularOrbital]

    init(moldenString: String) {
        let lines = moldenString.split(separator: "\n", maxSplits: Int.max, omittingEmptySubsequences: false)
        var i = 0
        var state = 0
        var state2 = 0
        var atoms = [MoldenAtom]()
        var atomicOrbitals = [MoldenAtomicOrbital]()
        var atomIndex = 0
        var molecularOrbitals = [MoldenMolecularOrbital]()
        var orbital: MoldenMolecularOrbital!
        while i < lines.count {
            let line = lines[i]
            i += 1
            if line.prefix(1) == "[" {
                if line.starts(with: "[Atoms]") {
                    state = 1
                } else if line.starts(with: "[GTO]") {
                    state = 2
                    state2 = 0
                } else if line.starts(with: "[MO]") {
                    state = 3
                    state2 = 1
                } else {
                    state = 0
                }
            } else if state == 1 { // Atoms
                let tmp = line.split(separator: " ")
                atoms.append(MoldenAtom(position: simd_float3(Float(tmp[3])!, Float(tmp[4])!, Float(tmp[5])! )))
            } else if state == 2 { // GTO
                if state2 == 0 {
                    atomIndex = Int(line.split(separator: " ")[0])! - 1
                    state2 = 1
                } else if state2 == 1 {
                    if line == "" {
                        state2 = 0
                    } else {
                        let tmp = line.split(separator: " ")
                        let subshell = String(tmp[0])
                        let nPrimitives = Int(tmp[1])!
                        let azimuthalQuantumNumber: Int
                        if subshell == "s" {
                            azimuthalQuantumNumber = 0
                        } else if subshell == "p" {
                            azimuthalQuantumNumber = 1
                        } else if subshell == "d" {
                            azimuthalQuantumNumber = 2
                        } else {
                            fatalError("Only subshells s, p, and d are supported.")
                        }
                        var primitives = [MoldenPrimitive]()
                        for _ in 0 ..< nPrimitives {
                            let line2 = lines[i]
                            let tmp2 = line2.split(separator: " ")

                            let exponent = Float(tmp2[0])!
                            let contraction = Float(tmp2[1])!
                            let norm = calculateNorm(azimuthalQuantumNumber: azimuthalQuantumNumber, exponent: exponent, contraction: contraction)
                            primitives.append(MoldenPrimitive(exponent: exponent, norm: norm))
                            i += 1
                        }
                        atomicOrbitals.append(MoldenAtomicOrbital(azimuthalQuantumNumber: azimuthalQuantumNumber, atomIndex: atomIndex, primitives: primitives))
                    }
                }
            } else if state == 3 { // MO
                if let tmp = line.range(of: "=") {
                    if state2 == 1 {
                        orbital = MoldenMolecularOrbital(energy: 0, occupation: 0, coefficients: [])
                        state2 = 0
                        molecularOrbitals.append(orbital)
                    }
                    let attr = line[..<tmp.lowerBound].trimmingCharacters(in: .whitespaces)
                    let value = line[tmp.upperBound...].trimmingCharacters(in: .whitespaces)
                    // if attr == "Ene" {
                    //     orbital.energy = Float(value)!
                    // }
                    if attr == "Occup" {
                        orbital.occupation = Int(Float(value)!)
                    }
                } else if line != "" {
                    let tmp2 = line.split(separator: " ")
                    //let aoNumber = Int(tmp2[0])
                    let coefficient = Float(tmp2[1])!
                    orbital.coefficients.append(coefficient)
                    state2 = 1
                }
            }
        }

        self.atoms = atoms
        self.atomicOrbitals = atomicOrbitals
        self.molecularOrbitals = molecularOrbitals
    }

    init(bmolden: Data) {
        var atoms = [MoldenAtom]()
        var atomicOrbitals = [MoldenAtomicOrbital]()
        var molecularOrbitals = [MoldenMolecularOrbital]()
        bmolden.withUnsafeBytes { p in
            let nAtoms = p.load(fromByteOffset: 0, as: UInt32.self)
            var i = 4
            for _ in 0 ..< nAtoms {
                let x = p.load(fromByteOffset: i, as: Float.self)
                let y = p.load(fromByteOffset: i + 4, as: Float.self)
                let z = p.load(fromByteOffset: i + 8, as: Float.self)
                atoms.append(MoldenAtom(position: simd_float3(x, y, z )))
                i += 12
            }

            let nAtomicOrbitals = p.load(fromByteOffset: i, as: UInt32.self)
            i += 4
            for _ in 0 ..< nAtomicOrbitals {
                //let azimuthalQuantumNumber = Int(p.load(fromByteOffset: i, as: UInt32.self))
                //let atomIndex = Int(p.load(fromByteOffset: i + 4, as: UInt32.self))
                //let nPrimitives = p.load(fromByteOffset: i + 8, as: UInt32.self)
                //i += 12
                let atomIndex = Int(p.load(fromByteOffset: i, as: UInt16.self))
                let azimuthalQuantumNumber = Int(p.load(fromByteOffset: i + 2, as: UInt8.self))
                let nPrimitives = p.load(fromByteOffset: i + 3, as: UInt8.self)
                i += 4
                var primitives = [MoldenPrimitive]()
                for _ in 0 ..< nPrimitives {
                    let exponent = p.load(fromByteOffset: i, as: Float.self)
                    let contraction = p.load(fromByteOffset: i + 4, as: Float.self)
                    let norm = calculateNorm(azimuthalQuantumNumber: azimuthalQuantumNumber, exponent: exponent, contraction: contraction)
                    primitives.append(MoldenPrimitive(exponent: exponent, norm: norm))
                    i += 8
                }
                atomicOrbitals.append(MoldenAtomicOrbital(azimuthalQuantumNumber: azimuthalQuantumNumber, atomIndex: atomIndex, primitives: primitives))
            }

            //let nMolecularOrbitals = p.load(fromByteOffset: i, as: UInt32.self)
            //i += 4
            let nMolecularOrbitals = 2  // Only have HOMO and LUMO
            let nCoefficients = p.load(fromByteOffset: i, as: UInt32.self)
            i += 4
            for j in 0 ..< nMolecularOrbitals {
                //let energy = p.load(fromByteOffset: i, as: Float.self)
                //let occupation = Int(p.load(fromByteOffset: i + 4, as: UInt32.self))
                //let nCoefficients = p.load(fromByteOffset: i + 8, as: UInt32.self)
                //i += 12
                let energy: Float = 0 // Not used
                let occupation = 1 - j // Fake occupation number, to indicate HOMO/LUMO
                var coefficients = [Float]()
                for _ in 0 ..< nCoefficients {
                    let coefficient = p.load(fromByteOffset: i, as: Float.self)
                    coefficients.append(coefficient)
                    i += 4
                }
                molecularOrbitals.append(MoldenMolecularOrbital(energy: energy, occupation: occupation, coefficients: coefficients))
            }
        }

        self.atoms = atoms
        self.atomicOrbitals = atomicOrbitals
        self.molecularOrbitals = molecularOrbitals
    }

    func getMeshes(orbitalLevel: Int) -> [MCMesh] {
        var min_x = Float.infinity
        var min_y = Float.infinity
        var min_z = Float.infinity
        var max_x = -Float.infinity
        var max_y = -Float.infinity
        var max_z = -Float.infinity

        for atom in atoms {
            let p = atom.position
            if p.x < min_x { min_x = p.x }
            if p.y < min_y { min_y = p.y }
            if p.z < min_z { min_z = p.z }
            if p.x > max_x { max_x = p.x }
            if p.y > max_y { max_y = p.y }
            if p.z > max_z { max_z = p.z }
        }

        let n = 60
        var data = [Float](repeating: 0, count: n * n * n)
        let padding: Float = 2.3
        let b1 = Vec3(min_x - padding, min_y - padding, min_z - padding)
        let b2 = Vec3(max_x + padding, max_y + padding, max_z + padding)

        let kx: Float = (b2.0 - b1.0) / Float(n - 1)
        let ky: Float = (b2.1 - b1.1) / Float(n - 1)
        let kz: Float = (b2.2 - b1.2) / Float(n - 1)

        let coefficients = molecularOrbitals[orbitalLevel].coefficients

        var aoOffset = 0

        var dxs = [Float](repeating: 0, count: n)
        var dys = [Float](repeating: 0, count: n)
        var dzs = [Float](repeating: 0, count: n)

        for atomicOrbital in atomicOrbitals {
            let atom = atoms[atomicOrbital.atomIndex]

            for x in 0 ..< n {
                dxs[x] = ((Float(x) * kx + b1.0) - atom.position.x) * ANGSTROM2BOHR
            }
            for y in 0 ..< n {
                dys[y] = ((Float(y) * ky + b1.1) - atom.position.y) * ANGSTROM2BOHR
            }
            for z in 0 ..< n {
                dzs[z] = ((Float(z) * kz + b1.2) - atom.position.z) * ANGSTROM2BOHR
            }

            var p = 0
            for x in 0 ..< n {
                let dx = dxs[x]
                let dx2 = dx * dx
                for y in 0 ..< n {
                    let dy = dys[y]
                    let dy2 = dy * dy
                    for z in 0 ..< n {
                        let dz = dzs[z]
                        let dz2 = dz * dz

                        let tmp: Float
                        if atomicOrbital.azimuthalQuantumNumber == 0 { // s
                            tmp = coefficients[aoOffset]
                        } else if atomicOrbital.azimuthalQuantumNumber == 1 { // p
                            tmp = (
                                coefficients[aoOffset] * dx +
                                coefficients[aoOffset + 1] * dy +
                                coefficients[aoOffset + 2] * dz
                            )
                        } else { // d
                            tmp = (
                                coefficients[aoOffset] / ROOT3 * dx2 +
                                coefficients[aoOffset + 1] / ROOT3 * dy2 +
                                coefficients[aoOffset + 2] / ROOT3 * dz2 +
                                coefficients[aoOffset + 3] * (dx * dy) +
                                coefficients[aoOffset + 4] * (dx * dz) +
                                coefficients[aoOffset + 5] * (dy * dz)
                            )
                        }

                        var tmp2: Float = 0
                        let r2 = dx2 + dy2 + dz2
                        for primitive in atomicOrbital.primitives {
                            tmp2 += primitive.norm * exp(-primitive.exponent * r2)
                        }

                        data[p] += tmp * tmp2
                        p += 1
                    }
                }
            }

            if atomicOrbital.azimuthalQuantumNumber == 0 { // s
                aoOffset &+= 1
            } else if atomicOrbital.azimuthalQuantumNumber == 1 { // p
                aoOffset &+= 3
            } else { // d
                aoOffset &+= 6
            }
        }

        let mesh1 = computeMarchingCubesMesh(data: data, dimensions: [n, n, n], isoLevel: 0.05)
        let mesh2 = computeMarchingCubesMesh(data: data, dimensions: [n, n, n], isoLevel: -0.05)
        func adjustVertices(_ vertices: inout [Vec3]) {
            for i in 0 ..< vertices.count {
                vertices[i].0 = vertices[i].0 * kx + b1.0
                vertices[i].1 = vertices[i].1 * ky + b1.1
                vertices[i].2 = vertices[i].2 * kz + b1.2
            }
        }
        adjustVertices(&mesh1.vertices)
        adjustVertices(&mesh2.vertices)
        return [mesh1, mesh2]
    }
}

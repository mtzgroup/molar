//
//  SDF.swift
//  MolAR
//
//  Created by Sukolsak on 10/10/21.
//

import Foundation

struct SDFElement {
    let symbol: String
    let position: Vec3
}

struct SDFBond {
    let a: Int
    let b: Int
    let order: Int
}

struct SDFStructure {
    let elements: [SDFElement]
    let bonds: [SDFBond]
}

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: min(self.count - range.lowerBound, range.upperBound - range.lowerBound))
        return String(self[start..<end])
    }

    subscript(_ range: CountablePartialRangeFrom<Int>) -> String {
        let start = index(startIndex, offsetBy: range.lowerBound)
        return String(self[start...])
    }
}

func parseSDF(_ s: String) -> SDFStructure {
    var structures = [SDFStructure]()
    let lines = s.split(separator: "\n", maxSplits: Int.max, omittingEmptySubsequences: false)
    let i = 0
    while i + 3 < lines.count {
        let infoLine = String(lines[i + 3])
        let nAtoms = Int(infoLine[0..<3].trimmingCharacters(in: .whitespaces))!
        let nBonds = Int(infoLine[3..<6].trimmingCharacters(in: .whitespaces))!

        var elements = [SDFElement]()
        var bonds = [SDFBond]()

        // Read atoms
        for j in 0 ..< nAtoms {
            let line = String(lines[i + 4 + j])
            let v: Vec3 = (
                Float(line[0..<10].trimmingCharacters(in: .whitespaces))!,
                Float(line[10..<20].trimmingCharacters(in: .whitespaces))!,
                Float(line[20..<30].trimmingCharacters(in: .whitespaces))!
            )
            let symbol = line[31..<34].trimmingCharacters(in: .whitespaces).uppercased()
            elements.append(SDFElement(symbol: symbol, position: v))
        }

        // Read bonds
        for j in 0 ..< nBonds {
            let line = String(lines[i + 4 + nAtoms + j])
            var a = Int(line[0..<3].trimmingCharacters(in: .whitespaces))! - 1
            var b = Int(line[3..<6].trimmingCharacters(in: .whitespaces))! - 1
            if a > b {
                swap(&a, &b)
            }
            let order = Int(line[6..<9].trimmingCharacters(in: .whitespaces))!
            bonds.append(SDFBond(a: a, b: b, order: order))
        }
        let structure = SDFStructure(elements: elements, bonds: bonds)
        structures.append(structure)
        // if !isTrajectory {
            break
        // }
        // i += 4 + nAtoms + nBonds + 2
    }
    return structures[0] // For now. No support for trajectory.
}

func parseBSDF(_ data: Data) -> SDFStructure {
    var elements = [SDFElement]()
    var bonds = [SDFBond]()
    data.withUnsafeBytes { p in
        let nAtoms = p.load(fromByteOffset: 0, as: UInt32.self)
        let nBonds = p.load(fromByteOffset: 4, as: UInt32.self)
        var i = 8
        for _ in 0 ..< nAtoms {
            var symbol = ""
            var tmp = p.load(fromByteOffset: i, as: UInt32.self)
            while tmp > 0 {
                symbol += String(UnicodeScalar(UInt8(tmp & 0xFF)))
                tmp = tmp &>> 8
            }
            let v: Vec3 = (
                p.load(fromByteOffset: i + 4, as: Float.self),
                p.load(fromByteOffset: i + 8, as: Float.self),
                p.load(fromByteOffset: i + 12, as: Float.self)
            )
            elements.append(SDFElement(symbol: symbol, position: v))
            i += 16
        }
        for _ in 0 ..< nBonds {
            let a = Int(p.load(fromByteOffset: i, as: UInt32.self))
            let b = Int(p.load(fromByteOffset: i + 4, as: UInt32.self))
            let order = Int(p.load(fromByteOffset: i + 8, as: UInt32.self))
            bonds.append(SDFBond(a: a, b: b, order: order))
            i += 12
        }
    }
    return SDFStructure(elements: elements, bonds: bonds)
}

private func escapeSMILES(_ smiles: String) -> String {
    return smiles.replacingOccurrences(of: "\n", with: "")
        .replacingOccurrences(of: "%", with: "%25")
        .replacingOccurrences(of: "#", with: "%23")
        .replacingOccurrences(of: "[", with: "%5B")
        .replacingOccurrences(of: "\\", with: "%5C")
        .replacingOccurrences(of: "]", with: "%5D")
        .replacingOccurrences(of: " ", with: "%20")
}

func getSDFFromSMILES(_ smiles: String, completionHandler: @escaping (String?) -> Void) {
    getSDFFromSMILES(smiles, 0, completionHandler: completionHandler)
}

private func getSDFFromSMILES(_ smiles: String, _ attempt: Int, completionHandler: @escaping (String?) -> Void) {
    // TODO: Cache
    let url: URL
    if attempt == 0 {
        url = URL(string: "https://cactus.nci.nih.gov/chemical/structure/" + escapeSMILES(smiles) + "/file?format=sdf&get3d=true")!
    } else if attempt == 1 {
        url = URL(string: "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/" + escapeQuery(smiles) + "/SDF?record_type=3d")!
    } else {
        url = URL(string: "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/smiles/" + escapeQuery(smiles) + "/SDF?record_type=3d")!
    }

    let session: URLSession
    if attempt == 0 {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 4
        configuration.timeoutIntervalForResource = 4
        session = URLSession(configuration: configuration)
    } else {
        session = URLSession.shared
    }
    let task = session.dataTask(with: url) {(data, response, error) in
        guard let data = data,
              let httpURLResponse = response as? HTTPURLResponse,
              httpURLResponse.statusCode == 200 else {
            if attempt < 2 {
                getSDFFromSMILES(smiles, attempt + 1, completionHandler: completionHandler)
            } else {
                completionHandler(nil)
            }
            return
        }
        let sdf = String(decoding: data, as: UTF8.self)
        completionHandler(sdf)
    }
    task.resume()
}

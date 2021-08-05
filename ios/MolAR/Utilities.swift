//
//  Utilities.swift
//  MolAR
//
//  Created by Sukolsak on 2/17/21.
//

import Foundation
import ARKit


private func isNumber(_ x: UInt8) -> Bool {
    return x >= 48 && x <= 57
}
private func isLetter(_ x: UInt8) -> Bool {
    return (65 <= x && x <= 90) || (97 <= x && x <= 122)
}
func isNamePDB(_ query: String) -> Bool {
    let xs = query.compactMap { $0.asciiValue }
    return xs.count == 4 && isNumber(xs[0]) && xs[1...].allSatisfy { isNumber($0) || isLetter($0) }
}
func isNamePotentiallyPDB(_ query: String) -> Bool {
    let xs = query.compactMap { $0.asciiValue }
    return xs.count >= 2 && xs.count <= 4 && isNumber(xs[0]) && xs[1...].allSatisfy { isNumber($0) || isLetter($0) }
}
func isNamePotentiallySMILESOrMoleculeName(_ query: String) -> Bool {
    if query.count == 1 {
        let a: [Character] = ["H", "B", "C", "c", "N", "n", "O", "o", "F", "P", "S", "s", "K", "V", "Y", "I", "i", "W"]
        return a.contains(query[query.startIndex])
    }
    let xs = query.compactMap { $0.asciiValue }
    return xs.count >= 1 && !isNamePotentiallyPDB(query) && xs.contains { isLetter($0) }
}
/*
func isNamePotentiallySMILES(_ query: String) -> Bool {
    let xs = query.compactMap { $0.asciiValue }
    // . - = # $ : / \ [ ] ( ) + @ %
    let s: Set<UInt8> = [46, 45, 61, 35, 36, 58, 47, 92, 91, 93, 40, 41, 43, 64, 37]
    return xs.count >= 1 && !isNumber(xs[0]) && xs.allSatisfy { isNumber($0) || isLetter($0) || s.contains($0) } && xs.contains { isLetter($0) }
}
*/
func escapeQuery(_ s: String) -> String {
    var set = NSCharacterSet.urlQueryAllowed
    set.remove(charactersIn: "/") // So that slashes are escaped.
    return s.addingPercentEncoding(withAllowedCharacters: set)!
}

// MARK: - float4x4 extensions

extension float4x4 {
    /**
     Treats matrix as a (right-hand column-major convention) transform matrix
     and factors out the translation component of the transform.
    */
    var translation: SIMD3<Float> {
        get {
            let translation = columns.3
            return [translation.x, translation.y, translation.z]
        }
        /*
        set(newValue) {
            columns.3 = [newValue.x, newValue.y, newValue.z, columns.3.w]
        }
        */
    }
}

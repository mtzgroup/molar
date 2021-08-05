//
//  CrateFile.swift
//  MolAR
//
//  Created by Sukolsak on 3/19/21.
//

import Foundation
import simd

// Modified from https://github.com/robmcrosby/BlenderUSDZ

private let IS_ARRAY_BIT: UInt64 = (1 << 63)
private let IS_INLINE_BIT: UInt64 = (1 << 62)
private let IS_COMPRESSED_BIT: UInt64 = (1 << 61)
private let PAYLOAD_MASK: UInt64 = (1 << 48) - 1

private struct FieldKey: Hashable {
    private let field: Int
    private let rep: UInt64

    init(_ field: Int, _ rep: UInt64) {
        self.field = field
        self.rep = rep
    }

    static func == (lhs: FieldKey, rhs: FieldKey) -> Bool {
        return lhs.field == rhs.field && lhs.rep == rhs.rep
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(field)
        hasher.combine(rep)
    }
}

final class CrateFile {
    private let writer = Writer()
    private var toc = [(String, Int, Int)]()
    private var tokenToTokenIndex = [String: Int]()
    private var tokens = [String]()
    private var strings = [Int]()
    private var fields = ContiguousArray<Int>()
    private var reps = [UInt64]()
    private var fieldToFieldIndex = [FieldKey: Int]()
    private var fsets = ContiguousArray<Int>()
    private var paths = [(Int, Int, Int)]()
    private var specs = [(Int, Int, Int)]()
    // private var writtenData = {}
    private var framesRef: Int = -1

    private func addWrittenData(_ data: Any, _ vType: ValueType, _ ref: Int) {
        // MOLAR: Not implemented.
        /*
        let key = (dataKey(data), vType)
        writtenData[key] = ref
         */
    }

    private func getDataRefrence(_ data: Any, _ vType: ValueType) -> Int {
        // MOLAR: Not implemented.
        return -1
        /*
        let key = (dataKey(data), vType)
        if key in self.writtenData {
            return self.writtenData[key]
        }
        return -1
         */
    }

    private func getTokenIndex(_ token: String) -> Int {
        if let tmp = tokenToTokenIndex[token] {
            return tmp
        }
        let tmp = self.tokens.count
        tokenToTokenIndex[token] = tmp
        tokens.append(token)
        return tmp
    }

    private func getStringIndex(_ str: String) -> Int {
        let tokenIndex = getTokenIndex(str)
        if let i = strings.firstIndex(of: tokenIndex) {
            return i
        }
        strings.append(tokenIndex)
        return strings.count - 1
    }

    private func addFieldSet(_ fset: [Int]) -> Int {
        let index = fsets.count
        fsets += fset
        fsets.append(-1)
        return index
    }

    private func addFieldItem(_ field: Int, _ vType: ValueType, _ isArray: Bool, _ isInline: Bool, _ isCompressed: Bool, _ payload: Int) -> Int {
        var rep: UInt64 = UInt64(vType.rawValue &<< 48) | (UInt64(payload) & PAYLOAD_MASK)
        if isArray {
            rep |= IS_ARRAY_BIT
        }
        if isInline {
            rep |= IS_INLINE_BIT
        }
        if isCompressed {
            rep |= IS_COMPRESSED_BIT
        }
        let key = FieldKey(field, rep)
        if let tmp = fieldToFieldIndex[key] {
            return tmp
        }
        let fieldIndex = fields.count
        fieldToFieldIndex[key] = fieldIndex
        fields.append(field)
        reps.append(rep)
        return fieldIndex
    }

    private func addFieldTokens(_ field: String, _ data: [String]) -> Int {
        let tokenIndex = getTokenIndex(field)
        var tokens = [Int]()
        for token in data {
            tokens.append(getTokenIndex(token))
        }

        let ref = writer.tell()
        writer.writeUInt64(tokens.count)
        for token in tokens {
            writer.writeUInt32(token)
        }

        return addFieldItem(tokenIndex, ValueType.token, true, false, false, ref)
    }

    private func addFieldToken(_ field: String, _ data: String) -> Int {
        let tokenIndex = getTokenIndex(field)
        let token = getTokenIndex(data)
        return addFieldItem(tokenIndex, ValueType.token, false, true, false, token)
    }

    private func addFieldTokenVector(_ field: String, _ tokens: [String]) -> Int {
        let tokenIndex = getTokenIndex(field)
        var data = [Int]()
        for token in tokens {
            data.append(getTokenIndex(token))
        }
        var ref = self.getDataRefrence(data, ValueType.TokenVector)
        if ref < 0 {
            ref = writer.tell()
            addWrittenData(data, ValueType.TokenVector, ref)
            writer.writeUInt64(data.count)
            for token in data {
                writer.writeUInt32(token)
            }
            // writer.write([UInt8](repeating: 0, count: 4)) // Not sure what this is.
        }
        return addFieldItem(tokenIndex, ValueType.TokenVector, false, false, false, ref)
    }

    private func addFieldPathListOp(_ field: String, _ pathIndex: Int) -> Int {
        let tokenIndex = getTokenIndex(field)
        let ref = writer.tell()
        let op = 259
        writer.writeUInt64(op)
        writer.write([UInt8](repeating: 0, count: 1))
        writer.writeUInt32(pathIndex)
        return addFieldItem(tokenIndex, ValueType.PathListOp, false, false, false, ref)
    }

    private func addFieldPathVector(_ field: String, _ pathIndex: Int) -> Int {
        let tokenIndex = getTokenIndex(field)
        let ref = writer.tell()
        writer.writeUInt64(1)
        writer.writeUInt32(pathIndex)
        return addFieldItem(tokenIndex, ValueType.PathVector, false, false, false, ref)
    }

    private func addFieldSpecifier(_ field: String, _ spec: SpecifierType) -> Int {
        let tokenIndex = getTokenIndex(field)
        return addFieldItem(tokenIndex, ValueType.Specifier, false, true, false, spec.rawValue)
    }

    private func addFieldInt(_ field: String, _ data: ContiguousArray<Int>) -> Int {
        let tokenIndex = getTokenIndex(field)
        // assert type(data) == list
        let compress = data.count >= 16

        let ref = writer.tell()
        writer.writeUInt64(data.count)
        if compress {
            writer.writeInt32Compressed(data)
        } else {
            for i in data {
                writer.writeInt32(i)
            }
        }

        return addFieldItem(tokenIndex, ValueType.int, true, false, compress, ref)
    }

    private func addFieldFloat(_ field: String, _ data: Float) -> Int {
        let tokenIndex = getTokenIndex(field)
        //let data = int.from_bytes(struct.pack('<f', data), 'little')
        let data = Int(withUnsafeBytes(of: data) { $0.load(as: Int32.self) })
        return addFieldItem(tokenIndex, ValueType.float, false, true, false, data)
    }

    private func addFieldVectors(_ field: String, _ data: [Vec3]) -> Int {
        let tokenIndex = getTokenIndex(field)

        let ref = writer.tell()
        writer.writeUInt64(data.count)
        // writer.write(Array(data.joined()).withUnsafeBytes(Array.init))
        // let tmp: [Float] = data.flatMap { x in [x.0, x.1, x.2] }
        // writer.write(tmp.withUnsafeBytes(Array.init))
        writer.write(data.withUnsafeBytes(Array.init))
        return addFieldItem(tokenIndex, ValueType.vec3f, true, false, false, ref)
    }

    private func addFieldVector(_ field: String, _ data: [Float]) -> Int {
        let tokenIndex = getTokenIndex(field)

        // MOLAR: Not implemented.
        /*
        if isWholeBytes(data) {
            let nBytes = 2 * data.count
            data = [int(f) for f in data]
            data = struct.pack("<3b", *data)
            data = int.from_bytes(data, "little")
            return addFieldItem(field, vType, false, true, false, data)
        }
         */

        let ref = writer.tell()
        //writer.write(struct.pack("<3f", *data))
        writer.write(data.withUnsafeBytes(Array.init))
        return addFieldItem(tokenIndex, ValueType.vec3f, false, false, false, ref)
    }

    private func addFieldBool(_ field: String, _ data: Bool) -> Int {
        let tokenIndex = getTokenIndex(field)
        let data = data ? 1 : 0
        return addFieldItem(tokenIndex, ValueType.bool, false, true, false, data)
    }

    private func addFieldVariability(_ field: String, _ data: Bool) -> Int {
        let tokenIndex = getTokenIndex(field)
        let data = data ? 1 : 0
        return addFieldItem(tokenIndex, ValueType.Variability, false, true, false, data)
    }

    private func addFieldDictionary(_ field: String, _ data: [String: String]) -> Int {
        let tokenIndex = getTokenIndex(field)
        let ref = writer.tell()
        writer.writeUInt64(data.count)
        for (key, value) in data {
            writer.writeUInt32(self.getStringIndex(key))
            writer.writeUInt64(8)
            writer.writeUInt32(self.getStringIndex(value))
            writer.writeUInt32(1074397184)
        }
        return addFieldItem(tokenIndex, ValueType.Dictionary, false, false, false, ref)
    }

    private func addFieldTimeSamples(_ field: String, _ data: [(Double, Any)], _ vType: ValueType) -> Int {
        let tokenIndex = getTokenIndex(field)
        let count = data.count
        let elem = 0
        // if (type(data[0][1]) == list && len(data[0][1]) > 1)
        //     elem = 128
        var frames = [Double]()
        var refs = [Int]()
        for (frame, value) in data {
            frames.append(frame)
            let ref = writer.tell()
            //writeValue(this.file, value, vType);
            // https://github.com/robmcrosby/BlenderUSDZ/blob/e8a002849b85df3daba339912f4cc91fb042fe6d/io_scene_usdz/crate_file.py#L51
            if vType == ValueType.vec3f {
                //writer.write(new Uint8Array((value as Float32Array).buffer))
//                let tmpValue = value as! Vec3
//                let tmp: [Float] = [tmpValue.0, tmpValue.1, tmpValue.2]
//                writer.write(tmp.withUnsafeBytes(Array.init))
                fatalError()
            } else if vType == ValueType.matrix4d {
                let tmp = value as! simd_float4x4
                var tmpValue = [Double]()
                for i in 0 ..< 4 {
                    for j in 0 ..< 4 {
                        tmpValue.append(Double(tmp[i, j]))
                    }
                }
                writer.write(tmpValue.withUnsafeBytes(Array.init))
            }
            refs.append(ref)
        }
        let ref = writer.tell()
        if self.framesRef > 0 {
            writer.writeUInt64(8)
            //writer.writeInt(self.framesRef + 8, 6)
            writer.writeUInt32(self.framesRef + 8)
            writer.writeUInt16(0)
            writer.writeUInt8(ValueType.DoubleVector.rawValue)
            writer.writeUInt8(0)
        } else {
            self.framesRef = ref
            let size = 8 * (count + 2)
            writer.writeUInt64(size)
            writer.writeUInt64(count)
            for frame in frames {
                writer.writeDouble(frame)
            }
            //writer.writeInt(ref + 8, 6)
            writer.writeUInt32(ref + 8)
            writer.writeUInt16(0)
            writer.writeUInt8(ValueType.DoubleVector.rawValue)
            writer.writeUInt8(0)
        }
        writer.writeUInt64(8)
        writer.writeUInt64(count)
        for ref2 in refs {
            //writer.writeInt(ref2, 6)
            writer.writeUInt32(ref2)
            writer.writeUInt16(0)
            writer.writeUInt8(vType.rawValue)
            writer.writeUInt8(elem)
        }
        return addFieldItem(tokenIndex, ValueType.TimeSamples, false, false, false, ref)
    }

    private func addField(_ field: String, _ usdAtt: UsdAttribute) -> Int {
        let value = usdAtt.value!
        let vType = usdAtt.valueType
        if vType == ValueType.token {
            if usdAtt.isArray {
                return addFieldTokens(field, value as! [String])
            }
            return addFieldToken(field, value as! String)
        }
        if vType == ValueType.Specifier {
            return addFieldSpecifier(field, value as! SpecifierType)
        }
        if vType == ValueType.int {
            return addFieldInt(field, value as! ContiguousArray<Int>)
        }
        if vType == ValueType.float {
            return addFieldFloat(field, value as! Float)
        }
        if vType == ValueType.vec3f {
            if usdAtt.isArray {
                return addFieldVectors(field, value as! [Vec3])
            }
            return addFieldVector(field, value as! [Float])
        }
        if vType == ValueType.bool {
            return addFieldBool(field, value as! Bool)
        }
        if vType == ValueType.Variability {
            return addFieldVariability(field, value as! Bool)
        }
        if vType == ValueType.Dictionary {
            return addFieldDictionary(field, value as! [String: String])
        }
        fatalError()
    }

    private func addPath(_ pathIndex: Int, _ tokenIndex: Int, _ jump: Int, _ prim: Bool) {
        var tokenIndex = tokenIndex
        if prim {
            tokenIndex *= -1
        }
        paths.append((pathIndex, tokenIndex, jump))
    }

    private func addSpec(_ fieldSetIndex: Int, _ specType: SpecType) -> Int {
        let pathIndex = specs.count
        specs.append((pathIndex, fieldSetIndex, specType.rawValue))
        return pathIndex
    }

    private func writeBootStrap(_ tocOffset: Int = 0) {
        // writer.seek(0)
        writer.write(Array("PXR-USDC".utf8))
        // Version
        writer.write([0x00, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
        // Table of Contents Offset
        writer.writeUInt64(tocOffset)
        writer.write([UInt8](repeating: 0, count: 64))
    }

    private func writeTokensSection() {
        let start = writer.tell()
        writer.writeUInt64(self.tokens.count)
        var buffer = [UInt8]()
        for token in self.tokens {
            buffer += Array(token.utf8)// + b'\0'
            buffer.append(0x00)
        }
        writer.writeUInt64(buffer.count)
        buffer = lz4Compress(buffer)
        writer.writeUInt64(buffer.count)
        writer.write(buffer)
        let size = writer.tell() &- start
        self.toc.append(("TOKENS", start, size))
    }

    private func writeStringsSection() {
        let start = writer.tell()
        writer.writeUInt64(self.strings.count)
        for i in self.strings {
            writer.writeUInt32(i)
        }
        let size = writer.tell() &- start
        self.toc.append(("STRINGS", start, size))
    }

    private func writeFieldsSection() {
        let start = writer.tell()
        writer.writeUInt64(self.fields.count)
        writer.writeInt32Compressed(self.fields)
        let buffer = lz4Compress(self.reps.withUnsafeBytes(Array.init))
        writer.writeUInt64(buffer.count)
        writer.write(buffer)
        let size = writer.tell() &- start
        self.toc.append(("FIELDS", start, size))
    }

    private func writeFieldSetsSection() {
        let start = writer.tell()
        writer.writeUInt64(self.fsets.count)
        writer.writeInt32Compressed(self.fsets)
        let size = writer.tell() &- start
        self.toc.append(("FIELDSETS", start, size))
    }

    private func writePathsSection() {
        let start = writer.tell()
        var pathIndices = ContiguousArray<Int>()
        var tokenIndices = ContiguousArray<Int>()
        var jumps = ContiguousArray<Int>()
        for (pathIndex, tokenIndex, jump) in self.paths {
            pathIndices.append(pathIndex)
            tokenIndices.append(tokenIndex)
            jumps.append(jump)
        }
        writer.writeUInt64(self.paths.count)
        writer.writeUInt64(self.paths.count)
        writer.writeInt32Compressed(pathIndices)
        writer.writeInt32Compressed(tokenIndices)
        writer.writeInt32Compressed(jumps)
        let size = writer.tell() &- start
        self.toc.append(("PATHS", start, size))
    }

    private func writeSpecsSection() {
        let start = writer.tell()
        var pathIndices = ContiguousArray<Int>()
        var fieldSetIndices = ContiguousArray<Int>()
        var specTypes = ContiguousArray<Int>()
        for (pathIndex, fieldSetIndex, specType) in self.specs {
            pathIndices.append(pathIndex)
            fieldSetIndices.append(fieldSetIndex)
            specTypes.append(specType)
        }
        writer.writeUInt64(self.specs.count)
        writer.writeInt32Compressed(pathIndices)
        writer.writeInt32Compressed(fieldSetIndices)
        writer.writeInt32Compressed(specTypes)
        let size = writer.tell() &- start
        self.toc.append(("SPECS", start, size))
    }

    private func writeSections() {
        writeTokensSection()
        writeStringsSection()
        writeFieldsSection()
        writeFieldSetsSection()
        writePathsSection()
        writeSpecsSection()
    }

    private func writeTableOfContents() {
        let tocStart = writer.tell()
        // print('tocStart: ', tocStart)
        writer.writeUInt64(self.toc.count)
        for (name, start, size) in self.toc {
            writer.write(Array(name.utf8))
            writer.write([UInt8](repeating: 0, count: 16 - name.count))
            writer.writeUInt64(start)
            writer.writeUInt64(size)
        }
        //self.writeBootStrap(tocStart)
        let bytes = withUnsafeBytes(of: UInt64(tocStart), Array.init)
        writer.overwrite(bytes, at: 16)
    }

    private func writeUsdConnection(_ usdAtt: UsdAttribute) {
        var fset = [Int]()
        let pathIndex = (usdAtt.value as! UsdAttribute).pathIndex
        fset.append(addFieldToken("typeName", "token"))
        fset.append(addFieldPathListOp("connectionPaths", pathIndex))
        fset.append(addFieldPathVector("connectionChildren", pathIndex))
        let fset2 = addFieldSet(fset)
        usdAtt.pathIndex = self.addSpec(fset2, SpecType.Attribute)
        let nameToken = getTokenIndex(usdAtt.name)
        let pathJump = usdAtt.getPathJump()
        addPath(usdAtt.pathIndex, nameToken, pathJump, true)
    }

    private func writeUsdRelationship(_ usdAtt: UsdAttribute) {
        var fset = [Int]()
        let pathIndex = (usdAtt.value as! UsdPrim).pathIndex
        fset.append(addFieldVariability("variability", true))
        fset.append(addFieldPathListOp("targetPaths", pathIndex))
        fset.append(addFieldPathVector("targetChildren", pathIndex))
        let fset2 = addFieldSet(fset)
        usdAtt.pathIndex = self.addSpec(fset2, SpecType.Relationship)
        let nameToken = getTokenIndex(usdAtt.name)
        let pathJump = usdAtt.getPathJump()
        addPath(usdAtt.pathIndex, nameToken, pathJump, true)
    }

    private func writeUsdAttribute(_ usdAtt: UsdAttribute) {
        var fset = [Int]()
        fset.append(addFieldToken("typeName", usdAtt.valueTypeStr))
        for q in usdAtt.qualifiers {
            assert(q == "uniform")
            fset.append(addFieldVariability("variability", true))
        }
        for (name, value) in usdAtt.metadata {
            fset.append(addFieldToken(name, value as! String))
        }
        if usdAtt.value != nil {
            fset.append(addField("default", usdAtt))
        }
        if !usdAtt.frames.isEmpty {
            fset.append(addFieldTimeSamples("timeSamples", usdAtt.frames, usdAtt.valueType))
        }
        let fset2 = addFieldSet(fset)
        usdAtt.pathIndex = self.addSpec(fset2, SpecType.Attribute)
        let nameToken = getTokenIndex(usdAtt.name)
        let pathJump = usdAtt.getPathJump()
        addPath(usdAtt.pathIndex, nameToken, pathJump, true)
    }

    private func writeUsdPrim(_ usdPrim: UsdPrim) {
        // Add Prim Properties
        var fset = [Int]()
        fset.append(addFieldSpecifier("specifier", usdPrim.specifierType))
        // assert(usdPrim.classType != nil)
        //fset.append(addFieldToken("typeName", String(describing: usdPrim.classType)))
        fset.append(addFieldToken("typeName", usdPrim.classType))
        for (name, value) in usdPrim.metadata {
            //let t: ValueType
            if name == "assetInfo" {
                // t = ValueType.Dictionary
                fset.append(addFieldDictionary(name, value as! [String: String]))
            } else if name == "kind" {
                // t = ValueType.token
                fset.append(addFieldToken(name, value as! String))
            } else {
                fatalError()
            }
            // fset.append(addField(name, value, t))
        }
        if !usdPrim.attributes.isEmpty {
            let tokens = usdPrim.attributes.map { $0.name }
            fset.append(addFieldTokenVector("properties", tokens))
        }
        if !usdPrim.children.isEmpty {
            let tokens = usdPrim.children.map { $0.name }
            fset.append(addFieldTokenVector("primChildren", tokens))
        }
        let fset2 = addFieldSet(fset)
        usdPrim.pathIndex = self.addSpec(fset2, SpecType.Prim)
        let nameToken = getTokenIndex(usdPrim.name)
        let pathJump = usdPrim.getPathJump()
        // Add Prim Path
        addPath(usdPrim.pathIndex, nameToken, pathJump, false)
        // Write Prim Children
        for child in usdPrim.children {
            writeUsdPrim(child)
        }
        // Write Prim Attributes
        for attribute in usdPrim.attributes {
            if attribute.isConnection() {
                writeUsdConnection(attribute)
            } else if attribute.isRelationship() {
                writeUsdRelationship(attribute)
            } else {
                writeUsdAttribute(attribute)
            }
        }
    }

    func writeUsd(_ usdData: UsdData) {
        usdData.updatePathIndices()
        writeBootStrap()
        // Add Root Metadata
        var fset = [Int]()
        /*
        for (name, value) in usdData.metadata {
            if let value = value as? Float {
                fset.append(addFieldFloat(name, value))
            } else if let value = value as? String {
                fset.append(addFieldToken(name, value))
            } else if let value = value as? Bool {
                fset.append(addFieldBool(name, value))
            } else {
                fatalError()
            }
        }
        */
        if !usdData.children.isEmpty {
            let tokens = usdData.children.map { $0.name }
            fset.append(addFieldTokenVector("primChildren", tokens))
        }
        let fset2 = addFieldSet(fset)
        usdData.pathIndex = self.addSpec(fset2, SpecType.PseudoRoot)
        // Add First Path
        let nameToken = getTokenIndex("")
        let pathJump = usdData.getPathJump()
        addPath(usdData.pathIndex, nameToken, pathJump, false)
        // Write the Children
        for child in usdData.children {
            writeUsdPrim(child)
        }
        // Finish Writing the Crate File
        writeSections()
        writeTableOfContents()
    }

    var bytes: [UInt8] {
        return writer.bytes
    }
}

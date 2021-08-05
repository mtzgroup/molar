//
//  ValueTypes.swift
//  MolAR
//
//  Created by Sukolsak on 3/19/21.
//

import Foundation


enum SpecifierType: Int {
    case Def = 0
    case Over = 1
    case Class = 2
}

enum SpecType: Int {
    case Attribute   = 1
    case Connection  = 2
    case Expression  = 3
    case Mapper      = 4
    case MapperArg   = 5
    case Prim        = 6
    case PseudoRoot  = 7
    case Relationship = 8
    case RelationshipTarget = 9
    case Variant     = 10
    case VariantSet  = 11
}

enum ValueType: Int {
    case Invalid = 0
    case bool = 1
    case uchar = 2
    case int = 3
    case uint = 4
    case int64 = 5
    case uint64 = 6
    case half = 7
    case float = 8
    case double = 9
    case string = 10
    case token = 11
    case asset = 12
    case matrix2d = 13
    case matrix3d = 14
    case matrix4d = 15
    case quatd = 16
    case quatf = 17
    case quath = 18
    case vec2d = 19
    case vec2f = 20
    case vec2h = 21
    case vec2i = 22
    case vec3d = 23
    case vec3f = 24
    case vec3h = 25
    case vec3i = 26
    case vec4d = 27
    case vec4f = 28
    case vec4h = 29
    case vec4i = 30
    case Dictionary = 31
    case TokenListOp = 32
    case StringListOp = 33
    case PathListOp = 34
    case ReferenceListOp = 35
    case IntListOp = 36
    case Int64ListOp = 37
    case UIntListOp = 38
    case UInt64ListOp = 39
    case PathVector = 40
    case TokenVector = 41
    case Specifier = 42
    case Permission = 43
    case Variability = 44
    case VariantSelectionMap = 45
    case TimeSamples = 46
    case Payload = 47
    case DoubleVector = 48
    case LayerOffsetVector = 49
    case StringVector = 50
    case ValueBlock = 51
    case Value = 52
    case UnregisteredValue = 53
    case UnregisteredValueListOp = 54
    case PayloadListOp = 55
}

final class UsdAttribute {
    let name: String
    let value: Any?
    var frames = [(Double, Any)]()
    var qualifiers = [String]()
    var metadata = [String: Any]()
    let valueType: ValueType
    let valueTypeStr: String
    let isArray: Bool
    var parent: UsdPrim!
    var pathIndex = -1

    init(_ name: String, _ value: Any?, _ type: ValueType, _ valueTypeStr: String, _ isArray: Bool = false) {
        self.name = name
        self.value = value
        self.valueType = type
        self.valueTypeStr = valueTypeStr
        self.isArray = isArray
    }

    func addQualifier(_ qualifier: String) {
        self.qualifiers.append(qualifier)
    }

    func addTimeSample(_ frame: Double, _ value: Any) {
        self.frames.append((frame, value))
    }

    func isConnection() -> Bool {
        return (self.value as? UsdAttribute) != nil
    }

    func isRelationship() -> Bool {
        return (self.value as? UsdPrim) != nil
    }

    func getPathJump() -> Int {
        if parent != nil && parent!.attributes.last === self {
            return -2
        }
        return 0
    }
}

class UsdPrim {
    let name: String
    let specifierType = SpecifierType.Def
    let classType: String
    var parent: UsdPrim?

    var metadata = [String: Any]()
    var children = [UsdPrim]()
    var attributes = [UsdAttribute]()
    var pathIndex = 0

    init(_ name: String, _ type: String) {
        self.name = name
        self.classType = type
    }

    func addAttribute(_ attribute: UsdAttribute) {
        attribute.parent = self
        attributes.append(attribute)
        // return attribute
    }

    private func addChild(_ child: UsdPrim) -> UsdPrim {
        child.parent = self
        children.append(child)
        return child
    }

    func createChild(_ name: String, _ type: String) -> UsdPrim {
        return addChild(UsdPrim(name, type))
    }

    func updatePathIndices(_ pathIndex2: Int) -> Int {
        var pathIndex2 = pathIndex2
        self.pathIndex = pathIndex2
        pathIndex2 += 1
        for child in self.children {
            pathIndex2 = child.updatePathIndices(pathIndex2)
        }
        for att in self.attributes {
            att.pathIndex = pathIndex
            pathIndex2 += 1
        }
        return pathIndex2
    }

    private func countItems() -> Int {
        var count = attributes.count + children.count
        for child in self.children {
            count += child.countItems()
        }
        return count
    }

    func getPathJump() -> Int {
        if parent == nil || (parent!.children.last === self && parent!.attributes.count == 0) {
            return -1
        }
        return countItems() + 1
    }
}

final class UsdData: UsdPrim { // subclass????
    /*
    var metadata = [String: Any]()
    var children = [UsdPrim]()
    var attributes = [UsdAttribute]()
    var pathIndex = 0
    var pathJump = -1
 */

    func updatePathIndices() {
        pathIndex = 1
        for child in children {
            pathIndex = child.updatePathIndices(pathIndex)
        }
    }

    override func getPathJump() -> Int {
        return (children.count > 0) ? -1 : -2
    }
}

//
//  Writer.swift
//  MolAR
//
//  Created by Sukolsak on 3/19/21.
//

import Foundation

final class Writer {
    private var pos = 0
    var bytes = [UInt8]()

    func tell() -> Int {
        return pos
    }

    func write(_ x: [UInt8]) {
        pos += x.count
        bytes += x
    }

    //func writeInt(_ value: Int, _ size: Int) {
    //    assert(size == 8)
    //    let bytes: [UInt8]
    //    bytes = withUnsafeBytes(of: UInt64(value), Array.init)
    //    write(bytes)
    //}

    func writeDouble(_ value: Double) {
        write(withUnsafeBytes(of: value, Array.init))
    }

    func writeInt32Compressed(_ data: ContiguousArray<Int>) {
        let buffer = lz4Compress(usdInt32Compress(data))
        writeUInt64(buffer.count)
        write(buffer)
    }

    func writeUInt8(_ value: Int) {
        write(withUnsafeBytes(of: UInt8(value), Array.init))
    }

    func writeUInt16(_ value: Int) {
        write(withUnsafeBytes(of: UInt16(value), Array.init))
        //writeAs(UInt16(value))
    }

    func writeInt32(_ value: Int) {
        write(withUnsafeBytes(of: Int32(value), Array.init))
    }

    func writeUInt32(_ value: Int) {
        write(withUnsafeBytes(of: UInt32(value), Array.init))
    }

    func writeUInt64(_ value: Int) {
        write(withUnsafeBytes(of: UInt64(value), Array.init))
    }

    //func writeAs<T>(_ value: T) {
    //    write(withUnsafeBytes(of: value, Array.init))
    //}

    func overwrite(_ x: [UInt8], at i: Int) {
        bytes.replaceSubrange(i ..< i + x.count, with: x)
    }
}


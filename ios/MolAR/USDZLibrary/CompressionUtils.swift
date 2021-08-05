//
//  CompressionUtils.swift
//  MolAR
//
//  Created by Sukolsak on 3/19/21.
//

// Read more at https://github.com/PixarAnimationStudios/USD/blob/release/pxr/usd/usd/integerCoding.cpp

import Foundation

// https://github.com/PixarAnimationStudios/USD/blob/release/pxr/base/tf/pxrLZ4/lz4.h
private let LZ4_MAX_INPUT_SIZE = 0x7E000000

private let LZ4_DISTANCE_MAX = 65535
private let MINMATCH = 4
private let MFLIMIT = 12

private let ML_BITS = 4
private let ML_MASK = (1 &<< ML_BITS) - 1
private let RUN_BITS = 8 - ML_BITS
private let RUN_MASK = (1 &<< RUN_BITS) - 1

private final class PositionTable {
    // private let TABLE_SIZE = 4096

    private var table = [Int?](repeating: nil, count: 4096)

    // LZ4_hash4 in https://github.com/PixarAnimationStudios/USD/blob/release/pxr/base/tf/pxrLZ4/lz4.cpp
    static private func _hash(_ val: Int) -> Int {
        let val = val & 0xFFFFFFFF  // prune to 32 bit
        return (val &* 2654435761) & 0x0FFF  // max = 4095
    }

    func getPosition(_ val: Int) -> Int? {
        let index = Self._hash(val)
        return table[index]
    }

    func setPosition(_ val: Int, _ pos: Int) -> Void {
        let index = Self._hash(val)
        table[index] = pos
    }
}

private func worstCaseBlockLength(_ srcLen: Int) -> Int {
    return srcLen + (srcLen / 255) + 16
}

private func readLeUint32(_ buf: [UInt8], _ pos: Int) -> Int {
    // return int.from_bytes(buf[pos:pos+4], 'little')
    //return Int(Array(buf[pos ..< pos+4]).withUnsafeBytes { $0.load(as: UInt32.self) })
    // "load" requires the pointer to be aligned.
    return Int(buf[pos]) | (Int(buf[pos + 1]) &<< 8) | (Int(buf[pos + 2]) &<< 16) | (Int(buf[pos + 3]) &<< 24)
}

private func writeLeUint16(_ buf: inout [UInt8], _ i: Int, _ val: Int) -> Void {
    buf[i] = UInt8(val & 0xFF)
    buf[i + 1] = UInt8((val >> 8) & 0xFF)
}

private func findMatch(_ table: PositionTable, _ val: Int, _ src: [UInt8], _ srcPtr: Int) -> Int? {
    let pos = table.getPosition(val)
    if let pos = pos, val == readLeUint32(src, pos) {
        // Check if the match is too far away
        if srcPtr - pos > LZ4_DISTANCE_MAX {
            return nil
        }
        return pos
    }
    return nil
}

private func countMatch(_ buf: [UInt8], _ front: Int, _ back: Int, _ max: Int) -> Int {
    var front = front
    var back = back

    var count = 0
    while back <= max {
        if buf[front] == buf[back] {
            count &+= 1
        } else {
            break
        }
        front += 1
        back += 1
    }
    return count
}

private func copySequence(_ dst: inout [UInt8], _ dstHead: Int, _ literal: ArraySlice<UInt8>, _ match: (Int, Int)) -> Int {
    let litLength = literal.count
    var dstPtr = dstHead

    // Write the length of the literal
    // var token = dst[dstPtr ..< dstPtr + 1]
    let originalDstPtr = dstPtr
    dstPtr += 1
    if litLength >= RUN_MASK {
        // token[originalDstPtr] = (15 << 4)
        var remLen = litLength - RUN_MASK
        dst[originalDstPtr] = UInt8(RUN_MASK << ML_BITS)
        while remLen >= 255 {
            dst[dstPtr] = 255
            dstPtr += 1
            remLen -= 255
        }
        dst[dstPtr] = UInt8(remLen)
        dstPtr += 1
    } else {
        // token[originalDstPtr] = UInt8(litLen << 4)
        dst[originalDstPtr] = UInt8(litLength << ML_BITS)
    }

    // Write the literal
    dst[dstPtr ..< dstPtr + litLength] = literal
    dstPtr += litLength

    var (offset, matchLen) = match
    if matchLen > 0 {
        // Write the Match offset
        writeLeUint16(&dst, dstPtr, offset)
        dstPtr += 2

        // Write the Match length
        matchLen -= MINMATCH
        if matchLen >= ML_MASK {
            // token[originalDstPtr] |= 15
            dst[originalDstPtr] |= UInt8(ML_MASK)
            matchLen -= ML_MASK
            while matchLen >= 255 {
                dst[dstPtr] = 255
                dstPtr += 1
                matchLen -= 255
            }
            dst[dstPtr] = UInt8(matchLen)
            dstPtr += 1
        } else {
            // token[originalDstPtr] |= UInt8(matchLen)
            dst[originalDstPtr] |= UInt8(matchLen)
        }
    }
    return dstPtr - dstHead
}

//
// LZ4_compress_default and LZ4_compress_generic in https://github.com/PixarAnimationStudios/USD/blob/release/pxr/base/tf/pxrLZ4/lz4.cpp
private func lz4CompressDefault(_ src: [UInt8]) -> ArraySlice<UInt8> {
    let srcLen = src.count
    //  if srcLen > LZ4_MAX_INPUT_SIZE {
    //     return ArraySlice<UInt8>()
    // }
    var dst = [UInt8](repeating: 0, count: worstCaseBlockLength(srcLen))
    let posTable = PositionTable()
    var srcPtr = 0
    var literalHead = 0
    var dstPtr = 0
    let MAX_INDEX = srcLen - MFLIMIT

    while srcPtr < MAX_INDEX {
        let curValue = readLeUint32(src, srcPtr)
        let matchPos = findMatch(posTable, curValue, src, srcPtr)
        if let matchPos = matchPos {
            let length = countMatch(src, matchPos, srcPtr, MAX_INDEX)
            if length < MINMATCH {
                break
            }
            dstPtr += copySequence(&dst, dstPtr,
                                   src[literalHead ..< srcPtr],
                                   (srcPtr - matchPos, length))
            srcPtr += length
            literalHead = srcPtr
        } else {
            posTable.setPosition(curValue, srcPtr)
            srcPtr += 1
        }
    }
    // Write the last literal
    dstPtr += copySequence(&dst, dstPtr,
                           src[literalHead ..< srcLen],
                           (0, 0))

    return dst.prefix(dstPtr)
}

// TfFastCompression::CompressToBuffer in https://github.com/PixarAnimationStudios/USD/blob/release/pxr/base/tf/fastCompression.cpp
func lz4Compress(_ input: [UInt8]) -> [UInt8] {
    var compressed = [UInt8]()
    let inputSize = input.count
    if inputSize == 0 {
        return compressed
    }
    if inputSize > 127 * LZ4_MAX_INPUT_SIZE {
        fatalError(String(format: "Attempted to compress a buffer of %zu bytes, more than the maximum supported", inputSize))
    }
    if inputSize <= LZ4_MAX_INPUT_SIZE {
        compressed.append(0) // < zero byte means one chunk.
        compressed += lz4CompressDefault(input)
    } else {
        let nWholeChunks = inputSize / LZ4_MAX_INPUT_SIZE
        let partChunkSize = inputSize % LZ4_MAX_INPUT_SIZE
        compressed = [UInt8(nWholeChunks + ((partChunkSize > 0) ? 1 : 0))]
        for i in 0..<nWholeChunks {
            let offset = i * LZ4_MAX_INPUT_SIZE
            let chunk = Array(input[offset ..< offset+LZ4_MAX_INPUT_SIZE])
            let chunk2 = lz4CompressDefault(chunk)
            compressed += withUnsafeBytes(of: UInt32(chunk2.count), Array.init)
            compressed += chunk2
        }
        if partChunkSize > 0 {
            let offset = nWholeChunks * LZ4_MAX_INPUT_SIZE
            let chunk = Array(input[offset ..< input.count])
            let chunk2 = lz4CompressDefault(chunk)
            compressed += withUnsafeBytes(of: UInt32(chunk2.count), Array.init)
            compressed += chunk2
        }
    }

    return compressed
}

func usdInt32Compress(_ values: ContiguousArray<Int>) -> [UInt8] {
    var values = values
    var data = [UInt8]()
    if values.count == 0 {
        return data
    }
    var preValue = 0
    for i in 0 ..< values.count {
        let value = values[i]
        values[i] = value &- preValue
        preValue = value
    }
    var counts = [Int: Int]()
    for value in values {
        counts[value, default: 0] &+= 1
    }

    let commonValue = counts.max(by: { ($0.value != $1.value) ? ($0.value < $1.value) : ($0.key < $1.key) })!.key

    /*
    // Just to make it stable.
    var commonValue = counts.max(by: {
        if $0.value < $1.value { return true }
        if $0.value > $1.value { return false }
        return $0.key > $1.key
    })!.key
    print(commonValue)
     */

    data += withUnsafeBytes(of: Int32(commonValue), Array.init)
    data += [UInt8](repeating: 0, count: (values.count * 2 + 7) / 8)
    for v in 0 ..< values.count {
        let value = values[v]
        let i = v + 16
        if value != commonValue {
            if value <= 0x7F && value >= -0x80 {
                data[i/4] |= 1 &<< ((i%4) &* 2)
                data += withUnsafeBytes(of: Int8(value), Array.init)
            } else if value <= 0x7FFF && value >= -0x8000 {
                data[i/4] |= 2 &<< ((i%4) &* 2)
                data += withUnsafeBytes(of: Int16(value), Array.init)
            } else {
                data[i/4] |= 3 &<< ((i%4) &* 2)
                data += withUnsafeBytes(of: Int32(value), Array.init)
            }
        }
    }
    return data
}

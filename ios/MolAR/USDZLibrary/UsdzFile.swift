//
//  UsdzFile.swift
//  MolAR
//
//  Created by Sukolsak on 3/20/21.
//

import Foundation

final class UsdzFile {
    let file = Writer()
    private var entries = [[String: Any]]()
    private var cdOffset = 0
    private var cdLength = 0


    private func getExtraAlignmentSize(_ name: String) -> Int {
        return 64 - ((file.tell() + 30 + name.count + 4) % 64)
    }

    func addFile(_ contents: [UInt8], _ fileName: String) {
        // contents = readFileContents(filePath)
        var entry = [String: Any]()
        entry["name"] = fileName // os.path.basename(filePath)
        // File offset and crc32 hash
        entry["offset"] = file.tell()
        entry["crc"] = 0 //zlib.crc32(contents) & 0xffffffff
        // Write the Current Date and Time
        // dt = time.localtime(time.time())
        // dosdate = (dt[0] - 1980) << 9 | dt[1] << 5 | dt[2]
        // dostime = dt[3] << 11 | dt[4] << 5 | (dt[5] // 2)
        // entry['time'] = dosdate.to_bytes(2, byteorder = 'little')
        // entry['date'] = dostime.to_bytes(2, byteorder = 'little')
        entry["time"] = [UInt8(0), UInt8(0)]
        entry["date"] = [UInt8(0), UInt8(0)]
        let extraSize = self.getExtraAlignmentSize(fileName)
        // Local Entry Signature
        file.write([0x50, 0x4b, 0x03, 0x04])
        // Version for Extract, Bits, Compression Method
        file.writeUInt16(20)
        file.writeUInt16(0)
        file.writeUInt16(0)
        // Mod Time/Date
        file.write(entry["time"] as! [UInt8])
        file.write(entry["date"] as! [UInt8])
        // CRC Hash
        file.writeUInt32(entry["crc"] as! Int)
        // Size Uncompressed/Compressed
        file.writeUInt32(contents.count)
        file.writeUInt32(contents.count)
        // Filename/Extra Length
        file.writeUInt16(fileName.count)
        file.writeUInt16(extraSize+4)
        // Filename
        file.write(Array(fileName.utf8))
        // Extra Header Id/Size
        file.writeUInt16(1)
        file.writeUInt16(extraSize)
        // Padding Bytes and File Contents
        file.write([UInt8](repeating: 0, count: extraSize))
        file.write(contents)
        entry["size"] = contents.count
        self.entries.append(entry)
    }

    private func writeCentralDir() {
        self.cdOffset = file.tell()
        for entry in self.entries {
            // Central Directory Signature
            file.write([0x50, 0x4B, 0x01, 0x02])
            // Version Made By
            file.writeUInt16(62)
            // Version For Extract
            file.writeUInt16(20)
            // Bits
            file.writeUInt16(0)
            // Compression Method
            file.writeUInt16(0)
            file.write(entry["time"] as! [UInt8])
            file.write(entry["date"] as! [UInt8])
            // CRC Hash
            file.writeUInt32(entry["crc"] as! Int)
            // Size Compressed/Uncompressed
            file.writeUInt32(entry["size"] as! Int)
            file.writeUInt32(entry["size"] as! Int)
            // Filename Length, Extra Field Length, Comment Length
            file.writeUInt16((entry["name"] as! String).count)
            file.writeUInt16(0)
            file.writeUInt16(0)
            // Disk Number Start, Internal Attrs, External Attrs
            file.writeUInt16(0)
            file.writeUInt16(0)
            file.writeUInt32(0)
            // Local Header Offset
            file.writeUInt32(entry["offset"] as! Int)
            // Add the file name again
            file.write(Array((entry["name"] as! String).utf8))
            // Get Central Dir Length
        }
        self.cdLength = file.tell() - self.cdOffset
    }

    private func writeEndCentralDir() {
        // End Central Directory Signature
        file.write([0x50, 0x4B, 0x05, 0x06])
        // Disk Number and Disk Number for Central Dir
        file.writeUInt16(0)
        file.writeUInt16(0)
        // Num Central Dir Entries on Disk and Num Central Dir Entries
        file.writeUInt16(self.entries.count)
        file.writeUInt16(self.entries.count)
        // Central Dir Length/Offset
        file.writeUInt32(self.cdLength)
        file.writeUInt32(self.cdOffset)
        // Comment Length
        file.writeUInt16(0)
    }

    func close() {
        self.writeCentralDir()
        self.writeEndCentralDir()
        // file.close()
        //let tmp = file.getvalue()
        //file.close()
        //return tmp
    }
}

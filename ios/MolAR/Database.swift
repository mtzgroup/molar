//
//  Database.swift
//  MolAR
//
//  Created by Sukolsak on 3/18/21.
//

import Foundation
import SQLite3

class Database {
    static func search(_ query: String) -> [Item] {
        var ret = [Item]()

        if !query.contains("%") { // For now.
            var db: OpaquePointer?
            let path = Bundle.main.path(forResource: "molar.sqlite", ofType: nil)!
            if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
                let tmp = query.lowercased().replacingOccurrences(of: "'", with: "''")
                do {
                    var statement: OpaquePointer?
                    sqlite3_prepare_v2(db, "SELECT name, full_name, preview FROM molecules WHERE full_name LIKE '" + tmp + "%' AND preview IS NULL ORDER BY full_name", -1, &statement, nil) // "preview IS NULL" is a hacky way to filter out vibrations
                    while sqlite3_step(statement) == SQLITE_ROW {
                        let name = String(cString: sqlite3_column_text(statement, 0))
                        let fullName = String(cString: sqlite3_column_text(statement, 1))
                        let tmp = sqlite3_column_text(statement, 2)
                        let preview = (tmp == nil) ? nil : String(cString: tmp!)
                        let item = Item(name: name, text: fullName, isPDB: isNamePDB(name))
                        item.isSuggestion = false
                        item.preview = preview
                        ret.append(item)
                    }
                    sqlite3_finalize(statement)
                }
                do {
                    var statement: OpaquePointer?
                    sqlite3_prepare_v2(db, "SELECT name, full_name, preview FROM molecules WHERE full_name LIKE '% " + tmp + "%' AND preview IS NULL ORDER BY full_name", -1, &statement, nil)
                    while sqlite3_step(statement) == SQLITE_ROW {
                        let name = String(cString: sqlite3_column_text(statement, 0))
                        let fullName = String(cString: sqlite3_column_text(statement, 1))
                        let tmp = sqlite3_column_text(statement, 2)
                        let preview = (tmp == nil) ? nil : String(cString: tmp!)
                        let item = Item(name: name, text: fullName, isPDB: isNamePDB(name))
                        item.isSuggestion = false
                        item.preview = preview
                        ret.append(item)
                    }
                    sqlite3_finalize(statement)
                }
                sqlite3_close(db)
            }
        }

        // If there's no exact match
        if (ret.isEmpty || ret[0].name != query.lowercased()) && isNamePotentiallySMILESOrMoleculeName(query) {
            let item = Item(name: query, text: "“" + query + "” in NCI/PubChem", isPDB: false)
            item.isSuggestion = true
            ret.insert(item, at: 0)
        }

        return ret
    }

    static private func getAllItems() -> [Item] {
        var ret = [Item]()
        var db: OpaquePointer?
        let path = Bundle.main.path(forResource: "molar.sqlite", ofType: nil)!
        if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
            var statement: OpaquePointer?
            sqlite3_prepare_v2(db, "SELECT name, full_name, preview FROM molecules WHERE preview IS NULL ORDER BY full_name", -1, &statement, nil) // "preview IS NULL" is a hacky way to filter out vibrations
            while sqlite3_step(statement) == SQLITE_ROW {
                let name = String(cString: sqlite3_column_text(statement, 0))
                let fullName = String(cString: sqlite3_column_text(statement, 1))
                let tmp = sqlite3_column_text(statement, 2)
                let preview = (tmp == nil) ? nil : String(cString: tmp!)
                let item = Item(name: name, text: fullName, isPDB: isNamePDB(name))
                item.preview = preview
                ret.append(item)
            }
            sqlite3_finalize(statement)
            sqlite3_close(db)
        }
        return ret
    }

    static func getItems(category: String?) -> [Item] {
        if category == "All" {
            return getAllItems()
        }

        var ret = [Item]()
        var db: OpaquePointer?
        let path = Bundle.main.path(forResource: "molar.sqlite", ofType: nil)!
        if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
            var statement: OpaquePointer?
            var sql = "SELECT browse_items.name, full_name, is_folder, CASE is_folder WHEN 1 THEN browse_items.preview ELSE molecules.preview END FROM browse_items LEFT JOIN molecules ON browse_items.name = molecules.name WHERE parent_id ="
            if category == nil {
                sql += "0"
            } else {
                sql += " (SELECT id FROM browse_items WHERE name='" + category! + "' AND is_folder=1 LIMIT 1)"
            }
            sqlite3_prepare_v2(db, sql, -1, &statement, nil)
            while sqlite3_step(statement) == SQLITE_ROW {
                let name = String(cString: sqlite3_column_text(statement, 0))
                //let fullName = String(cString: sqlite3_column_text(statement, 1))
                let tmp = sqlite3_column_text(statement, 1)
                let fullName = (tmp == nil) ? "" : String(cString: tmp!)
                let isFolder = sqlite3_column_int(statement, 2)
                let tmp2 = sqlite3_column_text(statement, 3)
                let preview = (tmp2 == nil) ? nil : String(cString: tmp2!)
                let item: Item
                if isFolder != 0 {
                    item = Item(name: name, text: name, isPDB: false)
                    item.isFolder = true
                } else {
                    item = Item(name: name, text: fullName, isPDB: isNamePDB(name))
                }
                item.preview = preview
                ret.append(item)
            }
            sqlite3_finalize(statement)
            sqlite3_close(db)
        }
        return ret
    }

    static func getData(name: String) -> Any? {
        var ret: Any?
        var db: OpaquePointer?
        let path = Bundle.main.path(forResource: "molar.sqlite", ofType: nil)!
        if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
            var statement: OpaquePointer?
            sqlite3_prepare_v2(db, "SELECT data, description, description_source FROM molecules WHERE name='" + name + "'", -1, &statement, nil)
            var data: Any?
            var description: String?
            var descriptionSource: String?
            if sqlite3_step(statement) == SQLITE_ROW {
                if let cString = sqlite3_column_text(statement, 0) {
                    let s = String(cString: cString)
                    data = try! JSONSerialization.jsonObject(with: s.data(using: .utf8)!)
                }
                if let cString = sqlite3_column_text(statement, 1) {
                    description = String(cString: cString)
                }
                if let cString = sqlite3_column_text(statement, 2) {
                    descriptionSource = String(cString: cString)
                }
                ret = [data, description, descriptionSource]
            }
            sqlite3_finalize(statement)
            sqlite3_close(db)
        }
        return ret
    }

    static private func getBlob(name: String, column: String) -> Data? {
        var ret: Data?
        var db: OpaquePointer?
        let path = Bundle.main.path(forResource: "molar.sqlite", ofType: nil)!
        if sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK {
            var statement: OpaquePointer?
            sqlite3_prepare_v2(db, "SELECT " + column + " FROM molecules WHERE name='" + name.replacingOccurrences(of: "'", with: "''") + "'", -1, &statement, nil)
            if sqlite3_step(statement) == SQLITE_ROW {
                if let pointer = sqlite3_column_blob(statement, 0) {
                    let length = Int(sqlite3_column_bytes(statement, 0))
                    ret = Data(bytes: pointer, count: length)
                }
            }
            sqlite3_finalize(statement)
            sqlite3_close(db)
        }
        return ret
    }

    static func getBSDF(name: String) -> Data? {
        return getBlob(name: name, column: "bsdf")
    }

    static func getBmolden(name: String) -> Data? {
        return getBlob(name: name, column: "bmolden")
    }

    static func getDipoleMoment(name: String) -> Data? {
        return getBlob(name: name, column: "dipole_moment")
    }

    static func getVibrations(name: String) -> Data? {
        return getBlob(name: name, column: "vibrations")
    }
}

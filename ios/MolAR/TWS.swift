//
//  TWS.swift
//  MolAR
//
//  Created by Sukolsak on 10/26/21.
//

import Foundation

func getComputationResultFromSDFStructure(_ structure: SDFStructure, _ smiles: String, completionHandler: @escaping ((MoldenFile, Vec3)?) -> Void) {
    var xyzLines = [String]()
    xyzLines.append(String(structure.elements.count))
    xyzLines.append("\n\n")
    for element in structure.elements {
        xyzLines.append(String(format: "%@%13.5f%13.5f%13.5f\n", element.symbol.padding(toLength: 2, withPad: " ", startingAt: 0), element.position.0, element.position.1, element.position.2))
    }
    let xyz = xyzLines.joined()

    let json: [String: Any] = [
        "open_smiles": smiles, // For caching. Currently not used.
        "method": "pbe0",
        "basis": "3-21g",
        "molecular_charge": 0,
        "molecular_multiplicity": 1,
        "phase": "vacuum",
        "xyz": xyz,
        "cis": "False"
    ]

    let url = URL(string: serverAddress + "/api/molar_calculate_single_point")
    var urlRequest = URLRequest(url: url!)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
    urlRequest.httpBody = try! JSONSerialization.data(withJSONObject: json)

    let task = URLSession.shared.dataTask(with: urlRequest) { responseData, response, error in
        var success = false
        var errorMessage = "Can't connect to the server"
        if error == nil {
            let jsonData = try? JSONSerialization.jsonObject(with: responseData!, options: .allowFragments)
            if let topJSON = jsonData as? [String: Any],
               let taskId = topJSON["task"] as? String {
                success = true
                getResults(taskId: taskId, completionHandler: completionHandler)
                return

            } else {
                errorMessage = "TWS Internal server error"
            }
        }
        if !success {
            print(errorMessage)
            completionHandler(nil)
        }
    }
    task.resume()
}

private func getResults(taskId: String, completionHandler: @escaping ((MoldenFile, Vec3)?) -> Void) {
    let json: [String: Any] = [
        "task_id": taskId
    ]

    let url = URL(string: serverAddress + "/api/molar_check_results")
    var urlRequest = URLRequest(url: url!)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
    urlRequest.httpBody = try! JSONSerialization.data(withJSONObject: json)

    let task = URLSession.shared.dataTask(with: urlRequest) { responseData, response, error in
        var success = false
        var errorMessage = "Can't connect to the server"
        if error == nil {
            let jsonData = try? JSONSerialization.jsonObject(with: responseData!, options: .allowFragments)
            if let topJSON = jsonData as? [String: Any],
               let status = topJSON["status"] as? String {
                success = true

                if status == "SUCCESS" {
                    let molden = MoldenFile(moldenString: topJSON["molden"] as! String)
                    let dipoleArray = topJSON["dipole"] as! [NSNumber]

                    let dipole = Vec3(dipoleArray[0].floatValue, dipoleArray[1].floatValue, dipoleArray[2].floatValue)

                    completionHandler((molden, dipole))
                } else {
                    Thread.sleep(forTimeInterval: 1)
                    getResults(taskId: taskId, completionHandler: completionHandler)
                    return
                }

            } else {
                errorMessage = "TWS Internal server error 2"
            }
        }
        if !success {
            print(errorMessage)
            completionHandler(nil)
        }
    }
    task.resume()
}

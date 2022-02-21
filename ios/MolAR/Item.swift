//
//  Item.swift
//  MolAR
//
//  Created by Sukolsak on 3/11/21.
//

import UIKit
import SceneKit

enum Section {
    case main
}

/*
func imageFromPixelValues(data: NSData, width: Int, height: Int) -> UIImage? {
    let colorSpaceRef = CGColorSpaceCreateDeviceRGB()

    let bitsPerComponent = 8
    let bytesPerPixel = 4
    let bitsPerPixel = bytesPerPixel * bitsPerComponent
    let bytesPerRow = bytesPerPixel * width
    //let totalBytes = height * bytesPerRow

    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue)
        .union(.byteOrder32Little)
    guard let providerRef = CGDataProvider(data: data) else { return nil }
    guard let imageRef = CGImage(width: width,
                       height: height,
                       bitsPerComponent: bitsPerComponent,
                       bitsPerPixel: bitsPerPixel,
                       bytesPerRow: bytesPerRow,
                       space: colorSpaceRef,
                       bitmapInfo: bitmapInfo,
                       provider: providerRef,
                       decode: nil,
                       shouldInterpolate: false,
                       intent: .defaultIntent) else { return nil }

    return UIImage(cgImage: imageRef)
}
*/

class Item: Hashable {
    let name: String
    var image: UIImage
    let text: String
    let isPDB: Bool
    private let identifier = UUID()
    var isSuggestion = false
    var isFolder = false
    var preview: String? // Used in folders and vibrations that want to have an image

    var cachedStructure: SDFStructure?
    var cachedComputationResult: (MoldenFile, Vec3)?

    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    func imageURL() -> URL {
        // Note: The URL is really never loaded. We just use it as a cache key.
        return URL(string: "https://a/" + escapeQuery(name.replacingOccurrences(of: " ", with: "_")) + ".png")!
    }

    func getImage(completionHandler: @escaping (UIImage?) -> Void) {
        getUSDZURL(molecularModelMode: .ballAndStick, molecularOrbitalMode: .none, showDipoleMoment: false, vibrationalMode: nil, polymerMode: .cartoon) { url in
            guard let url = url else {
                completionHandler(nil)
                return
            }

            let sceneView = SCNView(frame:CGRect(x: 0, y: 0, width: 500, height: 500))
            sceneView.backgroundColor = .clear
            sceneView.autoenablesDefaultLighting = true

            let scene = try! SCNScene(url: url)
            sceneView.scene = scene
            let image = sceneView.snapshot()
            completionHandler(image)
        }
    }

    /*
    static private func loadURL(_ url: URL, _ filename: String, completionHandler: @escaping (URL?) -> Void) {
        // https://developer.apple.com/documentation/foundation/url_loading_system/downloading_files_from_websites

        // If it's already downloaded, return it.
        // FIXME: Need to use lock???
        // TODO: How temporary is this?

        let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let savedURL = temporaryDirectoryURL.appendingPathComponent(filename)
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: savedURL.path) {
            completionHandler(savedURL)
            return
        }

        // Otherwise, download it and return it.
        let downloadTask = URLSession.shared.downloadTask(with: url) {
            urlOrNil, responseOrNil, errorOrNil in
            // FIXMEL Cache this

            var success = false
            if let fileURL = urlOrNil,
               let urlResponse = responseOrNil,
               let httpURLResponse = urlResponse as? HTTPURLResponse,
               (httpURLResponse.statusCode == 200 && errorOrNil == nil) {
                try? fileManager.removeItem(at: savedURL)
                do {
                    try fileManager.moveItem(at: fileURL, to: savedURL)
                    success = true
                    DispatchQueue.main.async {
                        completionHandler(savedURL)
                    }
                } catch {
                }
            }
            if !success {
                DispatchQueue.main.async {
                    completionHandler(nil)
                }
            }
        }
        downloadTask.resume()
    }
    */


    func getUSDZURL(
        molecularModelMode: MolecularModelMode, molecularOrbitalMode: MolecularOrbitalMode,
        showDipoleMoment: Bool, vibrationalMode: Int?,
        polymerMode: PolymerMode,
        defaultScale: Float = 8.0, completionHandler: @escaping (URL?) -> Void) {
        if !isPDB {
            getSDFStructure() { structure in
                guard let structure = structure else {
                    DispatchQueue.main.async {
                        completionHandler(nil)
                    }
                    return
                }

                func helper2(_ molden: MoldenFile?, _ dipoleMoment: Vec3?) {
                    let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                    let savedURL = temporaryDirectoryURL.appendingPathComponent("tmp.usdz")

                    var vibrations: [Vec3]?
                    if let vibrationalMode = vibrationalMode {
                        vibrations = self.getVibrations()?[vibrationalMode]
                    } else {
                        // Hacky.
                        if let preview = self.preview {
                            let vibrationalMode = Int(self.name.suffix(self.name.count - preview.count))!
                            vibrations = self.getVibrations()![vibrationalMode]
                        }
                    }

                    DispatchQueue.global(qos: .userInitiated).async {
                        let myobj = convertSDFStructureToMYOBJ(structure, molecularModelMode: molecularModelMode, molden: molden, molecularOrbitalMode: molecularOrbitalMode, dipoleMoment: dipoleMoment, vibrations: vibrations)
                        let usdz = convertMYOBJToUSDZ(myobj, defaultScale: defaultScale)
                        DispatchQueue.main.async {
                            try! usdz.write(to: savedURL)
                            completionHandler(savedURL)
                        }
                    }
                }

                func helper(_ molden: MoldenFile?) {
                    if !showDipoleMoment {
                        helper2(molden, nil)
                    } else {
                        self.getDipoleMoment() { dipoleMoment in
                            helper2(molden, dipoleMoment)
                        }
                    }
                }

                if molecularOrbitalMode == .none {
                    helper(nil)
                } else {
                    self.getMolden() { molden in
                        helper(molden)
                    }
                }
            }
        } else {
            let name2 = polymerMode == .cartoon ? name : (name + "_gaussiansurface")
            let filename = escapeQuery(name2.replacingOccurrences(of: " ", with: "_")) + ".usdz"

            // If it's already in the bundle, return it.
            if let localURL = Bundle.main.url(forResource: "usdz/" + filename, withExtension: nil) {
                completionHandler(localURL)
                return
            }

            do {
                // Download BCIF from PDB and generate USDZ on device.

                // If it's already generated, return it.
                // FIXME: Need to use lock???
                // TODO: How temporary is this?
                let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                let savedURL = temporaryDirectoryURL.appendingPathComponent(filename)
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: savedURL.path) {
                    completionHandler(savedURL)
                    return
                }

                let m = Molrender()
                m.loadPDB(name, polymerMode: polymerMode) {data in
                    guard let data = data else {
                        completionHandler(nil)
                        return
                    }
                    try! data.write(to: savedURL)
                    completionHandler(savedURL)
                }
            }
        }
    }

    private func getSDFStructure(completionHandler: @escaping (SDFStructure?) -> Void) {
        if let structure = cachedStructure {
            completionHandler(structure)
            return
        }

        if let bsdf = Database.getBSDF(name: preview ?? name) {
            let structure = parseBSDF(bsdf)
            cachedStructure = structure
            completionHandler(structure)
        } else {
            getSDFFromSMILES(name) { sdf in
                guard let sdf = sdf else {
                    completionHandler(nil)
                    return
                }
                let structure = parseSDF(sdf)
                self.cachedStructure = structure
                completionHandler(structure)
            }
        }
    }

    private func getMolden(completionHandler: @escaping (MoldenFile?) -> Void) {
        if let bmolden = Database.getBmolden(name: preview ?? name) {
            let molden = MoldenFile(bmolden: bmolden)
            completionHandler(molden)
        } else {
            getComputationResult() { result in
                guard let result = result else {
                    completionHandler(nil)
                    return
                }
                completionHandler(result.0)
            }
        }
    }

    private func getDipoleMoment(completionHandler: @escaping (Vec3?) -> Void) {
        if let data = Database.getDipoleMoment(name: preview ?? name) {
            data.withUnsafeBytes { p in
                let v: Vec3 = (
                    p.load(fromByteOffset: 0, as: Float.self),
                    p.load(fromByteOffset: 4, as: Float.self),
                    p.load(fromByteOffset: 8, as: Float.self)
                )
                completionHandler(v)
            }
        } else {
            getComputationResult() { result in
                guard let result = result else {
                    completionHandler(nil)
                    return
                }
                completionHandler(result.1)
            }
        }
    }

    private func getComputationResult(completionHandler: @escaping ((MoldenFile, Vec3)?) -> Void) {
        if let result = cachedComputationResult {
            completionHandler(result)
            return
        }

        getSDFStructure() { structure in
            guard let structure = structure else {
                completionHandler(nil)
                return
            }
            getComputationResultFromSDFStructure(structure, self.preview ?? self.name) { result in
                guard let result = result else {
                    completionHandler(nil)
                    return
                }
                self.cachedComputationResult = result
                completionHandler(result)
            }
        }
    }

    private func getVibrations() -> [[Vec3]]? {
        guard let data = Database.getVibrations(name: preview ?? name) else { return nil }
        var modes = [[Vec3]]()
        data.withUnsafeBytes { p in
            let nModes = Int(p.load(fromByteOffset: 0, as: UInt32.self))
            let nAtoms = ((data.count - 4) / nModes) / 12
            var i = 4
            for _ in 0 ..< nModes {
                var displacements = [Vec3]()
                for _ in 0 ..< nAtoms {
                    let v: Vec3 = (
                        p.load(fromByteOffset: i, as: Float.self),
                        p.load(fromByteOffset: i + 4, as: Float.self),
                        p.load(fromByteOffset: i + 8, as: Float.self)
                    )
                    displacements.append(v)
                    i += 12
                }
                modes.append(displacements)
            }
        }
        return modes
    }

    func getLocalImage() -> UIImage? {
        let name2 = (preview != nil) ? preview! : name
        return UIImage(named: "previews/" + name2.replacingOccurrences(of: " ", with: "_") + ".png")
    }

    static private func escapeURL(_ s: String) -> String {
        return s.replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "%", with: "%25")
            .replacingOccurrences(of: "#", with: "%23")
            .replacingOccurrences(of: "[", with: "%5B")
            .replacingOccurrences(of: "\\", with: "%5C")
            .replacingOccurrences(of: "]", with: "%5D")
            .replacingOccurrences(of: " ", with: "%20")
    }

    func getData(completionHandler: @escaping (Any?) -> Void) {
        if let data = Database.getData(name: name) {
            completionHandler(data)
            return
        }

        var request: URLRequest
        if isPDB {
            // request = URLRequest(url: URL(string: "https://data.rcsb.org/rest/v1/core/entry/" + name)!)
            request = URLRequest(url: URL(string: "https://data.rcsb.org/graphql")!)
            request.httpMethod = "POST"
            /*
             Don't need
             rcsb_entry_info {
               molecular_weight
               deposited_atom_count
               deposited_modeled_polymer_monomer_count
               polymer_entity_count_protein
               polymer_entity_count_nucleic_acid
               polymer_entity_count_nucleic_acid_hybrid
             }
             */
            request.httpBody = try! JSONSerialization.data(withJSONObject: [
                "query": """
{entry(entry_id:"
""" + name + """
"){
struct{title}
audit_author{name}
exptl{method}
rcsb_entry_info{resolution_combined}
struct_keywords{pdbx_keywords}
polymer_entities{
rcsb_entity_source_organism{ncbi_scientific_name}
rcsb_entity_host_organism{ncbi_scientific_name}
}
}}
""".replacingOccurrences(of: "\n", with: ""),
                "variables": nil
            ])
        } else {
            // For now. Because we are using NCI (Cactus), not PubChem.
            completionHandler(nil)
            return

            //request = URLRequest(url: URL(string: "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/" + Self.escapeURL(name) + "/JSON")!)
        }
        //let url = URL(string: isPDB ? ("https://data.rcsb.org/rest/v1/core/entry/" + name) : ("https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/name/" + Self.escapeURL(name) + "/JSON"))!

        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data,
                  let httpURLResponse = response as? HTTPURLResponse,
                  httpURLResponse.statusCode == 200 else {
                DispatchQueue.main.async {
                    completionHandler(nil)
                }
                return
            }
            var jsonData = try? JSONSerialization.jsonObject(with: data)
            if self.isPDB {
                jsonData = (jsonData as? [String: [String: Any]])?["data"]?["entry"]
            }
            DispatchQueue.main.async {
                completionHandler([jsonData, nil, nil])
            }
        }
        task.resume()
    }

    init(name: String, text: String, isPDB: Bool) {
        self.name = name
        self.image = ImageCache.publicCache.placeholderImage
        self.text = text
        self.isPDB = isPDB
    }
}

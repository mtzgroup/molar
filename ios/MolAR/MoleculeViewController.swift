//
//  MoleculeViewController.swift
//  MolAR
//
//  Created by Sukolsak on 3/13/21.
//

import UIKit
import QuickLook
import SceneKit
import SceneKit.ModelIO

class MoleculeViewController: UIViewController, QLPreviewControllerDataSource, MoleculeMenuViewControllerDelegate, UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var sceneView: SCNView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var viewARButton: UIButton!

    private var selectedURL: URL?

    var item: Item!

    private var molecularModelMode: MolecularModelMode = .ballAndStick
    private var molecularOrbitalMode: MolecularOrbitalMode = .none
    private var showDipoleMoment: Bool = false
    private var vibrationalMode: Int?

    private var polymerMode: PolymerMode = .cartoon

//    init(item: Item) {
//        super.init(nibName: nil, bundle: nil)
//        self.item = item
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = (item.isSuggestion && !item.isPDB) ? item.name : item.text // Hacky

        view.backgroundColor = .systemBackground

        // let sceneView = SCNView(frame:CGRect(x: 0.0, y: 100.0, width: 320.0, height: 320.0))
        //sceneView.backgroundColor = .systemBackground
        sceneView.backgroundColor = .secondarySystemBackground
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true

        //view.addSubview(sceneView)

        viewARButton.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .title3).pointSize, weight: .semibold)

        loadModel(true)

        let headlineFont = UIFont.preferredFont(forTextStyle: .title2)
        let headline = [
            NSAttributedString.Key.font: headlineFont,
            NSAttributedString.Key.foregroundColor: UIColor.label]
        let normalFont = UIFont.preferredFont(forTextStyle: .body)
        let fontSize = normalFont.pointSize
        let boldFont = UIFont.boldSystemFont(ofSize: fontSize)
        let normal = [
            NSAttributedString.Key.font: normalFont,
            NSAttributedString.Key.foregroundColor: UIColor.label]
        let bold = [
            NSAttributedString.Key.font: boldFont,
            NSAttributedString.Key.foregroundColor: UIColor.label]
        let footnote = [
            NSAttributedString.Key.font: normalFont,
            NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
        let footnoteBold = [
            NSAttributedString.Key.font: boldFont,
            NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]


        textView.text = "Loading..."

        if item.isPDB {
            item.getData() { [weak self] (data) in
                guard let self = self else { return }
                guard let data = data else {
                    //DispatchQueue.main.async {
                        self.textView.text = "Couldn't load the information"
                    //}
                    return
                }
                if let data = data as? [Any],
                   let topJSON = data[0] as? [String: Any] {
                    let title = (topJSON["struct"] as? [String: Any])?["title"] as? String ?? ""
                    let authors = ((topJSON["audit_author"] as? [Any])?.compactMap { author in
                        (author as? [String: Any])?["name"] as? String
                    })
                    let method = ((topJSON["exptl"] as? [Any])?[0] as? [String: Any])?["method"] as? String
                    let resolution = ((topJSON["rcsb_entry_info"] as? [String: Any])?["resolution_combined"] as? [Double])?.first
                    let classification = (topJSON["struct_keywords"] as? [String: Any])?["pdbx_keywords"] as? String
                    var sources = [String]()
                    var hosts = [String]()
                    if let entities = topJSON["polymer_entities"] as? [Any] {
                        //if let host =
                        for entity in entities {
                            guard let entity = entity as? [String: Any] else { continue }
                            if let source = (entity["rcsb_entity_source_organism"] as? [[String: Any]])?[0]["ncbi_scientific_name"] as? String {
                                if !sources.contains(source) {
                                    sources.append(source)
                                }
                            }
                            if let host = (entity["rcsb_entity_host_organism"] as? [[String: Any]])?[0]["ncbi_scientific_name"] as? String {
                                if !hosts.contains(host) {
                                    hosts.append(host)
                                }
                            }
                        }
                    }

                    let pdbId: String = self.item.name.uppercased()
                    self.title = title

                    let text = NSMutableAttributedString()
                    text.append(NSAttributedString(string: title + "\n", attributes: headline))
                    text.append(NSAttributedString(string: "\n", attributes: normal))

                    text.append(NSAttributedString(string: "PDB ID: ", attributes: bold))
                    text.append(NSAttributedString(string: pdbId + "\n", attributes: [NSAttributedString.Key.font: normalFont, NSAttributedString.Key.link: "https://www.rcsb.org/structure/" + pdbId]))
                    if let classification = classification {
                        text.append(NSAttributedString(string: "Classification: ", attributes: bold))
                        text.append(NSAttributedString(string: classification + "\n", attributes: normal))
                    }
                    if sources.count > 0 {
                        text.append(NSAttributedString(string: "Organism" + ((sources.count != 1) ? "s" : "") + ": ", attributes: bold))
                        text.append(NSAttributedString(string: sources.joined(separator: ", ") + "\n", attributes: normal))
                    }
                    if hosts.count > 0 {
                        text.append(NSAttributedString(string: "Expression system" + ((hosts.count != 1) ? "s" : "") + ": ", attributes: bold))
                        text.append(NSAttributedString(string: hosts.joined(separator: ", ") + "\n", attributes: normal))
                    }
                    text.append(NSAttributedString(string: "\n", attributes: normal))
                    if var method = method {
                        switch method {
                        case "SOLUTION NMR": method = "Solution NMR"
                        case "ELECTRON MICROSCOPY": method = "Electron microscopy"
                        case "X-RAY DIFFRACTION": method = "X-ray diffraction"
                        default: break
                        }
                        text.append(NSAttributedString(string: "Method: ", attributes: bold))
                        text.append(NSAttributedString(string: method + "\n", attributes: normal))
                        if let resolution = resolution {
                            text.append(NSAttributedString(string: "Resolution: ", attributes: bold))
                            text.append(NSAttributedString(string: String(format: "%.2f", resolution) + " Å\n", attributes: normal))
                        }
                        text.append(NSAttributedString(string: "\n", attributes: normal))
                    }
                    if let authors = authors {
                        text.append(NSAttributedString(string: "Deposition author" + ((authors.count != 1) ? "s" : "") + ": ", attributes: footnoteBold))
                        text.append(NSAttributedString(string: authors.joined(separator: ", ") + "\n", attributes: footnote))
                    }
                    text.append(NSAttributedString(string: "Source: ", attributes: footnoteBold))
                    text.append(NSAttributedString(string: "The Protein Data Bank", attributes: footnote))

                    //DispatchQueue.main.async {
                        self.textView.attributedText = text
                    //}
                } else {
                    DispatchQueue.main.async {
                        // self.textView.text = "Couldn't load the information"
                    }
                }
            }
        } else {
            item.getData() { [weak self] (data) in
                guard let self = self else { return }
                guard let data = data else {
                    // self.textView.text = "Couldn't load the information"

                    let item = self.item!
                    let tmp = (item.isSuggestion && !item.isPDB) ? item.name : item.text // Hacky
                    self.textView.attributedText = NSAttributedString(string: tmp, attributes: bold)

                    return
                }
                if let data = data as? [Any],
                   let topJSON = data[0] as? [String: Any],
                   let compounds = topJSON["PC_Compounds"] as? [Any],
                   let props = (compounds[0] as? [String: Any])?["props"] as? [Any] {

                    var formula: String?
                    var mass: Double?
                    for prop in props {
                        if let prop = prop as? [String: Any],
                           let urn = prop["urn"] as? [String: Any],
                           let label = urn["label"] as? String {

                            if label == "Molecular Formula" {
                                formula = (prop["value"] as? [String: Any])?["sval"] as? String
                            // } else if label == "Molecular Weight" {
                            } else if label == "Molecular Weight" {
                                mass = (prop["value"] as? [String: Any])?["fval"] as? Double
                            }
                        }
                    }

                    let text = NSMutableAttributedString()
                    text.append(NSAttributedString(string: self.item.text + "\n", attributes: headline))
                    text.append(NSAttributedString(string: "\n", attributes: normal))
                    if let description = data[1] as? String {
                        text.append(NSAttributedString(string: description + "\n\n", attributes: normal))
                    }
                    if let formula = formula {
                        let formula2 = String(formula.map({x -> Character in
                            let c = x.asciiValue!
                            return (48 <= c && c <= 57) ? Character(Unicode.Scalar(Int(c) - 48 + 8320)!) : x
                        }))
                        text.append(NSAttributedString(string: "Chemical formula: ", attributes: bold))
                        text.append(NSAttributedString(string: formula2 + "\n", attributes: normal))
                    }
                    if let mass = mass {
                        text.append(NSAttributedString(string: "Molecular weight: ", attributes: bold))
                        text.append(NSAttributedString(string: String(mass) + " g/mol\n", attributes: normal))
                    }
                    text.append(NSAttributedString(string: "\n", attributes: normal))
                    text.append(NSAttributedString(string: "Source: ", attributes: footnoteBold))
                    text.append(NSAttributedString(string: "NCI/CADD, PubChem", attributes: footnote))
                    if let descriptionSource = data[2] as? String {
                        text.append(NSAttributedString(string: ", " + descriptionSource, attributes: footnote))
                    }

                    //DispatchQueue.main.async {
                        self.textView.attributedText = text
                    //}
                } else {
                    //DispatchQueue.main.async {
                        // self.textView.text = "Couldn't load the information"
                        self.textView.attributedText = NSAttributedString(string: self.item.text, attributes: bold)
                    //}
                }
            }
        }

        if navigationItem.rightBarButtonItem == nil { // could be the Done button
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(showMenu))
        }
    }

    private func loadModel(_ firstTime: Bool) {
        item.getUSDZURL(
            molecularModelMode: molecularModelMode,
            molecularOrbitalMode: molecularOrbitalMode,
            showDipoleMoment: showDipoleMoment,
            vibrationalMode: vibrationalMode,
            polymerMode: polymerMode
        ) { [weak self] url in
            guard let self = self else { return }
            guard let url = url else {
                //if firstTime {
                //    self.activityIndicator.removeFromSuperview()
                //}
                self.activityIndicator.isHidden = true
                self.activityIndicator.stopAnimating()
                self.textView.text = "Molecule not found"
                self.viewARButton.isEnabled = false
                self.viewARButton.backgroundColor = .systemGray
                return
            }
            let scene = try! SCNScene(url: url)
            self.sceneView.scene = scene
            //if firstTime {
            //    self.activityIndicator.removeFromSuperview()
            //}
            self.activityIndicator.isHidden = true
            self.activityIndicator.stopAnimating()

            /*
            // Auto rotate the camera
            if let camera = self.sceneView.pointOfView {
                // TODO: If we click "View AR" or do something else, the timer should stop.
                Timer.scheduledTimer(withTimeInterval: 0.0, repeats: false) { [weak self] timer in
                    // The camera check is to check that the user still hasn't moved the camera
                    guard let self = self, camera === self.sceneView.pointOfView else { return }

                    self.sceneView.play(nil) // FIXME: Should we really use this? or use rendersContinuously ?

                    let position = camera.simdPosition
                    let r = sqrt(position.x * position.x + position.z * position.z)
                    var t: Float = 0.0
                    let timer = Timer(timeInterval: 0.03, repeats: true) { [weak self] timer in
                        guard let self = self else { return }
                        guard camera === self.sceneView.pointOfView else {
                            self.sceneView.stop(nil)
                            timer.invalidate()
                            return
                        }
                        camera.simdPosition = [sin(t) * r, position.y, cos(t) * r]
                        camera.simdOrientation = simd_quatf(ix: 0.0, iy: sin(t / 2), iz: 0, r: cos(t / 2))
                        t += 0.002
                    }
                    RunLoop.current.add(timer, forMode: .common)
                }
            }
            */
        }
    }

    @IBAction func viewAR() {
        item.getUSDZURL(
            molecularModelMode: molecularModelMode,
            molecularOrbitalMode: molecularOrbitalMode,
            showDipoleMoment: showDipoleMoment,
            vibrationalMode: vibrationalMode,
            polymerMode: polymerMode
        ) { [weak self] url in
            guard let self = self, let url = url else { return }
            self.selectedURL = url

            let previewController = QLPreviewController()
            previewController.dataSource = self
            self.present(previewController, animated: true, completion: nil)
        }
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let previewItem = selectedURL! as QLPreviewItem
        // previewItem.previewItemTitle = "TEST"
        return previewItem
    }

    @objc private func showMenu(sender: Any?) {
        let vc = MoleculeMenuViewController()
        vc.modalPresentationStyle = .popover
        vc.isPDB = item.isPDB
        vc.molecularModelMode = molecularModelMode
        vc.molecularOrbitalMode = molecularOrbitalMode
        vc.showDipoleMoment = showDipoleMoment
        vc.polymerMode = polymerMode
        vc.delegate = self

        if let popoverController = vc.popoverPresentationController, let button = sender as? UIBarButtonItem {
            popoverController.delegate = self
            popoverController.barButtonItem = button
        }

        present(vc, animated: false, completion: nil)
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    func moleculeMenuViewController(_: MoleculeMenuViewController, didSelectMolecularModelMode mode: MolecularModelMode) {
        if molecularModelMode != mode {
            molecularModelMode = mode
            loadModel(false)
        }
    }

    func moleculeMenuViewController(_: MoleculeMenuViewController, didSelectMolecularOrbitalMode mode: MolecularOrbitalMode) {
        if molecularOrbitalMode != mode {
            molecularOrbitalMode = mode
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
            loadModel(false)
        }
    }

    func moleculeMenuViewController(_ menuViewController: MoleculeMenuViewController, didChangeShowDipoleMoment show: Bool) {
        if showDipoleMoment != show {
            showDipoleMoment = show
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
            loadModel(false)
        }
    }

    func moleculeMenuViewController(_: MoleculeMenuViewController, didSelectPolymerMode mode: PolymerMode) {
        if polymerMode != mode {
            polymerMode = mode
            self.activityIndicator.isHidden = false
            self.activityIndicator.startAnimating()
            loadModel(false)
        }
    }
}








protocol MoleculeMenuViewControllerDelegate: AnyObject {
    func moleculeMenuViewController(_ menuViewController: MoleculeMenuViewController, didSelectMolecularModelMode: MolecularModelMode)
    func moleculeMenuViewController(_ menuViewController: MoleculeMenuViewController, didSelectMolecularOrbitalMode: MolecularOrbitalMode)
    func moleculeMenuViewController(_ menuViewController: MoleculeMenuViewController, didChangeShowDipoleMoment: Bool)
    func moleculeMenuViewController(_ menuViewController: MoleculeMenuViewController, didSelectPolymerMode: PolymerMode)
}

class MoleculeMenuViewController: UITableViewController {
    private let modeNames: [[String]] = [
        ["Ball-and-Stick", "Space-Filling", "Skeletal"],
        ["Hide Orbitals", "Show HOMO", "Show LUMO"],
        ["Hide Dipole Moment", "Show Dipole Moment"]
    ]
    private let pdbModeNames: [[String]] = [
        ["Cartoon", "Gaussian Surface"],
    ]
    var isPDB: Bool = false
    var molecularModelMode: MolecularModelMode = .ballAndStick
    var molecularOrbitalMode: MolecularOrbitalMode = .none
    var showDipoleMoment: Bool = false
    var polymerMode: PolymerMode = .cartoon

    weak var delegate: MoleculeMenuViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    override func viewWillLayoutSubviews() {
        preferredContentSize = CGSize(width: 250, height: tableView.contentSize.height)
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
        if isPDB {
            if section == 0 {
                delegate?.moleculeMenuViewController(self, didSelectPolymerMode: PolymerMode(rawValue: row)!)
            }
        } else {
            if section == 0 {
                delegate?.moleculeMenuViewController(self, didSelectMolecularModelMode: MolecularModelMode(rawValue: row)!)
            } else if section == 1 {
                delegate?.moleculeMenuViewController(self, didSelectMolecularOrbitalMode: MolecularOrbitalMode(rawValue: row)!)
            } else {
                delegate?.moleculeMenuViewController(self, didChangeShowDipoleMoment: row == 1)
            }
        }
        dismiss(animated: true, completion: nil)
    }


    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isPDB ? pdbModeNames[section].count : modeNames[section].count
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return isPDB ? 1 : 3
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return nil }
        return " "
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1.0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) // as! UITableViewCell
        let checked: Bool
        let section = indexPath.section
        let row = indexPath.row
        if isPDB {
            checked = row == polymerMode.rawValue
        } else {
            if section == 0 {
                checked = row == molecularModelMode.rawValue
            } else if section == 1 {
                checked = row == molecularOrbitalMode.rawValue
            } else {
                checked = (row == 1) == showDipoleMoment
            }
        }
        cell.accessoryType = checked ? .checkmark : .none
        cell.textLabel!.text = isPDB ? pdbModeNames[section][row] : modeNames[section][row]
        return cell
    }
}

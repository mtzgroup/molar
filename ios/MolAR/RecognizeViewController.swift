//
//  RecognizeViewController.swift
//  MolAR
//
//  Created by Sukolsak on 2/15/21.
//

import UIKit
import SceneKit
import ARKit
import VideoToolbox

class RecognizeViewController: UIViewController, ARSCNViewDelegate, UIGestureRecognizerDelegate, UIPopoverPresentationControllerDelegate, MoleculeSelectionViewControllerDelegate, MoleculeMenuViewControllerDelegate {

    @IBOutlet weak var sceneView: ARSCNView!

    /// A serial queue used to coordinate adding or removing nodes from the scene.
    private let updateQueue = DispatchQueue(label: "com.sukolsak.MolAR.serialSceneKitQueue")

    private var shouldUpdateAnchor = true

    private var myAnchor: ARAnchor?
    // var myObject: SCNNode?

    private var moleculeNode: MoleculeNode?
    private var trackedRaycast: ARTrackedRaycast?

    private var isLoading = false
    private var showsControls = true
    private var showsMolecule = false
    private var isInitializing = true
    private var _controlsVisible = false // == showsControls && !isInitializing
    private var resultMolecules: [String] = []
    private var selectedMolecule: String = ""
    private var selectedItem: Item?

    private var lastPosition: SIMD3<Float> = SIMD3<Float>(0,0,0)

    @IBOutlet weak var focusView: FocusView!

    @IBOutlet weak var recognizeButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var selectObjectButton: UIButton!

    @IBOutlet weak var cameraAccessLabel: UILabel!
    @IBOutlet weak var cameraAccessButton: UIButton!

    @IBOutlet weak var modeSegmentedControl: UISegmentedControl!

    private var messageHideTimer: Timer?

    private var cameraOK = false
    private var cameraNotOKReason = ""
    private var currentMessage: String?

    private enum ScanMode {
        case structure
        case object
    }
    private var mode: ScanMode = .structure

    private let structureRecognitionFailMessage = "Can't recognize the structure. Tap here for tips."

    private var molecularModelMode: MolecularModelMode = .ballAndStick
    private var molecularOrbitalMode: MolecularOrbitalMode = .none
    private var showDipoleMoment: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        sceneView.delegate = self
        //sceneView.showsStatistics = true

        // Create a new scene
        //let scene = SCNScene(named: "art.scnassets/water.usdz")!
        sceneView.autoenablesDefaultLighting = false

        //sceneView.scene = scene


        //let cameraNode = sceneView.pointOfView!

        let keyLight = SCNLight()
        keyLight.type = SCNLight.LightType.omni
        keyLight.intensity = 200
        //keyLight.castsShadow = true
        let keyLightNode = SCNNode()
        keyLightNode.light = keyLight
        keyLightNode.position = SCNVector3(x: 0, y: 10, z: 0)
        sceneView.scene.rootNode.addChildNode(keyLightNode)


        /*
        let ambientLight = SCNLight()
        ambientLight.type = SCNLight.LightType.ambient
        let shade: CGFloat = 0.40
        ambientLight.color = UIColor(red: shade, green: shade, blue: shade, alpha: 1.0)
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        cameraNode.addChildNode(ambientLightNode)
        */

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        //tapGesture.delegate = self  // ???? NEED?????
        sceneView.addGestureRecognizer(tapGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        //panGesture.delegate = self
        sceneView.addGestureRecognizer(panGesture)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        //pinchGesture.delegate = self
        sceneView.addGestureRecognizer(pinchGesture)

        /*
        let vibrancy = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: UIBlurEffect(style: .light)))
        vibrancy.frame = recognizeButton.bounds

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blur.frame = recognizeButton.bounds
        blur.isUserInteractionEnabled = false
        //blur.contentView.addSubview(vibrancy)
        recognizeButton.layer.cornerRadius = 22.0
        recognizeButton.clipsToBounds = true
        recognizeButton.insertSubview(blur, at: 0)
        */

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "questionmark.circle"), style: .plain, target: self, action: #selector(showHelp))

        modeSegmentedControl.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)], for: .normal)
        modeSegmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.link], for: .selected)


        let tapGesture2 = UITapGestureRecognizer(target: self, action: #selector(showTips(sender:)))
        messageLabel.addGestureRecognizer(tapGesture2)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.environmentTexturing = .automatic

        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        sceneView.session.pause()
    }

    private func updateMessage() {
        if let msg = currentMessage {
            messageLabel.text = msg
            messageLabel.alpha = 1
        } else if !cameraOK && showsControls {
            messageLabel.text = cameraNotOKReason
            messageLabel.alpha = 1
        } else {
            messageLabel.text = ""
        }
    }

    private func showMessage(_ text: String?) {
        messageHideTimer?.invalidate()

        currentMessage = text
        updateMessage()

        if text != nil {
            messageHideTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { [weak self] _ in
                self?.hideMessage()
            })
        }
    }

    private func hideMessage() {
        currentMessage = nil
        if cameraOK {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState], animations: {
                self.messageLabel.alpha = 0
            }, completion: nil)
        } else {
            updateMessage()
        }
    }

    private func sendPicToServer() {

        //moleculeNode?.isHidden = true
        //focusSquare.isHidden = true
        //let image = sceneView.snapshot()
        //let image = UIImage(sceneView.session.currentFrame!.capturedImage)
        guard let currentFrame = sceneView.session.currentFrame else { return }
        //let pixelBuffer = sceneView.session.currentFrame!.capturedImage
        var cgImageTmp: CGImage?
        VTCreateCGImageFromCVPixelBuffer(currentFrame.capturedImage, options: nil, imageOut: &cgImageTmp)

        guard let cgImage = cgImageTmp else { return }

        // Crop and fix the orientation
        let width = cgImage.width
        let height = cgImage.height
        var size = min(width, height)
        if mode == .structure {
            size = Int(Double(size) * 0.7)
        }
        let cropRect = CGRect(x: (width - size) / 2, y: (height - size) / 2, width: size, height: size)
        guard let cgImage2 = cgImage.cropping(to: cropRect) else { return }
        // let isLandscape = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation.isLandscape ?? false
        let image = UIImage(cgImage: cgImage2, scale: 1.0, orientation: .right)
        let imageData = image.jpegData(compressionQuality: 0.8)!


        //moleculeNode?.isHidden = false
        //focusSquare.isHidden = false

        // https://stackoverflow.com/questions/29623187/upload-image-with-multipart-form-data-ios-in-swift

        let url: URL
        if mode == .structure {
            url = URL(string: serverAddress + "/api/molar_recognize_structure")!
        } else {
            url = URL(string: serverAddress + "/api/molar_recognize_object")!
        }

        // generate boundary string using a unique per-app string
        let boundary = UUID().uuidString

        // Set the URLRequest to POST and to the specified URL
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var data = Data()

        // Add the image data to the raw http request data
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"test.jpg\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        data.append(imageData)

        data.append("\r\n--\(boundary)--".data(using: .utf8)!)

        let localMode = mode

        let task = URLSession.shared.uploadTask(with: urlRequest, from: data) { responseData, response, error in
            var success = false
            var errorMessage = "Can't connect to the server"
            if error == nil {
                let jsonData = try? JSONSerialization.jsonObject(with: responseData!, options: .allowFragments)
                if let topJSON = jsonData as? [String: Any] {
                    //print(json)
                    success = true

                    if localMode == .structure {
                        if let molecules = topJSON["molecules"] as? [String], molecules.count > 0 {
                            let molecule = molecules[0]

                            DispatchQueue.main.async {
                                self.showMessage(molecule)
                                self.resultMolecules = molecules
                                self.molecularOrbitalMode = .none
                                self.showDipoleMoment = false
                                self.loadMolecule(molecule)
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.moleculeNode!.hideLoading()
                                self.isLoading = false
                                self.showMessage(self.structureRecognitionFailMessage)
                                self.showsControls = true
                                self.updateViews()
                            }
                        }
                    } else {

                        let json = topJSON
                        let obj = json["object"] as! String

                        if let molecules = json["molecules"] as? [String], molecules.count > 0 {
                            let molecule = molecules[0]
                            DispatchQueue.main.async {
                                self.showMessage((obj == molecule) ? obj : (obj + ": " + molecule))

                                self.resultMolecules = molecules
                                self.molecularOrbitalMode = .none
                                self.showDipoleMoment = false
                                self.loadMolecule(molecule)

                                // Don't show this for now. I don't have time to implement this.
                                //self.selectObjectButton.isHidden = false
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.moleculeNode!.hideLoading()
                                self.isLoading = false
                                self.showMessage("Can't find molecules that match \"" + obj + "\"")
                                self.showsControls = true
                                self.updateViews()
                            }
                        }

                    }

                } else {
                    errorMessage = "Internal server error"
                }
            }
            if !success {
                DispatchQueue.main.async {
                    self.moleculeNode!.hideLoading()
                    self.isLoading = false
                    self.showMessage(errorMessage)
                    self.showsControls = true
                    self.updateViews()
                }
            }
        }
        task.resume()
    }


    private func loadMolecule(_ molecule: String) {
        selectedMolecule = molecule
        if let item = selectedItem, item.name == molecule {
        } else {
            selectedItem = Item(name: molecule, text: molecule, isPDB: (mode == .structure) ? false : isNamePDB(molecule))
        }

        isLoading = true

        moleculeNode!.setMainNode(nil)
        moleculeNode!.showLoading()
        showsControls = false
        updateViews()

        selectedItem!.getUSDZURL(
            molecularModelMode: molecularModelMode,
            molecularOrbitalMode: molecularOrbitalMode,
            showDipoleMoment: showDipoleMoment,
            vibrationalMode: nil,
            polymerMode: .cartoon,
            defaultScale: (mode == .structure) ? 2.0 : 8.0
        ) { url in
            guard let url = url else {
                self.moleculeNode!.hideLoading()
                self.isLoading = false
                self.showMessage("Can't load the 3D model")
                self.showsControls = true
                self.updateViews()
                return
            }
            self.loadLocalFile(url)
        }
    }

    private func loadLocalFile(_ url: URL) {
        let object = SCNReferenceNode(url: url)!
        //object.castsShadow = true
        // moleculeNode!.castsShadow = true

        //DispatchQueue.global(qos: .userInitiated).async {
        self.updateQueue.async {
            object.load()

            //let scene = try! SCNScene(url: object.referenceURL, options: nil)
            //self.sceneView.prepare([scene], completionHandler: { _ in
            self.sceneView.prepare([object], completionHandler: { _ in

                object.simdScale = simd_float3(0.000001, 0.000001, 0.000001)

                //let material = object.geometry?.firstMaterial
                //material?.lightingModel = .physicallyBased

                /*
                func setMaterial(_ node: SCNNode) {
                    let material = node.geometry!.firstMaterial!
                    //material.lightingModel = .physicallyBased
                    material.metalness.intensity = 1
                    material.roughness.contents = 0
                }
                for node in object.childNodes[0].childNodes {
                    setMaterial(node)
                }
                */


                // The original lookAt vector is (0, 0, -1).
                // We first find where it's currently at.
                // Then we erase the y component (call the new vector tmp) and find the orientation
                let lookAt = simd_act(self.sceneView.pointOfView!.simdOrientation, simd_float3(0, 0, 1))
                self.moleculeNode!.eulerAngles.y = atan2(lookAt.x, lookAt.z)


                self.moleculeNode!.hideLoading()
                self.moleculeNode!.setMainNode(object)

                DispatchQueue.main.async {
                    self.isLoading = false
                    self.showsMolecule = true
                }
            })

        }
    }


    private var intialEulerY: Float = 0

    @objc private func didPan(_ gesture: UIPanGestureRecognizer) {
        guard let moleculeNode = moleculeNode, !isLoading else { return }

        switch gesture.state {
        case .began:
            intialEulerY = moleculeNode.eulerAngles.y

        case .changed:
            let translation = gesture.translation(in: sceneView)
            moleculeNode.eulerAngles.y = intialEulerY + Float(translation.x) * 0.006

        default:
            break
        }
    }

    private var initialScale: Float = 0

    @objc private func didPinch(_ gesture: UIPinchGestureRecognizer) {
        guard let moleculeNode = moleculeNode, !isLoading else { return }

        switch gesture.state {
        case .began:
            initialScale = moleculeNode.scale.x
            fallthrough
        case .changed:
            let scale = initialScale * Float(gesture.scale)
            moleculeNode.simdScale = simd_float3(scale, scale, scale)
        default:
            break
        }
    }

    @objc private func didTap(_ gesture: UITapGestureRecognizer) {
        if !showsMolecule {
            return
        }

        var hit = false
        if mode == .object {
            if moleculeNode != nil {
                let touchLocation = gesture.location(in: sceneView)
                let hitTestOptions: [SCNHitTestOption: Any] = [.boundingBoxOnly: true]
                let hitTestResults = sceneView.hitTest(touchLocation, options: hitTestOptions)
                let hitMolecule = hitTestResults.lazy.contains { result in
                    var n: SCNNode? = result.node
                    while n != nil {
                        if n == self.moleculeNode {
                            return true
                        }
                        n = n!.parent
                    }
                    return false
                }
                if hitMolecule {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "moleculeViewController") as! MoleculeViewController
                    vc.item = Item(name: selectedMolecule, text: selectedMolecule, isPDB: isNamePDB(selectedMolecule))
                    vc.title = selectedMolecule
                    vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissMoleculeInfo))

                    let nav = UINavigationController(rootViewController: vc)
                    present(nav, animated: true, completion: nil)

                    hit = true
                    return
                }
            }
        }
        if !hit {
            showsControls = !showsControls
            updateViews()
            updateMessage()
        }
    }

    @objc private func dismissMoleculeInfo() {
        dismiss(animated: true, completion: nil)
    }

    private func clearMolecule() {
        if moleculeNode != nil {
            moleculeNode!.removeFromParentNode()
            moleculeNode = nil
        }
        if myAnchor != nil {
            sceneView.session.remove(anchor: myAnchor!)
            myAnchor = nil
        }
        if trackedRaycast != nil {
            trackedRaycast!.stopTracking()
            trackedRaycast = nil
        }

        showsMolecule = false
        resultMolecules = []
        selectedMolecule = ""
        selectObjectButton.isHidden = true

        navigationItem.rightBarButtonItem = nil
    }

    @IBAction func recognize() {

        if isLoading {
            return
        }

        let middlePoint = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
        let query = sceneView.raycastQuery(from: middlePoint, allowing: .estimatedPlane, alignment: .any)

        let placePosition: SIMD3<Float>

        if let query = query,
           let result = sceneView.session.raycast(query).first {
            lastPosition = result.worldTransform.translation
            placePosition = lastPosition
        } else {
            // We don't have the actual position.
            // What we can do: put the object at the center. Estimate the distance
            // from the last position we know.

            // The original lookAt vector is (0, 0, -1).
            let lookAt = simd_act(self.sceneView.pointOfView!.simdOrientation, simd_float3(0, 0, -1))

            let camera = sceneView.session.currentFrame!.camera

            let v = lastPosition - camera.transform.translation
            placePosition = camera.transform.translation + min(simd_dot(v, lookAt), 0.5) * lookAt
        }


        clearMolecule()
        moleculeNode = MoleculeNode()


        showsControls = false
        updateViews()
        showMessage(nil)

        moleculeNode!.simdWorldPosition = placePosition
        sceneView.scene.rootNode.addChildNode(moleculeNode!)
        shouldUpdateAnchor = true

        // FIXME: In the background???

        isLoading = true

        sendPicToServer()

        if let query = query {
            trackedRaycast = sceneView.session.trackedRaycast(query) { (results) in

                guard let result = results.first else {
                    fatalError("Unexpected case: the update handler is always supposed to return at least one result.")
                }

                //self.moleculeNode!.simdWorldTransform = result.worldTransform;

                self.moleculeNode!.simdWorldPosition = result.worldTransform.translation

                if self.shouldUpdateAnchor {
                    self.shouldUpdateAnchor = false
                    self.updateQueue.async {
                        //self.sceneView.addOrUpdateAnchor(for: object)


                        // if let anchor = self.myAnchor {
                        //     self.sceneView.session.remove(anchor: anchor)
                        // }

                        // Create a new anchor with the object's current transform and add it to the session
                        let newAnchor = ARAnchor(transform: self.moleculeNode!.simdWorldTransform)
                        self.myAnchor = newAnchor
                        self.sceneView.session.add(anchor: newAnchor)
                    }
                }
            }
        }
    }


    private func updateViews() {
        let oldControlsVisible = _controlsVisible;
        _controlsVisible = showsControls && !isInitializing
        if _controlsVisible {
            if !oldControlsVisible {
                UIView.animate(withDuration: 0.25) {
                    self.modeSegmentedControl.alpha = 1
                    self.recognizeButton.alpha = 1
                    self.focusView.unhide()
                }
                if let moleculeNode = moleculeNode {
                    moleculeNode.isHidden = true
                }
                selectObjectButton.isHidden = true

                navigationItem.rightBarButtonItem = nil
            }
        } else {
            if oldControlsVisible {
                UIView.animate(withDuration: 0.25) {
                    self.modeSegmentedControl.alpha = 0
                    self.recognizeButton.alpha = 0
                    self.focusView.hide()
                }
                if let moleculeNode = moleculeNode {
                    moleculeNode.isHidden = false
                    if mode == .object && !resultMolecules.isEmpty {
                        // Don't show this for now. I don't have time to implement this.
                        //selectObjectButton.isHidden = false
                    }

                    if mode == .structure {
                        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(showMenu))
                    }
                }
            }
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        updateQueue.async {
            if self.myAnchor == anchor {
                self.moleculeNode!.simdPosition = anchor.transform.translation
                //myObject!.anchor = anchor
                //print("anchor update")
            }
        }
    }


    // MARK: - ARSCNViewDelegate

    private func updateThings(moleculeInView: Bool) {
        /*
        if (moleculeInView) {
            recognizeButton.isHidden = true
            focusSquare.hide()
        } else {
            recognizeButton.isHidden = false
            focusSquare.unhide()
        }
         */

        let middlePoint = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)

        let camera = sceneView.session.currentFrame?.camera

        var localCameraOK = true
        var localCameraNotOKReason = ""

        if case .normal = camera?.trackingState, //let camera = sceneView.session.currentFrame?.camera, case .normal = camera.trackingState,
           let query = sceneView.raycastQuery(from: middlePoint, allowing: .estimatedPlane, alignment: .any),
           let result = sceneView.session.raycast(query).first {

//            updateQueue.async {
//                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
//                self.focusSquare.state = .detecting(raycastResult: result, camera: camera)
//            }

            self.lastPosition = result.worldTransform.translation


            //statusViewController.cancelScheduledMessage(for: .focusSquare)
        } else {
//            updateQueue.async {
//                self.focusSquare.state = .initializing
//                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
//            }


            if case .notAvailable = camera?.trackingState {
                localCameraOK = false
                localCameraNotOKReason = "Not available"
            } else if case .limited(let reason) = camera?.trackingState {
                localCameraOK = false
                switch reason {
                case .initializing:
                    localCameraNotOKReason = "Initializing..."
                case .relocalizing:
                    localCameraNotOKReason = "Relocalizing..."
                case .excessiveMotion:
                    localCameraNotOKReason = "Excessive motion"
                case .insufficientFeatures:
                    localCameraNotOKReason = "Insufficient features"
                @unknown default: break
                }
            } else if case .normal = camera?.trackingState {
                //text = "Too close/far"
            }

            //objectsViewController?.dismiss(animated: false, completion: nil)
        }


        if localCameraOK {
            if !cameraOK {
                cameraOK = true
                recognizeButton.isEnabled = true
                updateMessage()
            }
        } else {
            if cameraOK || localCameraNotOKReason != cameraNotOKReason {
                cameraOK = false
                cameraNotOKReason = localCameraNotOKReason
                recognizeButton.isEnabled = false
                updateMessage()
            }
        }


        if camera == nil {
            isInitializing = true
        } else if case .limited(let reason) = camera?.trackingState, case .initializing = reason {
            isInitializing = true
        } else if case .notAvailable = camera?.trackingState {
            isInitializing = true
        } else {
            isInitializing = false
        }
        updateViews()
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        /*
        let moleculeInView = moleculeNode != nil && sceneView.isNode(moleculeNode!, insideFrustumOf: sceneView.pointOfView!)
        */
        let moleculeInView = false

        DispatchQueue.main.async {
            self.updateThings(moleculeInView: moleculeInView)

            //self.updateFocusSquare(isObjectVisible: isAnyObjectInView)

            // If the object selection menu is open, update availability of items
            //if self.objectsViewController?.viewIfLoaded?.window != nil {
            //    self.objectsViewController?.updateObjectAvailability()
            //}
        }
    }

/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()

        return node
    }
*/


    func session(_ session: ARSession, didFailWithError error: Error) {
        if let arError = error as? ARError {
            switch arError.errorCode {
            case 103: // ARErrorCodeCameraUnauthorized
                cameraAccessLabel.isHidden = false
                cameraAccessButton.isHidden = false
                showsControls = false
                updateViews()
            default:
                break
            }
        }
    }

    @IBAction func openSettings() {
        UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
    }

    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay

    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required

    }

    // MARK: - Gesture Recognizer Delegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow objects to be translated and rotated at the same time.
        return true
    }

    // MARK: - Select Object

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }

    @IBAction func selectObject(sender: Any?) {

        let vc = MoleculeSelectionViewController()
        //vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .popover
        vc.molecules = resultMolecules
        vc.selectedMolecule = selectedMolecule
        vc.delegate = self

        if let popoverController = vc.popoverPresentationController, let button = sender as? UIButton {
            popoverController.delegate = self
            popoverController.sourceView = button
            popoverController.sourceRect = button.bounds
        }

        present(vc, animated: false, completion: nil)
    }

    func moleculeSelectionViewController(_: MoleculeSelectionViewController, didSelectMolecule molecule: String) {
        loadMolecule(molecule)
    }

    // MARK: - Mode

    @IBAction func modeChanged(_ sender: UISegmentedControl) {
        mode = (sender.selectedSegmentIndex == 0) ? .structure : .object
        clearMolecule()
        showMessage(nil)
        updateViews()
    }

    // MARK: - Help

    @objc private func showHelp(sender: Any?) {
        let vc = HelpViewController(mode: 1, firstTime: false)
        vc.title = "Help"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissHelp))

        let nav = UINavigationController(rootViewController: vc)
        //self.navigationController?.pushViewController(vc, animated: true)

        present(nav, animated: true, completion: nil)
    }

    @objc private func dismissHelp(sender: Any?) {
        dismiss(animated: true, completion: nil)
    }

    @objc private func showTips(sender: Any?) {
        if messageLabel.text != structureRecognitionFailMessage {
            return
        }
        let vc = HelpViewController(mode: 3, firstTime: false)
        vc.title = "Tips"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissHelp))

        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }

    @objc private func showMenu(sender: Any?) {
        let vc = MoleculeMenuViewController()
        vc.modalPresentationStyle = .popover
        vc.isPDB = false
        vc.molecularModelMode = molecularModelMode
        vc.molecularOrbitalMode = molecularOrbitalMode
        vc.showDipoleMoment = showDipoleMoment
        vc.delegate = self

        if let popoverController = vc.popoverPresentationController, let button = sender as? UIBarButtonItem {
            popoverController.delegate = self
            popoverController.barButtonItem = button
        }

        present(vc, animated: false, completion: nil)
    }

    func moleculeMenuViewController(_: MoleculeMenuViewController, didSelectMolecularModelMode mode: MolecularModelMode) {
        if molecularModelMode != mode {
            molecularModelMode = mode
            loadMolecule(selectedMolecule)
        }
    }

    func moleculeMenuViewController(_: MoleculeMenuViewController, didSelectMolecularOrbitalMode mode: MolecularOrbitalMode) {
        if molecularOrbitalMode != mode {
            molecularOrbitalMode = mode
            loadMolecule(selectedMolecule)
        }
    }

    func moleculeMenuViewController(_ menuViewController: MoleculeMenuViewController, didChangeShowDipoleMoment show: Bool) {
        if showDipoleMoment != show {
            showDipoleMoment = show
            loadMolecule(selectedMolecule)
        }
    }

    func moleculeMenuViewController(_ menuViewController: MoleculeMenuViewController, didSelectPolymerMode: PolymerMode) {
    }
}

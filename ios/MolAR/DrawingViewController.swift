//
//  DrawingViewController.swift
//  MolAR
//
//  Created by Sukolsak on 7/18/21.
//

import UIKit
import PencilKit
import QuickLook

class DrawingViewController: UIViewController, PKCanvasViewDelegate, QLPreviewControllerDataSource, UITextViewDelegate {
    @IBOutlet weak var canvasView: PKCanvasView!
    @IBOutlet weak var smilesTextView: UITextView!
    @IBOutlet weak var viewARButton: UIButton!
    private let thumbnailQueue = DispatchQueue(label: "ThumbnailQueue", qos: .background)
    private let lightTraitCollection = UITraitCollection(userInterfaceStyle: .light)
    private var drawId: Int = 0
    private var selectedURL: URL?
    private var clearButton: UIBarButtonItem!
    private var undoButton: UIBarButtonItem!

    private class UndoCacheItem {
        var drawId: Int
        var value: [String: Any]?

        init(drawId: Int, value: [String: Any]?) {
            self.drawId = drawId
            self.value = value
        }
    }

    private var undoCache = [UndoCacheItem?]()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.systemBackground

        clearButton = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain, target: self, action: #selector(clear))
        undoButton = UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.backward.circle"), style: .plain, target: self, action: #selector(undo))

        navigationItem.rightBarButtonItems = [clearButton, undoButton]

        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "questionmark.circle"), style: .plain, target: self, action: #selector(showHelp))

        //canvasView = PKCanvasView()
        canvasView.delegate = self
        /*
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(canvasView)
        NSLayoutConstraint.activate([
            canvasView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            canvasView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            canvasView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            canvasView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])
        */

        // Both finger and pencil are always allowed on this canvas.
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 1)
        canvasView.layer.cornerRadius = 8
        canvasView.layer.masksToBounds = true

        viewARButton.titleLabel?.font = UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .title3).pointSize, weight: .semibold)
        //viewARButton.titleLabel?.font = UIFontMetrics.default.scaledFont(for: UIFont.systemFont(ofSize: UIFont.preferredFont(forTextStyle: .title3).pointSize, weight: .regular))
        //viewARButton.titleLabel?.adjustsFontForContentSizeCategory = true
    }

    static private func getBolderDrawing(_ drawing: PKDrawing) -> PKDrawing {
        var newStrokes = [PKStroke]()
        let ink = PKInk(.pen, color: UIColor.black)
        let date = Date()
        for stroke in drawing.strokes {
            var newPoints = [PKStrokePoint]()
            stroke.path.forEach { (point) in
                let newPoint = PKStrokePoint(location: point.location,
                                             timeOffset: point.timeOffset,
                                             size: CGSize(width: 4, height: 4),
                                             opacity: 1, force: 1,
                                             azimuth: 0, altitude: 0)
                newPoints.append(newPoint)
            }
            let newPath = PKStrokePath(controlPoints: newPoints, creationDate: date)
            newStrokes.append(PKStroke(ink: ink, path: newPath))
         }
        return PKDrawing(strokes: newStrokes)
    }

    static private func transparentImageBackgroundToWhite(_ image: UIImage) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        let imageRect = CGRect(origin: .zero, size: image.size)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        ctx.fill(imageRect)
        image.draw(in: imageRect, blendMode: .normal, alpha: 1.0)
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }

    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        drawId += 1
        let localDrawId = drawId

        viewARButton.isEnabled = false

        let strokeCount = canvasView.drawing.strokes.count

        clearButton.isEnabled = strokeCount > 0
        undoButton.isEnabled = strokeCount > 0

        if strokeCount == 0 {
            smilesTextView.attributedText = nil
            smilesTextView.text = " "
            return
        }

        if strokeCount <= undoCache.count {
            if let item = undoCache[strokeCount - 1],
               let value = item.value {
                processResponse(value)
                return
            }
        } else {
            updateUndoCacheSize(strokeCount)
        }
        undoCache[strokeCount - 1] = UndoCacheItem(drawId: localDrawId, value: nil)

        smilesTextView.attributedText = nil
        smilesTextView.text = "Loading..."

        let bounds = canvasView.bounds
        let traitCollection = lightTraitCollection

        thumbnailQueue.async {
            traitCollection.performAsCurrent {
                let newDrawing = DrawingViewController.getBolderDrawing(canvasView.drawing)

                //let image = canvasView.drawing.image(from: bounds, scale: 256.0 / bounds.width)
                // Pad the drawing to make ChemPix work better.
                let w = bounds.width
                //let padding: CGFloat = 200
                let padding: CGFloat = 10 // use 10 with MathPix
                let image = newDrawing.image(from: CGRect(x: -padding, y: -padding, width: w + padding * 2, height: w + padding * 2), scale: 256.0 / (w + padding * 2))

                let imageData = DrawingViewController.transparentImageBackgroundToWhite(image).pngData()!


                let url = URL(string: serverAddress + "/api/molar_recognize_drawing")

                // generate boundary string using a unique per-app string
                let boundary = UUID().uuidString

                var urlRequest = URLRequest(url: url!)
                urlRequest.httpMethod = "POST"
                urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

                var data = Data()
                data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
                data.append("Content-Disposition: form-data; name=\"file\"; filename=\"a.png\"\r\n".data(using: .utf8)!)
                data.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
                data.append(imageData)
                data.append("\r\n--\(boundary)--".data(using: .utf8)!)

                let task = URLSession.shared.uploadTask(with: urlRequest, from: data) { responseData, response, error in

                    var success = false
                    var errorMessage = "Can't connect to the server"
                    if error == nil {
                        let jsonData = try? JSONSerialization.jsonObject(with: responseData!, options: .allowFragments)
                        if let topJSON = jsonData as? [String: Any] {
                            success = true
                            DispatchQueue.main.async {
                                if strokeCount <= self.undoCache.count,
                                   let item = self.undoCache[strokeCount - 1],
                                   item.drawId == localDrawId {
                                    item.value = topJSON
                                }

                                if localDrawId != self.drawId {
                                    return
                                }

                                self.processResponse(topJSON)
                            }
                        } else {
                            errorMessage = "Internal server error"
                        }
                    }
                    if !success {
                        DispatchQueue.main.async {
                            if localDrawId != self.drawId {
                                return
                            }
                            self.smilesTextView.attributedText = nil
                            self.smilesTextView.text = errorMessage
                            self.viewARButton.isEnabled = false
                        }
                    }
                }
                task.resume()
            }
        }
    }

    private func processResponse(_ topJSON: [String: Any]) {
        if let molecules = topJSON["molecules"] as? [String], molecules.count > 0 {
            let molecule = molecules[0]
            smilesTextView.attributedText = nil
            smilesTextView.text = molecule
            viewARButton.isEnabled = true
        } else {
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let normalFont = UIFont.systemFont(ofSize: 20.0) //UIFont.preferredFont(forTextStyle: .body)
            let normal = [
                NSAttributedString.Key.font: normalFont,
                NSAttributedString.Key.foregroundColor: UIColor.label,
                NSAttributedString.Key.paragraphStyle: paragraphStyle]
            let link: [NSAttributedString.Key : Any] = [
                NSAttributedString.Key.font: normalFont,
                //NSAttributedString.Key.foregroundColor: UIColor.link
                NSAttributedString.Key.link: ""
            ]

            let text = NSMutableAttributedString()
            text.append(NSAttributedString(string: "Can't recognize the structure. Please try again. ", attributes: normal))
            text.append(NSAttributedString(string: "Tap here for tips.", attributes: link))
            smilesTextView.attributedText = text
            viewARButton.isEnabled = false
        }
    }

    @objc private func undo() {
        updateUndoCacheSize(max(canvasView.drawing.strokes.count - 1, 0))
        canvasView.undoManager?.undo()
    }

    @objc private func clear() {
        updateUndoCacheSize(0)
        canvasView.drawing = PKDrawing()
    }

    // MARK: - Undo Cache

    private func updateUndoCacheSize(_ size: Int) {
        let curSize = undoCache.count
        if size < curSize {
            undoCache.removeSubrange(size ..< curSize)
        } else if size > curSize {
            for _ in curSize ..< size {
                undoCache.append(nil)
            }
        }
    }

    // MARK: - View AR

    @IBAction func viewAR() {
        getSDFFromSMILES(smilesTextView.text!) { sdf in
            guard let sdf = sdf else {
                // self.showMessage("An error has occured")
                return
            }

            let temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let savedURL = temporaryDirectoryURL.appendingPathComponent("tmp.usdz")
            let structure = parseSDF(sdf)
            let myobj = convertSDFStructureToMYOBJ(structure, molecularModelMode: .ballAndStick, molden: nil, molecularOrbitalMode: .none, dipoleMoment: nil, vibrations: nil)
            let usdz = convertMYOBJToUSDZ(myobj, defaultScale: 2.0)

            DispatchQueue.main.async {
                try! usdz.write(to: savedURL)
                self.selectedURL = savedURL

                let previewController = QLPreviewController()
                previewController.dataSource = self
                self.present(previewController, animated: true, completion: nil)
            }
        }
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let previewItem = selectedURL! as QLPreviewItem
        return previewItem
    }

    // MARK: - Help

    @objc private func showHelp(sender: Any?) {
        let vc = HelpViewController(mode: 0, firstTime: false)
        vc.title = "Help"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissHelp))

        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }

    @objc func dismissHelp(sender: Any?) {
        dismiss(animated: true, completion: nil)
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let vc = HelpViewController(mode: 2, firstTime: false)
        vc.title = "Tips"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissHelp))

        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
        return false
    }
}

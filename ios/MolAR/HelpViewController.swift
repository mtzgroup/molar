//
//  HelpViewController.swift
//  MolAR
//
//  Created by Sukolsak on 7/16/21.
//

import UIKit
import WebKit

class HelpViewController: UIViewController, WKNavigationDelegate, WKScriptMessageHandler {
    private var webView: WKWebView!
    private let mode: Int
    private let firstTime: Bool

    init(mode: Int, firstTime: Bool) {
        self.mode = mode
        self.firstTime = firstTime
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground

        //navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))

        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "iosListener")
        //config.defaultWebpagePreferences.allowsContentJavaScript = false

        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
        ])

        webView.backgroundColor = .clear
        //webView.scrollView.backgroundColor = .clear
        webView.isOpaque = false
        webView.navigationDelegate = self
        webView.allowsLinkPreview = false

        let content: String
        if mode == 0 {
            content = """
    <p>Draw a <b>chemical structure</b> to visualize the molecule with augmented reality.</p>
    <div><img src="draw.png"></div>
    <ul>
        <li>Please note that the results may not be accurate.</li>
    </ul>
"""
        } else if mode == 1 {
            content = """
                <p>Take a photo of a <b>chemical structure</b> or an <b>object</b> to visualize the molecule with augmented reality.</p>
                <div><img src="scan_structure.png"></div>
                <div class="caption">Structures</div>
                <div><img src="scan_object.png"></div>
                <div class="caption">Objects</div>
                <ul>
                    <li>The object recognition works best with food such as fruits.</li>
                    <li>Please note that the results may not be accurate.</li>
                </ul>
            """
        } else if mode == 2 {
            content = """
    <div><img src="draw.png"></div>
    <ul>
        <li>Try to make lines straight.</li>
    </ul>
"""
        } else {
            content = """
    <div><img src="scan_structure.png"></div>
    <ul>
        <li>Don't hold the phone too close to the structure.</li>
        <li>Use plain paper.</li>
        <li>Reduce shadows and background noise.</li>
    </ul>
"""
        }

        // https://noahgilmore.com/blog/dark-mode-uicolor-compatibility/
        webView.loadHTMLString("""
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no" />
  <style>
  :root {
    color-scheme: light dark;
    --link: #007aff;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --link: #0984ff;
    }
  }
  * {
    -webkit-touch-callout: none;
    -webkit-user-select: none;
  }
  body {
    font: -apple-system-body;
    -webkit-text-size-adjust: none;
    padding: 0px 10px;
  }
  h2 { font: -apple-system-title2 }
  img { max-width: 100% }
  button {
    padding: 8px;
    min-width: 150px;
    border-radius: 50px;
    border: none;
    font: -apple-system-title2;
    font-weight: 600;
    color: #ffffff;
    background-color: var(--link);
    margin-bottom: 20px;
  }
  .caption {
    text-align: center;
    margin-bottom: 20px;
  }
  </style>
</head>
<body>
""" +
content
+
"""
""" +
(firstTime ?
"""
    <center><button id="button">OK</button></center>
    <script>
document.getElementById('button').addEventListener('click', () => {
  window.webkit.messageHandlers.iosListener.postMessage('click');
});
    </script>
"""
: ""
) +
"""

</body>
</html>
""", baseURL: Bundle.main.bundleURL)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url)
                }
                decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    private func dismissHelp() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        var vc: UIViewController!
        if mode == 0 {
            vc = storyboard.instantiateViewController(withIdentifier: "drawingViewController")
            UserDefaults.standard.set(true, forKey: "seenHelpForDraw")
        } else {
            vc = storyboard.instantiateViewController(withIdentifier: "recognizeViewController")
            UserDefaults.standard.set(true, forKey: "seenHelpForScan")
        }
        vc.title = self.title
        self.navigationController?.viewControllers = [vc]
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        dismissHelp()
    }

//    @objc private func done() {
//        dismissHelp()
//    }
}

//
//  Molrender.swift
//  MolAR
//
//  Created by Sukolsak on 7/28/21.
//

import Foundation
import WebKit


class Molrender: NSObject, WKScriptMessageHandler {
    private var webView: WKWebView!
    private var completionHandler: ((Data?) -> Void)!

    func loadPDB(_ pdbId: String, completionHandler: @escaping (Data?) -> Void) {
        self.completionHandler = completionHandler

        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "iosListener")

        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 320, height: 320), configuration: config)
        webView.loadHTMLString("""
<!DOCTYPE html>
<html>
<body>
<script src="molrender.js"></script>
<script>
main('https://models.rcsb.org/
""" + pdbId + """
.bcif', 'usdz').catch((error) => {
  window.webkit.messageHandlers.iosListener.postMessage("error");
});
</script>
</body>
</html>
""", baseURL: Bundle.main.bundleURL)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.body as? [UInt8] == nil { // An error has occurred.
            completionHandler(nil)
            return
        }

        let bytes = message.body as! [UInt8]
        let d = Data(bytes)
        completionHandler(d)
    }
}

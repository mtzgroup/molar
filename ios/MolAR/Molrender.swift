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

    func loadPDB(_ pdbId: String, polymerMode: PolymerMode, completionHandler: @escaping (Data?) -> Void) {
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
(async () => {
  try {
    const response = await window.fetch('https://models.rcsb.org/
""" + pdbId + """
.bcif');
    const blob = await response.blob();
    const buffer = await blob.arrayBuffer();
    const data = new Uint8Array(buffer);
    window.main(data, x => {
      window.webkit.messageHandlers.iosListener.postMessage(Array.from(x));
    },
""" + (polymerMode == .cartoon ? "'cartoon'" : "'gaussianSurface'") + """
);
  } catch (e) {
    window.webkit.messageHandlers.iosListener.postMessage("error");
  }
})();

</script>
</body>
</html>
""", baseURL: Bundle.main.bundleURL)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        var d: Data? = nil
        if let body = message.body as? [UInt8] {
            d = Data(body)
        }
        completionHandler(d)
        userContentController.removeScriptMessageHandler(forName: "iosListener")
    }
}

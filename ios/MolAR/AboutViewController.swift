//
//  AboutViewController.swift
//  MolAR
//
//  Created by Sukolsak on 3/14/21.
//

import UIKit
import WebKit

class AboutViewController: UIViewController, WKNavigationDelegate {
    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground

        webView = WKWebView()
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
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
        webView.loadHTMLString("""
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, user-scalable=no" />
  <style>
  :root {
    color-scheme: light dark;
  }
  body {
    font: -apple-system-body;
    -webkit-text-size-adjust: none;
  }
  h2 { font: -apple-system-title2 }
  a { text-decoration: none; color: #007aff }
  td { text-align: center; color: black; min-width: 26px }
  </style>
</head>
<body>
    <h2>How to Use Augmented Reality</h2>

    <p>Tap the “View AR” button and point the camera to a flat surface with sufficient light. The molecule should then appear on the surface.</p>

    <h2>Color Scheme</h2>

    <p>We use the CPK coloring for atoms, as shown below.</p>

    <div style="overflow-x: scroll">
    <table cellpadding="3" cellspacing="0" id="periodicTable" class="mb-4">
      <tbody>
        <tr><td class="border-top border-start border-end">H</td><td colspan="16"></td><td>He</td></tr>
        <tr><td>Li</td><td>Be</td><td colspan="10"></td><td>B</td><td>C</td><td>N</td><td>O</td><td>F</td><td>Ne</td></tr>
        <tr><td>Na</td><td>Mg</td><td colspan="10"></td><td>Al</td><td>Si</td><td>P</td><td>S</td><td>Cl</td><td>Ar</td></tr>
        <tr><td>K</td><td>Ca</td><td>Sc</td><td>Ti</td><td>V</td><td>Cr</td><td>Mn</td><td>Fe</td><td>Co</td><td>Ni</td><td>Cu</td><td>Zn</td><td>Ga</td><td>Ge</td><td>As</td><td>Se</td><td>Br</td><td>Kr</td></tr>
        <tr><td>Rb</td><td>Sr</td><td>Y</td><td>Zr</td><td>Nb</td><td>Mo</td><td>Tc</td><td>Ru</td><td>Rh</td><td>Pd</td><td>Ag</td><td>Cd</td><td>In</td><td>Sn</td><td>Sb</td><td>Te</td><td>I</td><td>Xe</td></tr>
        <tr><td>Cs</td><td>Ba</td><td></td><td>Hf</td><td>Ta</td><td>W</td><td>Re</td><td>Os</td><td>Ir</td><td>Pt</td><td>Au</td><td>Hg</td><td>Tl</td><td>Pb</td><td>Bi</td><td>Po</td><td>At</td><td>Rn</td></tr>
        <tr><td>Fr</td><td>Ra</td><td></td><td>Rf</td><td>Db</td><td>Sg</td><td>Bh</td><td>Hs</td><td>Mt</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>
        <tr><td colspan="18">&nbsp;</td></tr>
        <tr><td></td><td></td><td>La</td><td>Ce</td><td>Pr</td><td>Nd</td><td>Pm</td><td>Sm</td><td>Eu</td><td>Gd</td><td>Tb</td><td>Dy</td><td>Ho</td><td>Er</td><td>Tm</td><td>Yb</td><td>Lu</td><td></td></tr>
        <tr><td></td><td></td><td>Ac</td><td>Th</td><td>Pa</td><td>U</td> <td>Np</td><td>Pu</td><td>Am</td><td>Cm</td><td>Bk</td><td>Cf</td><td>Es</td><td>Fm</td><td>Md</td><td>No</td><td>Lr</td><td></td></tr>
      </tbody>
    </table>
    </div>

    <h2>About Us</h2>

    <p>This app is created by the Martinez Group at Stanford University. If you have any feedback or suggestions, please contact us at sukolsak@gmail.com.</p>
    <p>The data in this app are from the Protein Data Bank, NCI/CADD, PubChem, and ChEBI. Proteins and macromolecules are rendered using Mol*.</p>
    <p>When using MolAR in research, please cite Sukolsak Sakshuwong, Hayley Weir, Umberto Raucci, and Todd J. Martínez, "<a href="https://aip.scitation.org/doi/10.1063/5.0090482">Bringing chemical structures to life with augmented reality, machine learning, and quantum chemistry</a>", Journal of Chemical Physics. 156, 204801 (2022).</p>

  <script>
  const elements = [
    ["H", "FFFFFF"],
    ["He", "D9FFFF"],
    ["Li", "CC80FF"],
    ["Be", "C2FF00"],
    ["B", "FFB5B5"],
    ["C", "909090"],
    ["N", "3050F8"],
    ["O", "FF0D0D"],
    ["F", "90E050"],
    ["Ne", "B3E3F5"],
    ["Na", "AB5CF2"],
    ["Mg", "8AFF00"],
    ["Al", "BFA6A6"],
    ["Si", "F0C8A0"],
    ["P", "FF8000"],
    ["S", "FFFF30"],
    ["Cl", "1FF01F"],
    ["Ar", "80D1E3"],
    ["K", "8F40D4"],
    ["Ca", "3DFF00"],
    ["Sc", "E6E6E6"],
    ["Ti", "BFC2C7"],
    ["V", "A6A6AB"],
    ["Cr", "8A99C7"],
    ["Mn", "9C7AC7"],
    ["Fe", "E06633"],
    ["Co", "F090A0"],
    ["Ni", "50D050"],
    ["Cu", "C88033"],
    ["Zn", "7D80B0"],
    ["Ga", "C28F8F"],
    ["Ge", "668F8F"],
    ["As", "BD80E3"],
    ["Se", "FFA100"],
    ["Br", "A62929"],
    ["Kr", "5CB8D1"],
    ["Rb", "702EB0"],
    ["Sr", "00FF00"],
    ["Y", "94FFFF"],
    ["Zr", "94E0E0"],
    ["Nb", "73C2C9"],
    ["Mo", "54B5B5"],
    ["Tc", "3B9E9E"],
    ["Ru", "248F8F"],
    ["Rh", "0A7D8C"],
    ["Pd", "006985"],
    ["Ag", "C0C0C0"],
    ["Cd", "FFD98F"],
    ["In", "A67573"],
    ["Sn", "668080"],
    ["Sb", "9E63B5"],
    ["Te", "D47A00"],
    ["I", "940094"],
    ["Xe", "429EB0"],
    ["Cs", "57178F"],
    ["Ba", "00C900"],
    ["La", "70D4FF"],
    ["Ce", "FFFFC7"],
    ["Pr", "D9FFC7"],
    ["Nd", "C7FFC7"],
    ["Pm", "A3FFC7"],
    ["Sm", "8FFFC7"],
    ["Eu", "61FFC7"],
    ["Gd", "45FFC7"],
    ["Tb", "30FFC7"],
    ["Dy", "1FFFC7"],
    ["Ho", "00FF9C"],
    ["Er", "00E675"],
    ["Tm", "00D452"],
    ["Yb", "00BF38"],
    ["Lu", "00AB24"],
    ["Hf", "4DC2FF"],
    ["Ta", "4DA6FF"],
    ["W", "2194D6"],
    ["Re", "267DAB"],
    ["Os", "266696"],
    ["Ir", "175487"],
    ["Pt", "D0D0E0"],
    ["Au", "FFD123"],
    ["Hg", "B8B8D0"],
    ["Tl", "A6544D"],
    ["Pb", "575961"],
    ["Bi", "9E4FB5"],
    ["Po", "AB5C00"],
    ["At", "754F45"],
    ["Rn", "428296"],
    ["Fr", "420066"],
    ["Ra", "007D00"],
    ["Ac", "70ABFA"],
    ["Th", "00BAFF"],
    ["Pa", "00A1FF"],
    ["U", "008FFF"],
    ["Np", "0080FF"],
    ["Pu", "006BFF"],
    ["Am", "545CF2"],
    ["Cm", "785CE3"],
    ["Bk", "8A4FE3"],
    ["Cf", "A136D4"],
    ["Es", "B31FD4"],
    ["Fm", "B31FBA"],
    ["Md", "B30DA6"],
    ["No", "BD0D87"],
    ["Lr", "C70066"],
    ["Rf", "CC0059"],
    ["Db", "D1004F"],
    ["Sg", "D90045"],
    ["Bh", "E00038"],
    ["Hs", "E6002E"],
    ["Mt", "EB0026"]
  ];
  const periodicTable = document.getElementById("periodicTable");
  for (const row of periodicTable.rows) {
    for (const cell of row.cells) {
      for (const element of elements) {
        if (cell.textContent == element[0]) {
          cell.style.backgroundColor = "#" + element[1];
          break;
        }
      }
    }
  }
  </script>
</body>
</html>
""", baseURL: nil)
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
}

//
//  ViewController.swift
//  MolAR
//
//  Created by Sukolsak on 3/10/21.
//

import UIKit

class ViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let gallery = GalleryViewController()
        gallery.title = "Browse"

        let galleryNav = UINavigationController(rootViewController: gallery)
        galleryNav.title = "Browse"
        galleryNav.tabBarItem.image = UIImage(systemName: "list.bullet")

        let seenHelpForDraw = UserDefaults.standard.bool(forKey: "seenHelpForDraw")
        let seenHelpForScan = UserDefaults.standard.bool(forKey: "seenHelpForScan")

        let draw = seenHelpForDraw ? storyboard.instantiateViewController(withIdentifier: "drawingViewController") : HelpViewController(mode: 0, firstTime: true)
        draw.title = "Draw"

        let drawNav = UINavigationController(rootViewController: draw)
        drawNav.title = "Draw"
        drawNav.tabBarItem.image = UIImage(systemName: "hand.draw")

        let recognize = seenHelpForScan ? storyboard.instantiateViewController(withIdentifier: "recognizeViewController") : HelpViewController(mode: 1, firstTime: true)
        recognize.title = "Recognize"

        let recognizeNav = UINavigationController(rootViewController: recognize)
        recognizeNav.title = "Recognize"
        recognizeNav.tabBarItem.image = UIImage(systemName: "viewfinder")

        self.viewControllers = [galleryNav, drawNav, recognizeNav]
    }
}

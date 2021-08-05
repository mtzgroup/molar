//
//  FocusView.swift
//  MolAR
//
//  Created by Sukolsak on 5/30/21.
//

import UIKit

class FocusView: UIView {
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(UIColor(white: 0, alpha: 0.5).cgColor)
        context.fill(bounds)

        let w = bounds.width
        let h = bounds.height
        let k = min(min(w - 60, h - 220), 500)
        let focusRect = CGRect(x: (w-k)/2, y: (h-k)/2, width: k, height: k)
        context.clear(focusRect)

        context.setLineWidth(2.0)
        context.setStrokeColor(UIColor.yellow.cgColor)
        context.stroke(focusRect)

        /*
        context.setFillColor(UIColor.yellow.cgColor)
        let xs: [CGFloat] = [(w-k)/2, (w+k)/2]
        let ys: [CGFloat] = [(h-k)/2, (h+k)/2]
        let sl: CGFloat = 50.0 // long
        let ss: CGFloat = 4.0 // short
        for i in 0..<2 {
            for j in 0..<2 {
                context.fill(CGRect(x: xs[i] - (i == 0 ? ss/2 : sl-ss/2), y: ys[j] - ss/2, width: sl, height: ss))
                context.fill(CGRect(x: xs[i] - ss/2, y: ys[j] - (j == 0 ? ss/2 : sl-ss/2), width: ss, height: sl))
            }
        }
        */
    }

    func hide() {
        alpha = 0
    }

    func unhide() {
        alpha = 1
    }
}

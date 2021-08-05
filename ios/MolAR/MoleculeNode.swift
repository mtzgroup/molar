//
//  MoleculeNode.swift
//  MolAR
//
//  Created by Sukolsak on 2/17/21.
//

import Foundation
import ARKit

class MoleculeNode: SCNNode {
    private let loadingNode = SCNNode()
    private var mainNode: SCNNode?

    override init() {
        super.init()

        /*
        let plane = SCNPlane(width: 0.1, height: 0.1)
        let material = plane.firstMaterial!
        material.diffuse.contents = #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)
        material.isDoubleSided = true
        material.ambient.contents = UIColor.black
        material.lightingModel = .constant
        material.emission.contents = #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)
        loadingNode.geometry = plane
         */

        let sphere = SCNSphere(radius: 0.05)
        sphere.segmentCount = 8
        let material = sphere.firstMaterial!
        material.fillMode = .lines
        material.diffuse.contents = #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)
        material.isDoubleSided = true
        material.ambient.contents = UIColor.black
        material.lightingModel = .constant
        material.emission.contents = #colorLiteral(red: 1, green: 0.8, blue: 0, alpha: 1)
        loadingNode.geometry = sphere
        loadingNode.runAction(rotateAction(), forKey: "pulse")

        addChildNode(loadingNode)
    }

    func setMainNode(_ node: SCNNode?) {
        if let currentMainNode = mainNode {
            currentMainNode.removeFromParentNode()
        }
        mainNode = node

        if let newMainNode = node {
            addChildNode(newMainNode)
            //self.moleculeNode!.hideLoading()

            SCNTransaction.begin()
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
            SCNTransaction.animationDuration = 0.25
            newMainNode.simdScale = simd_float3(0.008, 0.008, 0.008)
            SCNTransaction.commit()
        }
    }

    private func rotateAction() -> SCNAction {
        let action = SCNAction.rotate(by: .pi * 2, around: SCNVector3(0, 1, 0), duration: 6)
        return SCNAction.repeatForever(action)
        //return SCNAction.repeatForever(SCNAction.sequence([pulseOutAction, pulseInAction]))
    }

    func hideLoading() {
        loadingNode.removeFromParentNode()
    }

    func showLoading() {
        addChildNode(loadingNode)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


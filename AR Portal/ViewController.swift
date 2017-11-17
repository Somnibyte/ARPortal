//
//  ViewController.swift
//  AR Portal
//
//  Created by Guled on 11/4/17.
//  Copyright © 2017 Somnibyte. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var planeDetectionLabel: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    
    // MARK: - Constants
    
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
        
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        sceneView.delegate = self
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(sceneViewTapped))
        
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func sceneViewTapped(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else { return }
        
        let touchLocation = sender.location(in: sceneView)
        
        let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        
        if !hitTestResult.isEmpty {
            addPortal(hitTestResult: hitTestResult.first!)
        }
    }
    
    func addPortal(hitTestResult: ARHitTestResult) {
        guard
            let portalScene = SCNScene(named: "Portal.scnassets/Portal.scn"),
            let portalNode = portalScene.rootNode.childNode(withName: "Portal", recursively: false)
            else { return }
    
        let transform = hitTestResult.worldTransform
        let planeXposition = transform.columns.3.x
        let planeYposition = transform.columns.3.y
        let planeZposition = transform.columns.3.z
        
        portalNode.position =  SCNVector3(planeXposition, planeYposition, planeZposition)
        
        self.sceneView.scene.rootNode.addChildNode(portalNode)
        
        addImageToPlane(nodeName: "roof", node: portalNode, imageName: "side1")
        addImageToPlane(nodeName: "floor", node: portalNode, imageName: "side4")
        addImageToPlane(nodeName: "backWall", node: portalNode, imageName: "side6")
        addImageToPlane(nodeName: "rightSideWall", node: portalNode, imageName: "side2")
        addImageToPlane(nodeName: "leftSideWall", node: portalNode, imageName: "side5")
        addImageToPlane(nodeName: "rightFrontDoorWall", node: portalNode, imageName: "side3")
        addImageToPlane(nodeName: "leftFrontDoorWall", node: portalNode, imageName: "side3")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        DispatchQueue.main.async {
            self.planeDetectionLabel.isHidden = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.planeDetectionLabel.isHidden = true
        }
    }
    
    func addImageToPlane(nodeName: String, node: SCNNode, imageName: String) {
        let plane = node.childNode(withName: nodeName, recursively: true)
        
        plane?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "\(imageName).png")
        
        plane?.renderingOrder = 200
       
        if let mask = plane?.childNode(withName: "mask", recursively: false) {
            mask.geometry?.firstMaterial?.transparency = 0.000001
        }
    }
}


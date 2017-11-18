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
        // Here we tell the sceneView to detect horizontal surfaces
        configuration.planeDetection = .horizontal
        
        // We run our configuration on the scene.
        sceneView.session.run(configuration)
        
        // When debugging our app we would like the see what features our device has noticed in its
        // environment so we use the 'showFeaturePoints' debug option. The showWorldOrigin option
        // shows the origin of our sceneView.
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        
        // Here we conform to the ARSCNViewDelegate to use the `renderer` method below.
        sceneView.delegate = self
        
        // Here we add a tap gesture recognizer so that when we tap on the screen we can add a portal
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(sceneViewTapped))
        
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func sceneViewTapped(sender: UITapGestureRecognizer) {
        // We define the scene that the user tapped on.
        guard let sceneView = sender.view as? ARSCNView else { return }
        
        // We get the location of where the user tapped on in the screen.
        let touchLocation = sender.location(in: sceneView)
        
        // We check what exactly the user tapped on. Here we are making sure what they tapped on
        // was a plane.
        let hitTestResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
        
        // Here we make sure that the object they tapped on actually exists.
        if !hitTestResult.isEmpty {
            // We then call the addPortal method, passing in the hitTestResult.
            // The hitTestResult comes with information such as the location of the plane the
            // user tapped on.
            addPortal(hitTestResult: hitTestResult.first!)
        }
    }
    
    func addPortal(hitTestResult: ARHitTestResult) {
        guard
            // Here we save our portal scene.
            let portalScene = SCNScene(named: "Portal.scnassets/Portal.scn"),
            // Then we save the 'Portal' node within that scene file.
            let portalNode = portalScene.rootNode.childNode(withName: "Portal", recursively: false)
            else { return }
        
        // Down below we grab the location information of the plane the user tapped on
        // from the hitTestResult parameter.
        let transform = hitTestResult.worldTransform
        let planeXposition = transform.columns.3.x
        let planeYposition = transform.columns.3.y
        let planeZposition = transform.columns.3.z
        
        // We then position the portal where the plane (hitTestResult plane location) was located at.
        portalNode.position =  SCNVector3(planeXposition, planeYposition, planeZposition)
        
        // We then add the portal to our scene.
        self.sceneView.scene.rootNode.addChildNode(portalNode)
        
        // We call the addImageToPlane method to add images to the planes (walls)
        // of our portal.
        addImageToPlane(nodeName: "roof", node: portalNode, imageName: "side1")
        addImageToPlane(nodeName: "floor", node: portalNode, imageName: "side4")
        addImageToPlane(nodeName: "backWall", node: portalNode, imageName: "side6")
        addImageToPlane(nodeName: "rightSideWall", node: portalNode, imageName: "side2")
        addImageToPlane(nodeName: "leftSideWall", node: portalNode, imageName: "side5")
        addImageToPlane(nodeName: "rightFrontDoorWall", node: portalNode, imageName: "side3")
        addImageToPlane(nodeName: "leftFrontDoorWall", node: portalNode, imageName: "side3")
    }
    
    // The renderer method adds what are called 'anchors' within our scene. Anchors encode
    // information such as the orientation, position, and size of an object in the real world.
    // For example, when the iPhone recognizes the floor it will place an "anchor" to represent that floor.
    // The anchor that will be added (when the floor is detected) would be a plane since the floor would
    // be considered as a plane.
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // We make sure that the anchor is a plane...
        guard anchor is ARPlaneAnchor else { return }
        
        // Then we display our label from our viewcontroller and keep it on the screen for 3 seconds.
        DispatchQueue.main.async {
            self.planeDetectionLabel.isHidden = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.planeDetectionLabel.isHidden = true
        }
    }
    
    func addImageToPlane(nodeName: String, node: SCNNode, imageName: String) {
        // Here we are looking for a specific subNode within our original portalNode from
        // the addPortal method guard statement.
        // The Portal node from the Portal.scn file contains subNodes, those subNodes come with
        // names so it's important that the nodeName parameter should have the correct subNode
        // name you are looking for such as "redCarpet" or "roof".
        let plane = node.childNode(withName: nodeName, recursively: true)
        
        // Next we apply the desired image.
        plane?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "\(imageName).png")
        
        // We set the rendering order of the original walls (ex: rightSideWall (see Portal.scn file))
        // to be really high. If a node has a higher rendering order then it will be rendered later than
        // other nodes with lower rendering orders. By default every node has a rendering order of 0.
        
        // Here's what we are trying to accomplish. We are trying to make the walls (ex: rightSideWall, leftSideWall... (see Portal.scn file)) invisible.
        // Notice that those nodes in the Portal.scn file have subNodes of their own called "mask"
        // The plan is to make the masks transparent (see line: 139) and have the masks render BEFORE it's parent node.
        // What this does is make the transparency of the mask blend with the opaque surface of the it's parent node.
        // This is what makes the parents nodes transparent as well which creates the illusion of the invisible walls on the outside
        // of your portal.
        plane?.renderingOrder = 50
       
        if let mask = plane?.childNode(withName: "mask", recursively: false) {
            // Why do you set the transparency to be 0.1?
            // Good question. If the mask is completely invisible then the walls will be visible.
            // Here's an analogy. If you use Photoshop (or any image editing software for that matter)
            // And apply a mask to a layer with 0.0 opacity, was it really worth placing a mask on your layer if it's
            // basically non-existant?
            mask.geometry?.firstMaterial?.transparency = 0.1
        }
    }
}


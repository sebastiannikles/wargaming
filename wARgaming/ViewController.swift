//
//  ViewController.swift
//  wARgaming
//
//  Created by Sebastian Nikles on 03.01.19.
//  Copyright © 2019 Sebastian Nikles. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var character: Character?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "SceneKit.scnassets/GameScene.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Object Detection
        configuration.detectionObjects = ARReferenceObject.referenceObjects(inGroupNamed: "Figure", bundle: Bundle.main)!
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first as! UITouch
        if(touch.view == self.sceneView) {
            let viewTouchLocation:CGPoint = touch.location(in: sceneView)
            guard let result = sceneView.hitTest(viewTouchLocation, options: nil).first else {
                character?.hideMoveRadius()
                return
            }
            
            var n:SCNNode? = result.node

            while n != character && n != nil {
                n = n?.parent
            }

            if n == character {
                character?.showMoveRadius()
            } else {
                character?.hideMoveRadius()
            }
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // TEMPORARY FIX FOR ADDITIONAL NODES
        sceneView.scene.rootNode.childNodes.last!.removeFromParentNode()
        sceneView.scene.rootNode.childNodes.last!.removeFromParentNode()
        
        character = Character.create(from: anchor as? ARObjectAnchor)
        return character
    }
}

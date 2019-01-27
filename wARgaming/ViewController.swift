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
    
    @IBOutlet weak var phaseViewTop: NSLayoutConstraint!
    @IBOutlet weak var phaseLabel: UILabel!
    @IBOutlet weak var phaseView: UIVisualEffectView!
    @IBOutlet weak var playerView: UIVisualEffectView!
    @IBOutlet weak var playerLabel: UILabel!
    @IBOutlet weak var hintViewTop: NSLayoutConstraint!
    @IBOutlet weak var hintView: UIVisualEffectView!
    @IBOutlet weak var hintLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    
    // MARK: - Phase declaration
    
    var firstCharacter: Character?
    var secondCharacter: Character?
    
    var currentPlayer: Int! {
        didSet {
            updatePlayerText()
        }
    }
    
    func isPlayer1() -> Bool { return currentPlayer == 0 }
    func isPlayer2() -> Bool { return currentPlayer != 0 }
    func getCurrentPlayerString() -> String { return isPlayer1() ? "P1" : "P2" }
    
    var currentPhase: TurnPhase! {
        didSet {
            updatePhaseText()
        }
    }
    
    enum TurnPhase {
        case Selection
        case Movement
        case Attack
    }
    
    // MARK: - Session Set up
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = SCNDebugOptions.showBoundingBoxes
        
        // Create a new scene
        let scene = SCNScene(named: "SceneKit.scnassets/GameScene.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        setUpHintView()
        setUpPhaseView()
        setUpPlayerView()
        
        currentPlayer = 0
        changePhase(to: .Selection, animated: false)
        updateHint(animated: false)
    }
    
    func setUpHintView() {
        hintView.layer.cornerRadius = 6
        hintView.layer.borderWidth = 1
        hintView.layer.borderColor = hintLabel.textColor.cgColor
        hintView.clipsToBounds = true
    }
    
    func setUpPhaseView() {
        phaseView.layer.cornerRadius = 6
        phaseView.layer.borderWidth = 1
        phaseView.layer.borderColor = hintLabel.textColor.cgColor
        phaseView.clipsToBounds = true
    }
    
    func setUpPlayerView() {
        playerView.layer.cornerRadius = playerView.frame.width / 2
        playerView.layer.borderWidth = 1
        playerView.layer.borderColor = hintLabel.textColor.cgColor
        playerView.clipsToBounds = true
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

    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard currentPhase != .Selection else { return }
        
        let touch = touches.first as! UITouch
        if(touch.view == self.sceneView) {
            let viewTouchLocation:CGPoint = touch.location(in: sceneView)
            guard let result = sceneView.hitTest(viewTouchLocation, options: nil).first else {
                hideMoveRadius()
                return
            }
            
            var char: Character?
            if isCharacter(node: result.node, char: &char) {
                showMoveRadius(at: char)
            } else {
                hideMoveRadius()
            }
        }
    }
    
    func isCharacter(node: SCNNode?, char: inout Character?) -> Bool {
        var node = node
        while !(node is Character) && node != nil {
            node = node?.parent
        }
        
        if node is Character {
            char = node as? Character
            return true
        }
        
        return false
    }
    
    // MARK: - ARSCNViewDelegate
    
    var shouldRemoveFirstNodes = true
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard currentPhase == .Selection else { return nil }
        
        if (shouldRemoveFirstNodes) {
            // TEMPORARY FIX FOR ADDITIONAL NODES
            sceneView.scene.rootNode.childNodes.last!.removeFromParentNode()
            sceneView.scene.rootNode.childNodes.last!.removeFromParentNode()
            
            shouldRemoveFirstNodes = false
        }
        
        if firstCharacter == nil {
            firstCharacter = Character.create(from: anchor as? ARObjectAnchor)
            currentPlayer = 1
            updateHint()
            
            addMovmentRadius()
            
            return firstCharacter
        }
        
        if secondCharacter == nil {
            secondCharacter = Character.create(from: anchor as? ARObjectAnchor)
            
            currentPlayer = 0
            changePhase(to: .Movement)
            
            return secondCharacter
        }
        
        return nil
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        if currentPhase == .Movement && node == currentMovedNode {
            checkMovementRadius()
        }
    }
    
    // MARK: - Radius handling
    
    var movementNode: SCNNode!
    var currentMovementRadius: Double = 0.0
    var currentMovedNode: SCNNode?
    
    var isInRange = true
    let defaultCircleColor = UIColor(red: 0.83, green: 0.83, blue: 0.83, alpha: 0.3)
    let outOfRangeCircleColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.3)
    
    func addMovmentRadius() {
        let circle = SCNCylinder(radius: 0.0, height: 0.001)
        circle.firstMaterial?.diffuse.contents = defaultCircleColor
        
        movementNode = SCNNode(geometry: circle)
        movementNode.position = SCNVector3Zero
        
        sceneView.scene.rootNode.addChildNode(movementNode)
    }
    
    func showMoveRadius(at character: Character?) {
        guard let character = character else { return }
        
        movementNode.position = character.position
        currentMovementRadius = character.movementRadius
        currentMovedNode = character
        isInRange = true
        
        let animation = CABasicAnimation(keyPath: "geometry.radius")
        animation.fromValue = 0.0
        animation.toValue = character.movementRadius
        animation.duration = 0.35
        animation.autoreverses = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        movementNode.addAnimation(animation, forKey: "radius")
    }
    
    func hideMoveRadius() {
        let animation = CABasicAnimation(keyPath: "geometry.radius")
        animation.fromValue = currentMovementRadius
        animation.toValue = 0.0
        animation.duration = 0.35
        animation.autoreverses = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        movementNode.addAnimation(animation, forKey: "radius")
        
        currentMovementRadius = 0.0
        currentMovedNode = nil
    }
    
    func checkMovementRadius() {
        guard let movedNode = currentMovedNode else { return }
        
        print("check radius")
        
        let x1 = movementNode.position.x
        let z1 = movementNode.position.z
        let x2 = movedNode.position.x
        let z2 = movedNode.position.z
        
        let distance = sqrtf(powf(x2-x1, 2) + powf(z2-z1, 2))
        
        if (isInRange && distance <= Float(currentMovementRadius)) || (!isInRange && distance > Float(currentMovementRadius)) {
            return
        }
        
        isInRange = !isInRange
        UIView.animate(withDuration: 0.35, animations: {
            self.movementNode.geometry?.firstMaterial?.diffuse.contents = self.isInRange
                ? self.defaultCircleColor
                : self.outOfRangeCircleColor
        })
    }
    
    // MARK: - Game Info Helpers
    
    func changePhase(to phase: TurnPhase, animated: Bool = true) {
        guard animated else {
            currentPhase = phase
            return
        }
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.7, animations: {
                self.hintViewTop.constant = -self.phaseView.frame.height
                self.hintView.alpha = 0.0
                self.phaseView.alpha = 0.0
                self.view.layoutIfNeeded()
            }, completion: {finished in
                self.currentPhase = phase
                self.updateHint(animated: false)
                UIView.animate(withDuration: 0.7, animations: {
                    self.hintView.alpha = 1.0
                    self.phaseView.alpha = 1.0
                    self.hintViewTop.constant = 16
                    self.view.layoutIfNeeded()
                })
            })
        }
    }
    
    func updateHint(animated: Bool = true) {
        guard animated else {
            updateHintText()
            return
        }
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.7, animations: {
                self.hintViewTop.constant = -self.phaseView.frame.height
                self.hintView.alpha = 0.0
                self.view.layoutIfNeeded()
            }, completion: {finished in
                self.updateHintText()
                UIView.animate(withDuration: 0.7, animations: {
                    self.hintView.alpha = 1.0
                    self.hintViewTop.constant = 16
                    self.view.layoutIfNeeded()
                })
            })
        }
    }
    
    func updateHintText() {
        var hint: String!
        
        if currentPhase == .Selection {
            hint = "Choose your character by looking at it"
        } else if currentPhase == .Movement {
            hint = "Whoops"
        }
        
        DispatchQueue.main.async {
            self.hintLabel.text = hint
        }
    }
    
    func updatePhaseText() {
        var phase: String!
        
        if currentPhase == .Selection {
            phase = "Selection"
        } else if currentPhase == .Movement {
            phase = "Movement"
        }
        
        DispatchQueue.main.async {
            self.phaseLabel.text = phase
        }
    }
    
    func updatePlayerText() {
        DispatchQueue.main.async {
            self.playerLabel.text = self.getCurrentPlayerString()
        }
    }
}

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
    
    // The corresponding IBOutlets to the views used in Main.storyboard
    @IBOutlet weak var victoryView: UIVisualEffectView!
    @IBOutlet weak var victoryLabel: UILabel!
    
    @IBOutlet weak var changePhaseView: UIVisualEffectView!
    @IBOutlet weak var changePhaseButton: UIButton!
    @IBOutlet weak var phaseViewTop: NSLayoutConstraint!
    @IBOutlet weak var phaseLabel: UILabel!
    @IBOutlet weak var phaseView: UIVisualEffectView!
    @IBOutlet weak var playerView: UIVisualEffectView!
    @IBOutlet weak var playerLabel: UILabel!
    @IBOutlet weak var hintViewTop: NSLayoutConstraint!
    @IBOutlet weak var hintView: UIVisualEffectView!
    @IBOutlet weak var hintLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var attackView: AttackView!
    @IBOutlet weak var attackViewHeight: NSLayoutConstraint!
    
    // MARK: - Phase declaration
    
    // The players are represented through their models (only one model per player)
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
    
    // The three possible phases a turn can be in
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
        // Show the bounding boxes of virtual nodes
        sceneView.debugOptions = SCNDebugOptions.showBoundingBoxes
        
        // Create a new scene
        let scene = SCNScene(named: "SceneKit.scnassets/GameScene.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Set up the different UI elements in the view
        setUpHintView()
        setUpPhaseView()
        setUpChangePhaseView()
        setUpPlayerView()
        setUpAttackView()
        
        // Reset the game
        currentPlayer = 0
        changePhase(to: .Selection, animated: false)
        updateHint(animated: false)
    }
    
    // Update the appearance of the hint view
    func setUpHintView() {
        hintView.layer.cornerRadius = 6
        hintView.layer.borderWidth = 1
        hintView.layer.borderColor = hintLabel.textColor.cgColor
        hintView.clipsToBounds = true
    }
    
    // Update the appearance of the phase view
    func setUpPhaseView() {
        phaseView.layer.cornerRadius = 6
        phaseView.layer.borderWidth = 1
        phaseView.layer.borderColor = hintLabel.textColor.cgColor
        phaseView.clipsToBounds = true
    }
    
    // Update the appearance of the change phase view
    func setUpChangePhaseView() {
        changePhaseView.layer.cornerRadius = changePhaseView.frame.width / 2
        changePhaseView.layer.borderWidth = 1
        changePhaseView.layer.borderColor = hintLabel.textColor.cgColor
        changePhaseView.clipsToBounds = true
        
        changePhaseView.alpha = 0.0
    }
    
    // Update the appearance of the player view
    func setUpPlayerView() {
        playerView.layer.cornerRadius = playerView.frame.width / 2
        playerView.layer.borderWidth = 1
        playerView.layer.borderColor = hintLabel.textColor.cgColor
        playerView.clipsToBounds = true
    }
    
    // Update the appearance of the attack view
    func setUpAttackView() {
        attackView.clipsToBounds = true
        attackView.layer.cornerRadius = 12
        attackView.layer.maskedCorners = [.layerMinXMinYCorner,.layerMaxXMinYCorner]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Pass the object scans to the session for object detection
        configuration.detectionObjects = ARReferenceObject.referenceObjects(inGroupNamed: "Figure", bundle: Bundle.main)!
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - Attack handling
    
    // References to the two characters partaking in an attack
    var attackTarget: Character?
    var attackingNode: Character?
    
    func showAttackView() {
        guard let attacker = attackingNode, let defender = attackTarget else { return }
        
        // Delegates executing the attack to the attack view
        attackView.setUp(attacker, defender, completion: {
            DispatchQueue.main.async {
                // Hides the attack view after the attack is finished
                UIView.animate(withDuration: 0.35, animations: {
                    self.attackViewHeight.constant = 0
                    self.view.layoutIfNeeded()
                }, completion: {finished in
                    // Resets the attack view
                    self.attackView.phase = .HitRoll
                    
                    // If the attacked character's lost all of its lives, the game ends
                    // Otherwise the next turn begins
                    if defender.wounds <= 0 {
                        self.hideHint()
                        self.hidePhase()
                        self.hideChangePhase()
                        
                        self.showVictoryView()
                    } else {
                        self.canSwitchPhase = true
                        self.changePhase(self)
                    }
                })
            }
        })
        
        // Shows the attack view
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.35, animations: {
                self.attackViewHeight.constant = 300
                self.view.layoutIfNeeded()
            })
        }
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Ignore touches in the character selection phase
        guard currentPhase != .Selection else { return }
        
        // Ignore touches if there is a character to move already selected in the movement phase
        let shouldIgnore = currentPhase == .Movement && currentMovedNode != nil
        
        guard !shouldIgnore else { return }
        
        // Get the first touch
        let touch = touches.first!
        if(touch.view != self.sceneView) {
            return
        }

        // Use an AR hit test at the touch location to find the touched node
        let viewTouchLocation:CGPoint = touch.location(in: sceneView)
        guard let result = sceneView.hitTest(viewTouchLocation, options: nil).first else {
            return
        }
        
        // Ignore result if touched node is not a character
        var char: Character?
        if !isCharacter(node: result.node, char: &char) {
            return
        }

        // Show the movement range at the touched character
        if currentPhase == .Movement {
            let isRightTurn = (char == firstCharacter && isPlayer1()) || (char == secondCharacter && isPlayer2())
            if !isRightTurn {
                return
            }
            
            showMoveRadius(at: char)
            hideHint()
            
            return
        }
        
        // If no attacker selected yet, set the attacker node and show its attacking range
        if attackingNode == nil {
            let isRightTurn = (char == firstCharacter && isPlayer1()) || (char == secondCharacter && isPlayer2())
            if !isRightTurn {
                return
            }
            
            showMoveRadius(at: char)
            attackingNode = char
            updateHint()
        } else {
            // Try to set the touched node as the defending node
            let isRightTarget = (char == firstCharacter && isPlayer2()) || (char == secondCharacter && isPlayer1())
            if !isRightTarget {
                return
            }
            
            // If desired attack target is not in range, show hint and return function
            if char == nil || !isInRange(char!) {
                shakeAnimation(for: hintView)
                highlightMoveRadius()
                return
            }
            
            // Initiate the attack
            canSwitchPhase = false
            attackTarget = char
            hideHint()
            showAttackView()
        }
    }
    
    // Test if a give node is of type character in order to determine nodes in the scene as characters
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
    
    // Used in the selection phase to assign characters to players
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard currentPhase == .Selection else { return nil }
        
        // TEMPORARY FIX FOR ADDITIONAL NODES
        // ARKit creates and adds dummy nodes by itself for some reason which block all touches and therefore, have to be removed
        if (shouldRemoveFirstNodes) {
            sceneView.scene.rootNode.childNodes.last!.removeFromParentNode()
            sceneView.scene.rootNode.childNodes.last!.removeFromParentNode()
            
            shouldRemoveFirstNodes = false
        }
        
        // Assign the character for the first player and move to the next player
        if firstCharacter == nil {
            firstCharacter = Character.create(from: anchor as? ARObjectAnchor)
            currentPlayer = 1
            updateHint()
            
            addMovmentRadius()
            
            return firstCharacter
        }
        
        // Assign the character for the second player and proceed to the actual game
        if secondCharacter == nil {
            secondCharacter = Character.create(from: anchor as? ARObjectAnchor)
            
            currentPlayer = 0
            changePhase(to: .Movement)
            canSwitchPhase = true
            
            return secondCharacter
        }
        
        // Ignore anchors for any additonally detected object (which shouldn't happen anyway)
        return nil
    }
    
    // In case of the movement phase and a node to move is set, compare the movement range to the new location
    // to check if a character is still in range
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
        // Creates the circular SCNNode used to display the movement and attack ranges
        let circle = SCNCylinder(radius: 0.0, height: 0.001)
        circle.firstMaterial?.diffuse.contents = defaultCircleColor
        
        movementNode = SCNNode(geometry: circle)
        movementNode.position = SCNVector3Zero
        
        // Adds the node to the scene so it's not attached to any other node
        sceneView.scene.rootNode.addChildNode(movementNode)
    }
    
    func showMoveRadius(at character: Character?) {
        guard let character = character else { return }
        
        // Moves the node to the moved character's position
        movementNode.position = character.position
        // Initializes the properties of the range
        currentMovementRadius = character.movementRadius
        currentMovedNode = character
        isInRange = true
        
        // Animates the range to appear from the inside out
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
        // Animates the range to be hidden again
        let animation = CABasicAnimation(keyPath: "geometry.radius")
        animation.fromValue = currentMovementRadius
        animation.toValue = 0.0
        animation.duration = 0.35
        animation.autoreverses = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        movementNode.addAnimation(animation, forKey: "radius")
        
        // Resets the properties of the range
        currentMovementRadius = 0.0
        currentMovedNode = nil
    }
    
    // Used to show a color effect on the range if a node is out of range
    func highlightMoveRadius() {
        let oldColor = defaultCircleColor
        let newColor = outOfRangeCircleColor
        let duration: TimeInterval = 0.2
        // Action for changing the color from default to out of range
        let act0 = SCNAction.customAction(duration: duration, action: { (node, elapsedTime) in
            let percentage = elapsedTime / CGFloat(duration)
            node.geometry?.firstMaterial?.diffuse.contents = self.getPercentageColor(from: oldColor, to: newColor, percentage: percentage)
        })
        // Action for changing the color back to default
        let act1 = SCNAction.customAction(duration: duration, action: { (node, elapsedTime) in
            let percentage = elapsedTime / CGFloat(duration)
            node.geometry?.firstMaterial?.diffuse.contents = self.getPercentageColor(from: newColor, to: oldColor, percentage: percentage)
        })
        
        let act = SCNAction.sequence([act0, act1])
        // Starts the animation
        movementNode.runAction(act)
    }
    
    func checkMovementRadius() {
        guard let movedNode = currentMovedNode else { return }
        
        let x1 = movementNode.position.x
        let z1 = movementNode.position.z
        let x2 = movedNode.position.x
        let z2 = movedNode.position.z
        
        // Uses the positions of character and movement range to calculate their distance (ignoring y differences)
        let distance = sqrtf(powf(x2-x1, 2) + powf(z2-z1, 2))
        
        // Only proceeds if the state changed (i.e. was in range and now isn't or vice versa)
        if (isInRange && distance <= Float(currentMovementRadius)) || (!isInRange && distance > Float(currentMovementRadius)) {
            return
        }
        
        // Updates the flags
        isInRange = !isInRange
        canSwitchPhase = isInRange
        
        // Changes the color of the movement range to reflect its current status
        UIView.animate(withDuration: 0.35, animations: {
            self.movementNode.geometry?.firstMaterial?.diffuse.contents = self.isInRange
                ? self.defaultCircleColor
                : self.outOfRangeCircleColor
        })
    }
    
    // Similar to checkMovementRadius but used for attacks instead of movements
    // Only returns if the two nodes are in range or not (no side effects)
    func isInRange(_ node: Character) -> Bool {
        guard let attackingNode = attackingNode else { return false }
        
        let x1 = attackingNode.position.x
        let z1 = attackingNode.position.z
        let x2 = node.position.x
        let z2 = node.position.z
        
        let distance = sqrtf(powf(x2-x1, 2) + powf(z2-z1, 2))
        
        return distance <= Float(attackingNode.attackRadius)
    }
    
    // MARK: - Switch Phase Action
    
    var canSwitchPhase = false
    
    // The action for the change phase button
    @IBAction func changePhase(_ sender: Any) {
        // Checks if the current phase can be changed right now and if not
        // indicates this by shaking the view
        guard canSwitchPhase else {
            shakeAnimation(for: changePhaseView)
            return
        }
        
        // Hides potentially visible ranges
        hideMoveRadius()
        attackTarget = nil
        attackingNode = nil
        
        // Proceeds to the next phase depending on the current one
        switch currentPhase {
        case .Movement?:
            changePhase(to: .Attack, animated: true)
        case .Attack?:
            currentPlayer = isPlayer1() ? 1 : 0
            changePhase(to: .Movement, animated: true)
        default:
            return
        }
    }
    
    func shakeAnimation(for view: UIView) {
        // Creates a little shake animation for the given view
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.1
        animation.repeatCount = 2
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: view.center.x - 10, y: view.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: view.center.x + 10, y: view.center.y))
        
        view.layer.add(animation, forKey: "position")
    }
    
    // MARK: - Game Info Helpers
    
    func changePhase(to phase: TurnPhase, animated: Bool = true) {
        // If the phase change shouldn't be animated, the phase is just updated
        guard animated else {
            currentPhase = phase
            return
        }
        
        // Animates the change of the hint view due to the phase change
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
                    self.changePhaseView.alpha = 1.0
                    
                    self.view.layoutIfNeeded()
                })
            })
        }
    }
    
    func updateHint(animated: Bool = true) {
        // Just updates the hint if it is not animated
        guard animated else {
            updateHintText()
            return
        }
        
        // Animates the change of the hint view
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
    
    func hideHint() {
        // Hides the hint view
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.7, animations: {
                self.hintViewTop.constant = -self.phaseView.frame.height
                self.hintView.alpha = 0.0
                self.view.layoutIfNeeded()
            })
        }
    }
    
    // Hides the phase view
    func hidePhase() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.7, animations: {
                self.phaseView.alpha = 0.0
                self.view.layoutIfNeeded()
            })
        }
    }
    
    // Hides the change phase view
    func hideChangePhase() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.7, animations: {
                self.changePhaseView.alpha = 0.0
                self.view.layoutIfNeeded()
            })
        }
    }
    
    // Shows the victory view
    func showVictoryView() {
        victoryLabel.text = "Congratulations!\n\n\(isPlayer1() ? "Player 1" : "Player 2") wins the game!"
        
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.7, animations: {
                self.victoryView.alpha = 1.0
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func updateHintText() {
        var hint: String!
        
        // Updates the displayed hint based on the current phase
        if currentPhase == .Selection {
            hint = "Choose your character by looking at it"
        } else if currentPhase == .Movement {
            hint = "Tap the character you want to move"
        } else {
            hint = attackingNode != nil ? "Tap the character you want to attack" : "Tap the character you want to attack with"
        }
        
        DispatchQueue.main.async {
            self.hintLabel.text = hint
        }
    }
    
    func updatePhaseText() {
        var phase: String!
        
        // Updates the phase text based on the current phase
        if currentPhase == .Selection {
            phase = "Selection"
        } else if currentPhase == .Movement {
            phase = "Movement"
        } else {
            phase = "Attack"
        }
        
        DispatchQueue.main.async {
            self.phaseLabel.text = phase
        }
    }
    
    func updatePlayerText() {
        // Updates the player text to show whose turn it is
        DispatchQueue.main.async {
            self.playerLabel.text = self.getCurrentPlayerString()
        }
    }
}
extension ViewController {
    // An extension function in order to get the proportionate color between two colors based on the percentage of the animation elapsed
    func getPercentageColor(from: UIColor, to: UIColor, percentage: CGFloat) -> UIColor {
        let fromComponents = from.cgColor.components!
        let toComponents = to.cgColor.components!
        
        let color = UIColor(red: fromComponents[0] + (toComponents[0] - fromComponents[0]) * percentage,
                            green: fromComponents[1] + (toComponents[1] - fromComponents[1]) * percentage,
                            blue: fromComponents[2] + (toComponents[2] - fromComponents[2]) * percentage,
                            alpha: fromComponents[3] + (toComponents[3] - fromComponents[3]) * percentage)
        return color
    }
}

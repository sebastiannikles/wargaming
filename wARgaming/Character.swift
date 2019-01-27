//
//  Character.swift
//  wARgaming
//
//  Created by Sebastian Nikles on 05.01.19.
//  Copyright © 2019 Sebastian Nikles. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class Character: SCNNode {
    var movementRadius = 0.0
    var attackRadius = 0.0
    
    static func create(from objectAnchor: ARObjectAnchor?) -> Character? {
        guard let objectAnchor = objectAnchor else { return nil }
        
        let character = Character()
        
        character.movementRadius = 0.2
        character.attackRadius = 0.2
        
        character.addCharacterBox(with: objectAnchor)
        character.addCharacterInfo(with: objectAnchor)
        character.addCharacterStats(with: objectAnchor)
        
        return character
    }
    
    func addCharacterBox(with objectAnchor: ARObjectAnchor) {
        let box = SCNBox(width: CGFloat(objectAnchor.referenceObject.extent.x), height: CGFloat(objectAnchor.referenceObject.extent.y), length: CGFloat(objectAnchor.referenceObject.extent.z), chamferRadius: 0.0)
        box.firstMaterial?.diffuse.contents = UIColor.clear
        
        let boxNode = SCNNode(geometry: box)
        boxNode.position = SCNVector3Make(objectAnchor.referenceObject.center.x, objectAnchor.referenceObject.center.y, objectAnchor.referenceObject.center.z)
        
        addChildNode(boxNode)
    }
    
    func addCharacterInfo(with objectAnchor: ARObjectAnchor) {
        let plane = SCNPlane(width: 0.2, height: 0.0467)
        plane.cornerRadius = 0.01
        let characterInfoScene = SKScene(fileNamed: "CharacterInfo")
        plane.firstMaterial?.diffuse.contents = characterInfoScene
        plane.firstMaterial?.isDoubleSided = false
        plane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.constraints = [SCNBillboardConstraint()]
        planeNode.position = SCNVector3Make(objectAnchor.referenceObject.center.x, objectAnchor.referenceObject.center.y + objectAnchor.referenceObject.extent.y + 0.03, objectAnchor.referenceObject.center.z)
        
        addChildNode(planeNode)
    }
    
    func addCharacterStats(with objectAnchor: ARObjectAnchor) {
        let plane = SCNPlane(width: 0.15, height: 0.03)
        plane.cornerRadius = 0.01
        
        let statsScene = SKScene(fileNamed: "Stats")
        plane.firstMaterial?.diffuse.contents = statsScene
        plane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.constraints = [SCNBillboardConstraint()]
        planeNode.position = SCNVector3Make(objectAnchor.referenceObject.center.x, 0.03, objectAnchor.referenceObject.center.z + 0.12)
        
        addChildNode(planeNode)
    }
}

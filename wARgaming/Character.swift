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

// The different possible types used to calculate the weapon strength
enum WeaponStrengthType {
    case Integer
    case Multiplier
    case Add
}

class Character: SCNNode {
    // The properties inherent to a character
    // Set to default values for exemplary purposes
    var movementRadius = 0.2
    var attackRadius = 0.2
    
    var weaponStrengthType: WeaponStrengthType = .Add
    var ballisticSkill = 2
    var weaponStrength = 2
    var armorPenetration = 3
    var weaponDamage = 3
    var toughness = 5
    var save = 2
    var wounds = 6
    var strength = 4
    
    // Creates the character node itself and its child nodes used for additional augmentation of the character
    static func create(from objectAnchor: ARObjectAnchor?) -> Character? {
        guard let objectAnchor = objectAnchor else { return nil }
        
        let character = Character()
        
        character.addCharacterBox(with: objectAnchor)
        character.addCharacterInfo(with: objectAnchor)
        character.addCharacterStats(with: objectAnchor)
        
        return character
    }
    
    // Calculates the weapon strength based on the type
    func getWeaponStrength() -> Int {
        switch weaponStrengthType {
        case .Add:
            return strength + weaponStrength
        case .Integer:
            return weaponStrength
        case .Multiplier:
            return strength * weaponStrength
        }
    }
    
    // Creates a bounding box around the physical object using the created anchor by ARKit
    func addCharacterBox(with objectAnchor: ARObjectAnchor) {
        let box = SCNBox(width: CGFloat(objectAnchor.referenceObject.extent.x), height: CGFloat(objectAnchor.referenceObject.extent.y), length: CGFloat(objectAnchor.referenceObject.extent.z), chamferRadius: 0.0)
        box.firstMaterial?.diffuse.contents = UIColor.clear
        
        let boxNode = SCNNode(geometry: box)
        boxNode.position = SCNVector3Make(objectAnchor.referenceObject.center.x, objectAnchor.referenceObject.center.y, objectAnchor.referenceObject.center.z)
        
        addChildNode(boxNode)
    }
    
    // Creates a billboard node which shows the character's name and shows it above the physical object
    func addCharacterInfo(with objectAnchor: ARObjectAnchor) {
        let plane = SCNPlane(width: 0.2, height: 0.0467)
        plane.cornerRadius = 0.01
        let characterInfoScene = SKScene(fileNamed: objectAnchor.referenceObject.name == "LemanRuss" ? "CharacterInfoLeman" : "CharacterInfoGargbot")
        plane.firstMaterial?.diffuse.contents = characterInfoScene
        plane.firstMaterial?.isDoubleSided = false
        plane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.constraints = [SCNBillboardConstraint()]
        planeNode.position = SCNVector3Make(objectAnchor.referenceObject.center.x, objectAnchor.referenceObject.center.y + objectAnchor.referenceObject.extent.y + 0.03, objectAnchor.referenceObject.center.z)
        
        addChildNode(planeNode)
    }
    
    // Creates a billboard node which shows the character's stats and shows it below the physical object
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

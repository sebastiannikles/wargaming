//
//  AttackView.swift
//  wARgaming
//
//  Created by Sebastian Nikles on 27.01.19.
//  Copyright © 2019 Sebastian Nikles. All rights reserved.
//

import UIKit

@IBDesignable
class AttackView: UIView, NibLoadable {
    
    // The different IBOutlets used in AttackView.xib to display the attack's progress
    @IBOutlet weak var rollButton: UIButton!
    @IBOutlet weak var attackStateLabel: UILabel!
    
    @IBOutlet weak var ballisticSkillLabel: UILabel!
    @IBOutlet weak var rolledBallisticSkillLabel: UILabel!
    @IBOutlet weak var wSLabel: UILabel!
    @IBOutlet weak var rolledWSLabel: UILabel!
    @IBOutlet weak var aPLabel: UILabel!
    @IBOutlet weak var dLabel: UILabel!
    @IBOutlet weak var rolledAPLabel: UILabel!
    @IBOutlet weak var tLabel: UILabel!
    @IBOutlet weak var sVLabel: UILabel!
    @IBOutlet weak var rolledSVLabel: UILabel!
    @IBOutlet weak var wLabel: UILabel!
    
    @IBOutlet weak var attackerNameLabel: UILabel!
    @IBOutlet weak var defenderNameLabel: UILabel!
    
    // The both characters participating in the attack
    var attackingCharacter: Character!
    var defendingCharacter: Character!
    
    // The callback which is executed after the action has concluded
    var completionAction: (() -> ())!
    
    // The current phase
    // Updates the button text according to the current phase
    var phase: AttackPhase! {
        didSet {
            switch phase {
            case .HitRoll?:
                rollButton.setTitle("Hit Roll", for: .normal)
            case .WoundRoll?:
                rollButton.setTitle("Wound Roll", for: .normal)
            case .SavingThrow?:
                rollButton.setTitle("Saving Throw", for: .normal)
            case .Success?:
                rollButton.setTitle("End", for: .normal)
                attackStateLabel.text = "The attack was successful"
            default:
                rollButton.setTitle("Close", for: .normal)
                attackStateLabel.text = "The attack has failed"
            }
        }
    }
    
    // The possible phases an attack can be in
    enum AttackPhase {
        case HitRoll
        case WoundRoll
        case SavingThrow
        case Ended
        case Success
    }
    
    // Sets up the view using the extension method
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()
    }
    
    // Sets up the view using the extension method
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
    }
    
    func setUp(_ attacker: Character, _ defender: Character, completion: @escaping (() -> ())) {
        // Sets the attack to its first phase
        phase = .HitRoll
        
        // Sets up the required properties
        attackingCharacter = attacker
        defendingCharacter = defender
        completionAction = completion

        // Resets the UI element text's
        ballisticSkillLabel.text = "\(attacker.ballisticSkill)+"
        rolledBallisticSkillLabel.text = ""
        wSLabel.text = "+\(attacker.weaponStrength)"
        rolledWSLabel.text = ""
        aPLabel.text = "-\(attacker.armorPenetration)"
        rolledAPLabel.text = ""
        dLabel.text = String(attacker.weaponDamage)

        tLabel.text = String(defender.toughness)
        sVLabel.text = "\(defender.save)+"
        rolledSVLabel.text = ""
        wLabel.text = String(defender.wounds)

        attackStateLabel.text = ""
    }
    
    // The roll button's action which executes the roll (or the completion action) based on the current phase
    @IBAction func roll(_ sender: Any) {
        if phase == .HitRoll {
            handleHitRoll()
        } else if phase == .WoundRoll {
            handleWoundRoll()
        } else if phase == .SavingThrow {
            handleSavingThrow()
        } else {
            completionAction()
        }
    }
    
    func handleHitRoll() {
        // Generates a number for the dice roll
        let roll = arc4random_uniform(6) + 1
        
        // Updates the text
        rolledBallisticSkillLabel.text = String(roll)
        
        // Compares the roll to the threshold to determine the next phase
        if roll == 1 || roll < attackingCharacter.ballisticSkill {
            phase = .Ended
            rolledBallisticSkillLabel.textColor = UIColor.red
        } else {
            rolledBallisticSkillLabel.textColor = UIColor.black
            phase = .WoundRoll
        }
    }
    
    func handleWoundRoll() {
        // Generates a number for the dice roll
        let roll = arc4random_uniform(6) + 1
        let requiredRoll: Int!
        
        let weaponStrength = attackingCharacter.getWeaponStrength()
        
        // Calculates the required roll based on the weapon strength of the attacker and the toughness of the defender
        if weaponStrength >= 2 * defendingCharacter.toughness {
            requiredRoll = 2
        } else if weaponStrength > defendingCharacter.toughness {
            requiredRoll = 3
        } else if weaponStrength == defendingCharacter.toughness {
            requiredRoll = 4
        } else if 2 * weaponStrength < defendingCharacter.toughness {
            requiredRoll = 6
        } else {
            requiredRoll = 5
        }
        
        // Updates the text
        rolledWSLabel.text = String(roll)
        
        // Compares the roll to the threshold to determine the next phase
        if roll == 1 || roll < requiredRoll {
            phase = .Ended
            rolledWSLabel.textColor = UIColor.red
        } else {
            rolledWSLabel.textColor = UIColor.black
            phase = .SavingThrow
        }
    }
    
    func handleSavingThrow() {
        // Generates a number for the dice roll
        let roll = arc4random_uniform(6) + 1
        
        // Updates the text
        rolledSVLabel.text = String(roll)
        
        // Compares the roll to the threshold to determine the next phase
        if roll > 1 && Int(roll) - attackingCharacter.armorPenetration >= defendingCharacter.save {
            rolledSVLabel.textColor = UIColor.black
            phase = .Ended
        } else {
            phase = .Success
            rolledSVLabel.textColor = UIColor.red
            defendingCharacter.wounds -= attackingCharacter.weaponDamage
        }
    }
}

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
    var attackingCharacter: Character!
    var defendingCharacter: Character!
    
    var completionAction: (() -> ())!
    
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
    
    enum AttackPhase {
        case HitRoll
        case WoundRoll
        case SavingThrow
        case Ended
        case Success
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
    }
    
    func setUp(_ attacker: Character, _ defender: Character, completion: @escaping (() -> ())) {
        phase = .HitRoll
        
        attackingCharacter = attacker
        defendingCharacter = defender
        completionAction = completion

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
        let roll = arc4random_uniform(6) + 1
        
        rolledBallisticSkillLabel.text = String(roll)
        
        if roll == 1 || roll < attackingCharacter.ballisticSkill {
            phase = .Ended
            rolledBallisticSkillLabel.textColor = UIColor.red
        } else {
            phase = .WoundRoll
        }
    }
    
    func handleWoundRoll() {
        let roll = arc4random_uniform(6) + 1
        let requiredRoll: Int!
        
        if attackingCharacter.weaponStrength >= 2 * defendingCharacter.toughness {
            requiredRoll = 2
        } else if attackingCharacter.weaponStrength >= defendingCharacter.toughness {
            requiredRoll = 3
        } else if attackingCharacter.weaponStrength == defendingCharacter.toughness {
            requiredRoll = 4
        } else if 2 * attackingCharacter.weaponStrength < defendingCharacter.toughness {
            requiredRoll = 6
        } else {
            requiredRoll = 5
        }
        
        rolledWSLabel.text = String(roll)
        
        if roll == 1 || roll < requiredRoll {
            phase = .Ended
            rolledWSLabel.textColor = UIColor.red
        } else {
            phase = .SavingThrow
        }
    }
    
    func handleSavingThrow() {
        let roll = arc4random_uniform(6) + 1
        
        rolledSVLabel.text = String(roll)
        
        if roll > 1 && Int(roll) - attackingCharacter.armorPenetration >= defendingCharacter.save {
            phase = .Ended
        } else {
            phase = .Success
            rolledSVLabel.textColor = UIColor.red
            defendingCharacter.wounds -= attackingCharacter.weaponDamage
        }
    }
}

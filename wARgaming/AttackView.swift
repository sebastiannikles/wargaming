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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupFromNib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupFromNib()
    }
    
    func setUp(_ attacker: Character, _ defender: Character) {
        attackingCharacter = attacker
        defendingCharacter = defender

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
    }
}

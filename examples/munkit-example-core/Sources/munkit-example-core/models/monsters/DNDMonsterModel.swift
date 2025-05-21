//
//  DNDMonsterModel.swift
//  munkit-example-core
//
//  Created by Ilia Chub on 12.05.2025.
//

import Foundation

public struct DNDMonsterModel: Sendable, Decodable {
    public let index: String
    public let name: String
    public let size: String
    public let type: String
    public let alignment: String
    public let armorClass: [DNDMonsterArmorClassModel]
    public let hitPoints: Int
    public let hitDice: String
    public let hitPointsRoll: String
    public let speed: DNDMonsterSpeedModel
    public let strength: Int
    public let dexterity: Int
    public let constitution: Int
    public let intelligence: Int
    public let wisdom: Int
    public let charisma: Int
    public let proficiencies: [DNDMonsterProficiencyModel]
    public let damageVulnerabilities: [String]
    public let damageResistances: [String]
    public let damageImmunities: [String]
    public let conditionImmunities: [String]
    public let senses: DNDMonsterSenses
    public let languages: String
    public let challengeRating: Float
    public let proficiencyBonus: Int
    public let xp: Int
    public let specialAbilities: [DNDMonsterSpecialAbilityModel]
    public let actions: [DNDMonsterActionModel]
    public let legendaryActions: [DNDMonsterLegendaryActionModel]
    public let image: String
    public let url: String
    public let updatedAt: String
    public let forms: [String]
    public let reactions: [String]

    enum CodingKeys: String, CodingKey {
        case index
        case name
        case size
        case type
        case alignment
        case armorClass = "armor_class"
        case hitPoints = "hit_points"
        case hitDice = "hit_dice"
        case hitPointsRoll = "hit_points_roll"
        case speed
        case strength
        case dexterity
        case constitution
        case intelligence
        case wisdom
        case charisma
        case proficiencies
        case damageVulnerabilities = "damage_vulnerabilities"
        case damageResistances = "damage_resistances"
        case damageImmunities = "damage_immunities"
        case conditionImmunities = "condition_immunities"
        case senses
        case languages
        case challengeRating = "challenge_rating"
        case proficiencyBonus = "proficiency_bonus"
        case xp
        case specialAbilities = "special_abilities"
        case actions
        case legendaryActions = "legendary_actions"
        case image
        case url
        case updatedAt = "updated_at"
        case forms
        case reactions
    }
}

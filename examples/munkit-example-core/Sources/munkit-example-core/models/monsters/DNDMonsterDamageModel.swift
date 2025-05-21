//
//  DNDMonsterDamageModel.swift
//  munkit-example-core
//
//  Created by Ilia Chub on 12.05.2025.
//

public struct DNDMonsterDamageModel: Sendable, Decodable {
    public let damageType: DNDMonsterDamageTypeModel
    public let damageDice: String

    enum CodingKeys: String, CodingKey {
        case damageType = "damage_type"
        case damageDice = "damage_dice"
    }
}

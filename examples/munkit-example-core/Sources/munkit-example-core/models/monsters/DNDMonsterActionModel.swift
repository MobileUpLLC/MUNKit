//
//  DNDMonsterActionModel.swift
//  munkit-example-core
//
//  Created by Ilia Chub on 12.05.2025.
//

public struct DNDMonsterActionModel: Sendable, Decodable {
    public let name: String
    public let desc: String
    public let multiattackType: String?
    public let attackBonus: Int?
    public let usage: DNDMonsterUsageModel?
    public let damage: [DNDMonsterDamageModel]
    public let actions: [DNDMonsterSubActionModel]

    enum CodingKeys: String, CodingKey {
        case name
        case desc
        case multiattackType = "multiattack_type"
        case attackBonus = "attack_bonus"
        case usage
        case damage
        case actions
    }
}

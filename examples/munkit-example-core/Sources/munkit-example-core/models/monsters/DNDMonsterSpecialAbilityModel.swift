//
//  DNDMonsterSpecialAbilityModel.swift
//  munkit-example-core
//
//  Created by Ilia Chub on 12.05.2025.
//

public struct DNDMonsterSpecialAbilityModel: Sendable, Decodable {
    public let name: String
    public let desc: String
    public let damage: [DNDMonsterDamageModel]
}

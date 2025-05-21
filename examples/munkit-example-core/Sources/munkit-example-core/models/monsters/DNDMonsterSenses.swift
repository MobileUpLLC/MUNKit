//
//  DNDMonsterSenses.swift
//  munkit-example-core
//
//  Created by Ilia Chub on 12.05.2025.
//

public struct DNDMonsterSenses: Sendable, Decodable {
    public let darkvision: String?
    public let passivePerception: Int

    enum CodingKeys: String, CodingKey {
        case darkvision
        case passivePerception = "passive_perception"
    }
}

//
//  DNDMonsterSubActionModel.swift
//  munkit-example-core
//
//  Created by Ilia Chub on 12.05.2025.
//

public struct DNDMonsterSubActionModel: Sendable, Decodable {
    public let actionName: String
    public let count: String
    public let type: String

    enum CodingKeys: String, CodingKey {
        case actionName = "action_name"
        case count
        case type
    }
}

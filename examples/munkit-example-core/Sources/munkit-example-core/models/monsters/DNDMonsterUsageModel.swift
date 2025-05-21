//
//  DNDMonsterUsageModel.swift
//  munkit-example-core
//
//  Created by Ilia Chub on 12.05.2025.
//

public struct DNDMonsterUsageModel: Sendable, Decodable {
    public let type: String
    public let times: Int?
}

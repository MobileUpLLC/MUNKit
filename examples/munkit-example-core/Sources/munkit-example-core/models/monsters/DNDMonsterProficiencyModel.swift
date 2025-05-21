//
//  DNDMonsterProficiencyModel.swift
//  munkit-example-core
//
//  Created by Ilia Chub on 12.05.2025.
//

public struct DNDMonsterProficiencyModel: Sendable, Decodable {
    public let value: Int
    public let proficiency: DNDMonsterProficiencyDetailModel
}

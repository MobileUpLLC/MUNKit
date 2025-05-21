//
//  DNDMonstersListModel.swift
//  munkit-example-core
//
//  Created by Ilia Chub on 12.05.2025.
//

import Foundation

public struct DNDMonstersListModel: Sendable, Decodable {
    public let count: Int
    public let results: [DNDMonsterShortModel]
}

//
//  DNDClassModel.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import Foundation

public struct DNDClassModel: Decodable, Sendable {
    public let index: String
    public let name: String
    public let url: URL
    public var isLiked: Bool

    public init(index: String, name: String, url: URL, isLiked: Bool = false) {
        self.index = index
        self.name = name
        self.url = url
        self.isLiked = isLiked
    }

    enum CodingKeys: String, CodingKey {
        case index
        case name
        case url
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(String.self, forKey: .index)
        name = try container.decode(String.self, forKey: .name)
        url = try container.decode(URL.self, forKey: .url)
        isLiked = false
    }
}

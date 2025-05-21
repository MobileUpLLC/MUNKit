//
//  DNDClassesListModel.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import Foundation

public struct DNDClassesListModel: Decodable, Sendable {
    public var results: [DNDClassModel]

    public init(results: [DNDClassModel]) {
        self.results = results
    }
}

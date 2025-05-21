//
//  KeyedReplicaSettings.swift
//  munkit
//
//  Created by Ilia Chub on 14.05.2025.
//

import Foundation

public struct KeyedReplicaSettings<K: Sendable, T: Sendable>: Sendable {
    let maxCount: Int
    let childRemovingPolicy: KeyedReplicaChildRemovingPolicy<K, T>

    public init(maxCount: Int, childRemovingPolicy: KeyedReplicaChildRemovingPolicy<K, T>) {
        self.maxCount = maxCount
        self.childRemovingPolicy = childRemovingPolicy
    }
}

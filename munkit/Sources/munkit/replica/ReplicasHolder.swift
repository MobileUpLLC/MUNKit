//
//  ReplicaClient.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 03.04.2025.
//

import Foundation

public actor ReplicasHolder {
    private var singleReplicas: [any SingleReplica] = []
    private var keydReplicas: [any KeyedReplica] = []

    public static let shared = ReplicasHolder()
    
    private init() {}

    public func getSingleReplica<T: Sendable>(
        name: String,
        settings: SingleReplicaSettings,
        storage: (any SingleReplicaStorage<T>)?,
        fetcher: @Sendable @escaping () async throws -> T
    ) async -> any SingleReplica<T> {
        var replica: (any SingleReplica)? = nil
        for singleReplica in singleReplicas {
            if await singleReplica.name == name {
                replica = singleReplica
                break
            }
        }
        if let replica = replica as? any SingleReplica<T> {
            return replica
        }

        let newReplica = SingleReplicaImplementation(
            name: name,
            settings: settings,
            storage: storage,
            fetcher: fetcher
        )

        singleReplicas.append(newReplica)

        return newReplica
    }

    public func getKeydReplica<K: Hashable & Sendable, T: Sendable>(
        name: String,
        childNameFacroty: @Sendable @escaping (K) -> String,
        childSettingsFactory: @Sendable @escaping (K) -> SingleReplicaSettings,
        settings: KeyedReplicaSettings<K, T>,
        fetcher: @escaping @Sendable (K) async throws -> T
    ) async -> any KeyedReplica<K, T> {
        var replica: (any KeyedReplica)? = nil
        for keydReplica in keydReplicas {
            if await keydReplica.name == name {
                replica = keydReplica
                break
            }
        }
        if let replica = replica as? any KeyedReplica<K, T> {
            return replica
        }

        let newKeydReplica = KeyedReplicaImplementation<K, T>(
            name: name,
            settings: settings,
            childFactory: { key in
                SingleReplicaImplementation(
                    name: childNameFacroty(key),
                    settings: childSettingsFactory(key),
                    storage: nil,
                    fetcher: { try await fetcher(key) }
                )
            }
        )

        keydReplicas.append(newKeydReplica)

        return newKeydReplica
    }
}

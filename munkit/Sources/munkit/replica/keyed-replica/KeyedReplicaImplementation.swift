//
//  KeyedReplicaImplementation.swift
//  munkit
//
//  Created by Ilia Chub on 12.05.2025.
//

import Foundation

actor KeyedReplicaImplementation<K: Hashable & Sendable, T: Sendable>: KeyedReplica {
    var name: String

    private let settings: KeyedReplicaSettings<K, T>
    private let childFactory: @Sendable (K) -> any SingleReplica<T>

    private var replicas: [K: any SingleReplica<T>] = [:]
    
    init(
        name: String,
        settings: KeyedReplicaSettings<K, T>,
        childFactory: @Sendable @escaping (K) -> any SingleReplica<T>
    ) {
        self.name = name
        self.settings = settings
        self.childFactory = childFactory
    }

    func observe(activityStream: AsyncStream<Bool>, keyStream: AsyncStream<K>) async -> KeyedReplicaObserver<K, T> {
        return KeyedReplicaObserver<K, T>(
            activityStream: activityStream,
            keyStream: keyStream,
            replicaProvider: getOrCreateReplica
        )
    }

    func refresh(key: K) async {
        await getOrCreateReplica(key).refresh()
    }

    func revalidate(key: K) async {
        await getOrCreateReplica(key).revalidate()
    }

    private func getOrCreateReplica(_ key: K) async -> any SingleReplica<T> {
        if let replica = replicas[key] {
            return replica
        }

        var replicasCurrentValueByKey: [(K, SingleReplicaState<T>)] = []
        for replica in replicas {
            replicasCurrentValueByKey.append(await (replica.key, replica.value.currentState))
        }

        if
            replicas.count == settings.maxCount,
            let keyForRemoving = replicasCurrentValueByKey.sorted(
                by: settings.childRemovingPolicy.comparator
            ).first?.0
        {
            MUNLogger.shared?
                .log(
                    type: .debug,
                    "🕸️🧙☠️ Removing replica for key \(keyForRemoving) with policy: \(settings.childRemovingPolicy)"
                )
            replicas.removeValue(forKey: keyForRemoving)
        }

        MUNLogger.shared?.log(
            type: .debug,
            "🕸️🧙🆕 Creating replica for key \(key)"
        )

        let replica = childFactory(key)

        replicas[key] = replica
        return replica
    }
}

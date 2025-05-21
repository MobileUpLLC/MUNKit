//
//  KeyedReplica.swift
//  munkit
//
//  Created by Ilia Chub on 12.05.2025.
//

import Foundation

public protocol KeyedReplica<K, T>: Actor {
    associatedtype K: Hashable & Sendable
    associatedtype T: Sendable

    var name: String { get }

    init(
        name: String,
        settings: KeyedReplicaSettings<K, T>,
        childFactory: @Sendable @escaping (K) -> any SingleReplica<T>,
    )

    /// Starts observing a keyed replica. Returns a ReplicaObserver that provides access to replica state and error events.
    func observe(activityStream: AsyncStream<Bool>, keyStream: AsyncStream<K>) async -> KeyedReplicaObserver<K, T>

    /// Loads fresh data from the network for a given key.
    func refresh(key: K) async

    /// Loads fresh data from the network for a given key if the data is stale.
    func revalidate(key: K) async
}

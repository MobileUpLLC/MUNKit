//
//  SingleReplica.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

public protocol SingleReplica<T>: Actor {
    associatedtype T: Sendable

    var name: String { get }
    var currentState: SingleReplicaState<T> { get }

    init(
        name: String,
        settings: SingleReplicaSettings,
        storage: (any SingleReplicaStorage<T>)?,
        fetcher: @Sendable @escaping () async throws -> T
    )

    /// Starts observing the replica's state.
    func observe(activityStream: AsyncStream<Bool>) async -> SingleReplicaObserver<T>

    /// Fetches fresh data from the network.
    /// - Note: Does not trigger a new request if one is already in progress.
    func refresh() async

    /// Fetches fresh data from the network if the current data is stale.
    /// - Note: Does not trigger a new request if one is already in progress.
    func revalidate() async
}

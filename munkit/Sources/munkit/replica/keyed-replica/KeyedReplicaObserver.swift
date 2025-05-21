//
//  KeyedReplicaObserver.swift
//  munkit
//
//  Created by Ilia Chub on 13.05.2025.
//

import Foundation

public actor KeyedReplicaObserver<K: Sendable & Hashable, T: Sendable> {
    public let stateStream: AsyncStream<SingleReplicaState<T>>

    private let stateStreamContinuation: AsyncStream<SingleReplicaState<T>>.Continuation
    private let keyStream: AsyncStream<K>
    private let replicaProvider: (K) async -> any SingleReplica<T>

    private let activityStream: AsyncStream<Bool>
    private var currentActivity: Bool = false

    private var activeChild: (
        key: K,
        observer: SingleReplicaObserver<T>,
        activityStream: AsyncStream<Bool>.Continuation
    )?

    init(
        activityStream: AsyncStream<Bool>,
        keyStream: AsyncStream<K>,
        replicaProvider: @escaping (K) async -> any SingleReplica<T>
    ) {
        (self.stateStream, self.stateStreamContinuation) = AsyncStream<SingleReplicaState<T>>.makeStream()

        self.keyStream = keyStream
        self.replicaProvider = replicaProvider
        self.activityStream = activityStream

        Task { await startActivityObserving() }
        Task { await startKeyObserving() }
    }

    private func updateCurrentActivity(_ newValue: Bool) {
        currentActivity = newValue
    }

    private func startActivityObserving() async {
        for await activity in activityStream {
            updateCurrentActivity(activity)
            activeChild?.activityStream.yield(activity)
        }
        activeChild?.activityStream.finish()
    }

    private func startKeyObserving() async {
        for await key in keyStream {
            guard activeChild?.key != key else { continue }

            activeChild?.activityStream.finish()

            let internalActivityStreamBundle = AsyncStream<Bool>.makeStream()
            let observer = await replicaProvider(key).observe(activityStream: internalActivityStreamBundle.stream)
            let activeChild = (
                key: key,
                observer: observer,
                activityStream: internalActivityStreamBundle.continuation
            )
            self.activeChild = activeChild

            activeChild.activityStream.yield(currentActivity)

            Task {
                for await state in activeChild.observer.stateStream {
                    stateStreamContinuation.yield(state)
                }
                stateStreamContinuation.finish()
            }
        }

        activeChild?.activityStream.finish()
        activeChild = nil
    }
}

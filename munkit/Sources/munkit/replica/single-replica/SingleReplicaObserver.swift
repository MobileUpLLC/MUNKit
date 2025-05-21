//
//  SingleReplicaObserver.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

public actor SingleReplicaObserver<T> where T: Sendable {
    public let stateStream: AsyncStream<SingleReplicaState<T>>

    let observerId = UUID()
    let eventStream: AsyncStream<SingleReplicaObserverEvent>

    private let eventStreamContinuation: AsyncStream<SingleReplicaObserverEvent>.Continuation
    private let activityStream: AsyncStream<Bool>

    init(activityStream: AsyncStream<Bool>, stateStream: AsyncStream<SingleReplicaState<T>>) async {
        self.activityStream = activityStream
        self.stateStream = stateStream

        (self.eventStream, self.eventStreamContinuation) = AsyncStream<SingleReplicaObserverEvent>.makeStream()

        eventStreamContinuation.yield(.observerAdded)
        Task { [weak self] in await self?.startObserverControl() }
    }

    private func startObserverControl() async {
        for await isActive in activityStream {
            eventStreamContinuation.yield(isActive ? .observerActivated : .observerDeactivated)
        }

        eventStreamContinuation.yield(.observerRemoved)
        eventStreamContinuation.finish()
    }
}

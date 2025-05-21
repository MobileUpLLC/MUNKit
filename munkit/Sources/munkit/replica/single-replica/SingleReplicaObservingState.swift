//
//  ObservingState.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

/// Contains information about the observers of a replica.
public struct SingleReplicaObservingState: Sendable, CustomStringConvertible {
    let observerIds: Set<UUID>
    let activeObserverIds: Set<UUID>
    let lastObservingTime: ReplicaLastObservingTime

    public var description: String { getDescription() }

    /// The current observation status based on the number of observers.
    var status: ObservingStatus { getStatus() }

    private func getDescription() -> String {
        return "observers: \(observerIds.count)"
        + " active: \(activeObserverIds.count)"
        + " observingSince: \(lastObservingTime)"
    }

    private func getStatus() -> ObservingStatus {
        if activeObserverIds.count > 0 {
            return .active
        } else if observerIds.count > 0 {
            return .inactive
        } else {
            return .none
        }
    }
}

/// Represents the status of observers for a replica.
enum ObservingStatus {
    /// No observers
    case none
    /// There are inactive observers
    case inactive
    /// There are active observers
    case active
}

/// Represents the time of the last observation of a replica.
enum ReplicaLastObservingTime: Sendable, Comparable, CustomStringConvertible {
    case never
    case timeInPast(Date)
    case now

    var description: String { getDescription() }

    private func getDescription() -> String {
        switch self {
        case .never:
            return "NEVER"
        case .now:
            return "NOW"
        case .timeInPast(let date):
            return date.description(with: .current)
        }
    }
}

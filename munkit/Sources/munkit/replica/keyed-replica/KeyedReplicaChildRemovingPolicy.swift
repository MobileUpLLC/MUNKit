//
//  KeyedReplicaChildRemovingPolicy.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 15.05.2025.
//


public enum KeyedReplicaChildRemovingPolicy<K: Sendable, T: Sendable>: Sendable, CustomStringConvertible {
    case byObservingTime
    case byDataChangingTime
    case customComparator(@Sendable ((K, SingleReplicaState<T>), (K, SingleReplicaState<T>)) -> Bool)

    public var description: String { getDescription() }

    var comparator: @Sendable ((K, SingleReplicaState<T>), (K, SingleReplicaState<T>)) -> Bool { getComparator() }

    private func getComparator() -> @Sendable ((K, SingleReplicaState<T>), (K, SingleReplicaState<T>)) -> Bool {
        switch self {
        case .byObservingTime:
            return { $0.1.observingState.lastObservingTime < $1.1.observingState.lastObservingTime }
        case .byDataChangingTime:
            return {
                guard let lhsData = $0.1.data else {
                    return false
                }

                guard let rhsData = $1.1.data else {
                    return true
                }

                return lhsData.changingDate < rhsData.changingDate
            }
        case .customComparator(let comparator):
            return comparator
        }
    }

    private func getDescription() -> String {
        switch self {
        case .byObservingTime:
            return "BY OBSERVING TIME"
        case .byDataChangingTime:
            return "BY DATA CHANGING TIME"
        case .customComparator:
            return "CUSTOM COMPARATOR"
        }
    }
}

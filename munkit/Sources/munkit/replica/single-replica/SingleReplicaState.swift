//
//  SingleReplicaState.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

public struct SingleReplicaState<T>: Sendable where T: Sendable {
    /// Indicates whether data is currently being loaded.
    public var loading: Bool
    /// Contains the loaded data, if available.
    public var data: SingleReplicaStateData<T>?
    /// Represents an error that occurred during loading.
    public var error: Error?
    /// The observation state.
    var observingState: SingleReplicaObservingState
}

extension SingleReplicaState: CustomStringConvertible {
    public var description: String {
        """
        SingleReplicaState:
          loading: \(loading)
          data: \(data != nil ? "present" : "absent")
          error: \(error?.localizedDescription ?? "none")
          observing: \(observingState)
        """
    }
}

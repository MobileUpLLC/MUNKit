//
//  SingleReplicaStorage.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

/// Interface for saving replica data to persistent storage.
public protocol SingleReplicaStorage<T>: Sendable {
    associatedtype T: Sendable

    /// Writes data to the storage.
    func write(data: T) async throws

    /// Reads data from the storage.
    func read() async throws -> T?

    /// Removes data from the storage.
    func remove() async throws
}

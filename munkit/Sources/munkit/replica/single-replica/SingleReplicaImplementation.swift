//
//  SingleReplicaImplementation.swift
//  MUNKit
//
//  Created by Ilia Chub on 29.04.2025.
//

import Foundation

actor SingleReplicaImplementation<T: Sendable>: SingleReplica {
    public let name: String

    var currentState: SingleReplicaState<T>

    private let settings: SingleReplicaSettings
    private let storage: (any SingleReplicaStorage<T>)?
    private let dataFetcher: @Sendable () async throws -> T

    private var observerStateStreams: [UUID: AsyncStreamBundle<SingleReplicaState<T>>] = [:]
    private var dataClearingTask: Task<Void, Never>?
    private var errorClearingTask: Task<Void, Never>?
    private var cancelTask: Task<Void, Never>?
    private var staleTask: Task<Void, Never>?
    private var loadingTask: Task<Void, Never>?

    init(
        name: String,
        settings: SingleReplicaSettings,
        storage: (any SingleReplicaStorage<T>)?,
        fetcher: @Sendable @escaping () async throws -> T
    ) {
        self.name = name
        self.settings = settings
        self.storage = storage
        self.dataFetcher = fetcher

        let observingState = SingleReplicaObservingState(
            observerIds: [],
            activeObserverIds: [],
            lastObservingTime: .never
        )
        self.currentState = SingleReplicaState(
            loading: false,
            data: nil,
            error: nil,
            observingState: observingState
        )
    }

    public func observe(activityStream: AsyncStream<Bool>) async -> SingleReplicaObserver<T> {
        let stateStreamBundle = AsyncStream<SingleReplicaState<T>>.makeStream()

        let observer = await SingleReplicaObserver<T>(
            activityStream: activityStream,
            stateStream: stateStreamBundle.stream,
        )

        observerStateStreams[observer.observerId] = stateStreamBundle

        Task {
            for await event in observer.eventStream {
                await handleObserverEvent(event, observerId: observer.observerId)
            }
        }

        return observer
    }

    public func refresh() async {
        await setLoadingStateAndLoadData(skipLoadingIfFresh: false)
    }

    public func revalidate() async {
        await setLoadingStateAndLoadData(skipLoadingIfFresh: true)
    }

    private func cancel() async {
        guard currentState.loading else { return }
        loadingTask?.cancel()
        var updatedState = currentState
        updatedState.loading = false
        await updateState(updatedState)
    }

    private func emitObserverCountChangedIfNeeded(
        from previousState: SingleReplicaObservingState,
        to newState: SingleReplicaObservingState
    ) async {
        guard
            previousState.observerIds.count != newState.observerIds.count
            || previousState.activeObserverIds.count != newState.activeObserverIds.count
        else {
            return
        }

        var updatedState = currentState
        updatedState.observingState = newState
        await updateState(updatedState)

        guard
            newState.activeObserverIds.count > previousState.activeObserverIds.count,
            settings.revalidateOnActiveObserverAdded
        else {
            return
        }

        await revalidate()
    }

    private func setLoadingStateAndLoadData(skipLoadingIfFresh: Bool) async {
        guard !currentState.loading, !(skipLoadingIfFresh && (currentState.data?.isFresh ?? false)) else {
            return
        }

        var updatedState = currentState
        updatedState.loading = true
        updatedState.error = nil

        await updateState(updatedState)

        loadingTask?.cancel()
        loadingTask = Task { [weak self] in await self?.loadData() }
    }

    private func loadData() async {
        MUNLogger.shared?.log(type: .debug, "🔄 \(name) \(#function)")

        do {
            let data: T

            if let storage, let dataFromStorage = try await storage.read() {
                data = dataFromStorage
            } else {
                data = try await dataFetcher()

                if let storage = storage {
                    try await storage.write(data: data)
                }
            }

            let replicaData = SingleReplicaStateData(value: data, isFresh: true, changingDate: .now)

            var updatedState = currentState
            updatedState.loading = false
            updatedState.data = replicaData
            updatedState.error = nil

            await updateState(updatedState)

            let staleTime = settings.staleTime
            guard staleTime < .infinity else {
                return
            }

            staleTask?.cancel()
            staleTask = Task { [weak self] in
                await self?.performDataStaling(after: staleTime)
            }
        } catch is CancellationError {
            return
        } catch {
            var updatedState = currentState
            updatedState.loading = false
            updatedState.error = error

            await updateState(updatedState)
        }
    }

    private func clearData() async throws {
        var updatedState = currentState
        updatedState.data = nil
        updatedState.error = nil
        await updateState(updatedState)
        try await storage?.remove()
    }

    private func updateState(_ newState: SingleReplicaState<T>) async {
        logStateChange(from: currentState, to: newState)
        currentState = newState
        observerStateStreams.forEach { $0.value.continuation.yield(currentState) }
    }

    private func performDataClearing(after seconds: TimeInterval) async {
        do { try await Task.sleep(for: .seconds(seconds)) } catch { return }

        let currentState = currentState

        guard
            (currentState.data != nil || currentState.error != nil),
            !currentState.loading,
            case .none = currentState.observingState.status
        else {
            return
        }

        try? await clearData()
    }

    private func performErrorClearing(after seconds: TimeInterval) async {
        do { try await Task.sleep(for: .seconds(seconds)) } catch { return }

        let currentState = currentState

        guard currentState.error != nil, !currentState.loading, case .none = currentState.observingState.status else {
            return
        }

        await clearError()
    }

    private func performCanceling(after seconds: TimeInterval) async {
        do { try await Task.sleep(for: .seconds(seconds)) } catch { return }

        let currentState = currentState

        guard currentState.loading, case .none = currentState.observingState.status else {
            return
        }

        await cancel()
    }

    private func performDataStaling(after seconds: TimeInterval) async {
        do { try await Task.sleep(for: .seconds(settings.staleTime)) } catch { return }

        guard let data = currentState.data, data.isFresh else {
            return
        }

        var newData = currentState.data
        newData?.isFresh = false
        var updatedState = currentState
        updatedState.data = newData
        await updateState(updatedState)
    }

    private func clearError() async {
        var updatedState = currentState
        updatedState.error = nil
        await updateState(updatedState)
    }

    private func logStateChange(from oldState: SingleReplicaState<T>, to newState: SingleReplicaState<T>) {
        var changes: [String] = []

        if oldState.loading != newState.loading {
            changes.append("loading: \(oldState.loading) → \(newState.loading)")
        }
        if oldState.data?.changingDate != newState.data?.changingDate {
            let oldValue: String
            if let oldData = oldState.data {
                oldValue = "present" + " since \(oldData.changingDate)"
            } else {
                oldValue = "absent"
            }

            let newValue: String
            if let newData = newState.data {
                newValue = "present" + " since \(newData.changingDate.description(with: .current))"
            } else {
                newValue = "absent"
            }

            changes.append("data: \(oldValue) → \(newValue)")
        }
        if oldState.error?.localizedDescription != newState.error?.localizedDescription {
            changes.append("error: \(oldState.error?.localizedDescription ?? "none") → \(newState.error?.localizedDescription ?? "none")")
        }
        if
            oldState.observingState.observerIds != newState.observingState.observerIds
            || oldState.observingState.activeObserverIds != newState.observingState.activeObserverIds
        {
            changes.append("observing: \(oldState.observingState) → \(newState.observingState)")
        }
        if
            let oldHasFreshData = oldState.data?.isFresh,
            let newHasFreshData = newState.data?.isFresh,
            oldHasFreshData != newHasFreshData
        {
            changes.append("hasFreshData: \(oldHasFreshData) → \(newHasFreshData)")
        }

        if changes.isEmpty {
            MUNLogger.shared?.log(type: .debug, "⚖️ \(name) \(#function): No changes in state")
        } else {
            MUNLogger.shared?.log(
                type: .debug,
                "⚖️ \(name) \(#function): Changed fields:\n  " + changes.joined(separator: "\n  ")
            )
        }
    }

    private func handleObserverEvent(_ event: SingleReplicaObserverEvent, observerId: UUID ) async {
        switch event {
        case .observerAdded:
            await handleObserverAdded(observerId: observerId)
        case .observerRemoved:
            await handleObserverRemoved(observerId: observerId)
        case .observerActivated:
            await handleObserverActivated(observerId: observerId)
        case .observerDeactivated:
            await handleObserverDeactivated(observerId: observerId)
        }
    }

    private func handleObserverAdded(observerId: UUID) async {
        [errorClearingTask, dataClearingTask, cancelTask].forEach { $0?.cancel() }

        let currentObservingState = currentState.observingState
        let newObservingState = SingleReplicaObservingState(
            observerIds: currentObservingState.observerIds.union([observerId]),
            activeObserverIds: currentObservingState.activeObserverIds,
            lastObservingTime: currentObservingState.lastObservingTime
        )

        await emitObserverCountChangedIfNeeded(from: currentObservingState, to: newObservingState)
    }

    private func handleObserverRemoved(observerId: UUID) async {
        observerStateStreams[observerId]?.continuation.finish()
        observerStateStreams[observerId] = nil

        let currentObservingState = currentState.observingState
        let isLastActive = currentObservingState.activeObserverIds.count == 1
            && currentObservingState.activeObserverIds.contains(observerId)
        let updatedlastObservingTime = isLastActive ? .timeInPast(.now) : currentObservingState.lastObservingTime
        let newObservingState = SingleReplicaObservingState(
            observerIds: currentObservingState.observerIds.subtracting([observerId]),
            activeObserverIds: currentObservingState.activeObserverIds.subtracting([observerId]),
            lastObservingTime: updatedlastObservingTime
        )

        await emitObserverCountChangedIfNeeded(from: currentObservingState, to: newObservingState)

        guard newObservingState.status == .none else {
            return
        }

        let cancelTime = settings.cancelTime
        if cancelTime < .infinity {
            cancelTask?.cancel()
            cancelTask = Task { [weak self] in await self?.performCanceling(after: cancelTime) }
        }

        let clearTime = settings.clearTime
        if clearTime < .infinity {
            dataClearingTask?.cancel()
            dataClearingTask = Task { [weak self] in await self?.performDataClearing(after: clearTime) }
        }

        let clearErrorTime = settings.clearErrorTime
        if clearErrorTime < .infinity {
            errorClearingTask?.cancel()
            errorClearingTask = Task { [weak self] in await self?.performErrorClearing(after: clearErrorTime) }
        }
    }

    private func handleObserverActivated(observerId: UUID) async {
        let currentObservingState = currentState.observingState
        var updatedActiveObserverIds = currentObservingState.activeObserverIds
        updatedActiveObserverIds.insert(observerId)
        let newObservingState = SingleReplicaObservingState(
            observerIds: currentObservingState.observerIds,
            activeObserverIds: updatedActiveObserverIds,
            lastObservingTime: .now
        )

        await emitObserverCountChangedIfNeeded(from: currentObservingState, to: newObservingState)
    }

    private func handleObserverDeactivated(observerId: UUID) async {
        let currentObservingState = currentState.observingState
        let isLastActive = currentObservingState.activeObserverIds.count == 1
            && currentObservingState.activeObserverIds.contains(observerId)
        let updatedlastObservingTime = isLastActive ? .timeInPast(.now) : currentObservingState.lastObservingTime
        let newObservingState = SingleReplicaObservingState(
            observerIds: currentObservingState.observerIds,
            activeObserverIds: currentObservingState.activeObserverIds.subtracting([observerId]),
            lastObservingTime: updatedlastObservingTime
        )

        await emitObserverCountChangedIfNeeded(from: currentObservingState, to: newObservingState)
    }
}

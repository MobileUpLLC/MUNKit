//
//  PhysicalReplicaImplementation.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

public actor PhysicalReplicaImplementation<T: Sendable>: PhysicalReplica {
    public let name: String

    private let storage: (any Storage<T>)?
    private let fetcher: @Sendable () async throws -> T
    private var currentReplicaState: ReplicaState<T>

    private var observerStateStreamBundles: [AsyncStreamBundle<ReplicaState<T>>] = []
    private var observerEventStreamBundles: [AsyncStreamBundle<ReplicaEvent<T>>] = []

    private let observersControllerStateStreamBundle: AsyncStreamBundle<ReplicaState<T>>
    private let observersControllerEventStreamBundle: AsyncStreamBundle<ReplicaEvent<T>>

    private let loadingControllerStateStreamBundle: AsyncStreamBundle<ReplicaState<T>>
    private let loadingControllerEventStreamBundle: AsyncStreamBundle<ReplicaEvent<T>>

    private let сlearingControllerStateStreamBundle: AsyncStreamBundle<ReplicaState<T>>
    private let сlearingControllerEventStreamBundle: AsyncStreamBundle<ReplicaEvent<T>>

    private let freshnessControllerStateStreamBundle: AsyncStreamBundle<ReplicaState<T>>
    private let freshnessControllerEventStreamBundle: AsyncStreamBundle<ReplicaEvent<T>>

    private let dataChangingControllerStateStreamBundle: AsyncStreamBundle<ReplicaState<T>>
    private let dataChangingControllerEventStreamBundle: AsyncStreamBundle<ReplicaEvent<T>>

    private let optimisticUpdatesControllerStateStreamBundle: AsyncStreamBundle<ReplicaState<T>>
    private let optimisticUpdatesControllerEventStreamBundle: AsyncStreamBundle<ReplicaEvent<T>>

    private let replicaObserversController: ReplicaObserversController<T>
    private let replicaLoadingController: ReplicaLoadingController<T>
    private let replicaClearingController: ReplicaClearingController<T>
    private let replicaFreshnessController: ReplicaFreshnessController<T>
    private let replicaDataChangingController: ReplicaDataChangingController<T>
    private let replicaOptimisticUpdatesController: ReplicaOptimisticUpdatesController<T>

    public init(storage: (any Storage<T>)?, fetcher: @Sendable @escaping () async throws -> T, name: String) {
        self.name = name
        self.storage = storage
        self.fetcher = fetcher
        self.currentReplicaState = ReplicaState<T>.createEmpty(hasStorage: storage != nil)
        self.observersControllerStateStreamBundle = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.observersControllerEventStreamBundle = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.loadingControllerStateStreamBundle = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.loadingControllerEventStreamBundle = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.сlearingControllerStateStreamBundle = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.сlearingControllerEventStreamBundle = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.freshnessControllerStateStreamBundle = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.freshnessControllerEventStreamBundle = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.dataChangingControllerStateStreamBundle = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.dataChangingControllerEventStreamBundle = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.optimisticUpdatesControllerStateStreamBundle = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.optimisticUpdatesControllerEventStreamBundle = AsyncStream.makeStream(of: ReplicaEvent<T>.self)

        self.replicaObserversController = ReplicaObserversController(
            replicaState: currentReplicaState,
            replicaStateStream: observersControllerStateStreamBundle.stream,
            replicaEventStreamContinuation: observersControllerEventStreamBundle.continuation
        )
        let dataLoader = DataLoader(storage: storage, fetcher: fetcher)
        self.replicaLoadingController = ReplicaLoadingController(
            replicaState: currentReplicaState,
            replicaStateStream: loadingControllerStateStreamBundle.stream,
            replicaEventStreamContinuation: loadingControllerEventStreamBundle.continuation,
            dataLoader: dataLoader
        )
        self.replicaClearingController = ReplicaClearingController(
            replicaStateStream: сlearingControllerStateStreamBundle.stream,
            replicaEventStreamContinuation: сlearingControllerEventStreamBundle.continuation,
            storage: storage
        )
        self.replicaFreshnessController = ReplicaFreshnessController(
            replicaState: currentReplicaState,
            replicaStateStream: freshnessControllerStateStreamBundle.stream,
            replicaEventStreamContinuation: freshnessControllerEventStreamBundle.continuation
        )
        self.replicaDataChangingController = ReplicaDataChangingController(
            replicaState: currentReplicaState,
            replicaStateStream: dataChangingControllerStateStreamBundle.stream,
            replicaEventStreamContinuation: dataChangingControllerEventStreamBundle.continuation,
            storage: storage
        )
        self.replicaOptimisticUpdatesController = ReplicaOptimisticUpdatesController(
            replicaState: currentReplicaState,
            replicaStateStream: optimisticUpdatesControllerStateStreamBundle.stream,
            replicaEventStreamContinuation: optimisticUpdatesControllerEventStreamBundle.continuation,
            storage: storage
            )

        Task {
            await processReplicaEvent()
        }
    }

    public func observe(observerActive: AsyncStream<Bool>) async -> ReplicaObserver<T> {
        let stateStreamPair = AsyncStream<ReplicaState<T>>.makeStream()
        observerStateStreamBundles.append(stateStreamPair)

        let eventStreamPair = AsyncStream<ReplicaEvent<T>>.makeStream()
        observerEventStreamBundles.append(eventStreamPair)

        return await ReplicaObserver<T>(
            observerActive: observerActive,
            replicaStateStream: stateStreamPair.stream,
            externalEventStream: eventStreamPair.stream,
            observersController: replicaObserversController
        )
    }

    public func refresh() async {
        await replicaLoadingController.refresh()
    }

    public func revalidate() async {
        await replicaLoadingController.revalidate()
    }

    public func getData(forceRefresh: Bool) async throws -> T {
        try await replicaLoadingController.getData(forceRefresh: forceRefresh)
    }

    public func clear(invalidationMode: InvalidationMode, removeFromStorage: Bool) async {
        await replicaLoadingController.cancel()
        try? await replicaClearingController.clear(removeFromStorage: removeFromStorage)
        Task {
            await replicaLoadingController.refreshAfterInvalidation(invalidationMode: invalidationMode)
        }
    }

    public func clearError() async {
        await replicaClearingController.clearError()
    }

    public func invalidate(mode: InvalidationMode) {
        Task {
            await replicaFreshnessController.invalidate()
            await replicaLoadingController.refreshAfterInvalidation(invalidationMode: mode)
        }
    }

    public func makeFresh() async {
        await replicaFreshnessController.makeFresh()
    }

    public func setData(data: T) async {
        try? await replicaDataChangingController.setData(data: data)
    }

    public func mutataData(transform: @escaping (T) -> T) {
        Task {
            try? await replicaDataChangingController.mutateData(transform: transform)
        }
    }

    func cancel() async {
        await replicaLoadingController.cancel()
    }
    
    private func processReplicaEvent() {
        Task {
            for await event in loadingControllerEventStreamBundle.stream {
                processReplicaEvent(event)
            }
        }

        Task {
            for await event in observersControllerEventStreamBundle.stream {
                processReplicaEvent(event)
            }
        }

        Task {
            for await event in сlearingControllerEventStreamBundle.stream {
                processReplicaEvent(event)
            }
        }

        Task {
            for await event in freshnessControllerEventStreamBundle.stream {
                processReplicaEvent(event)
            }
        }

        Task {
            for await event in dataChangingControllerEventStreamBundle.stream {
                processReplicaEvent(event)
            }
        }

        Task {
            for await event in optimisticUpdatesControllerEventStreamBundle.stream {
                processReplicaEvent(event)
            }
        }
    }

    private func updateState(_ newState: ReplicaState<T>) {
        print("💾 Replica \(self) обновила состояние: \(newState)")
        currentReplicaState = newState

        let allStateStreamPairs = observerStateStreamBundles
        + [
            loadingControllerStateStreamBundle,
            observersControllerStateStreamBundle,
            freshnessControllerStateStreamBundle,
            сlearingControllerStateStreamBundle,
            dataChangingControllerStateStreamBundle,
            optimisticUpdatesControllerStateStreamBundle
        ]

        allStateStreamPairs.forEach { $0.continuation.yield(currentReplicaState) }
    }

    private func processReplicaEvent(_ event: ReplicaEvent<T>) {
        print("\n⚡️ \(self) получено событие: \(event)")
        switch event {
        case .loading(let loadingEvent):
            handleLoadingEvent(loadingEvent)
        case .freshness(let freshnessEvent):
            handleFreshnessEvent(freshnessEvent)
        case .cleared:
            var replica = currentReplicaState
            replica.data = nil
            replica.error = nil
            replica.loadingFromStorageRequired = false

            updateState(replica)

        case .clearedError:
            var replica = currentReplicaState
            replica.error = nil

            updateState(replica)
        case .observerCountChanged(let observingState):
            let previousState = currentReplicaState
            let replica = currentReplicaState.copy(observingState: observingState)
            updateState(replica)

            print("🔍 \(self) изменилось количество наблюдателей: observerIds \(observingState.observerIds) activeObserverIds: \(observingState.activeObserverIds) observingTime \(observingState.observingTime)")

            if observingState.activeObserverIds.count > previousState.observingState.activeObserverIds.count {
                Task { await revalidate() }
            }
        case .changing(let changingEvent):
            handleChangingEvent(changingEvent)
        case .optimisticUpdates(let optimisticUpdateEvent):
            handleOptimisticUpdateEvent(optimisticUpdateEvent)
        }
    }

    private func handleOptimisticUpdateEvent(_ event: OptimisticUpdatesEvent<T>) {
        switch event {
        case .begin(data: let data):
            let replica = currentReplicaState.copy(data: data)
            updateState(replica)
        case .commit(data: let data):
            let replica = currentReplicaState.copy(data: data)
            updateState(replica)
        case .rollback(data: let data):
            let replica = currentReplicaState.copy(data: data)
            updateState(replica)
        }
    }

    private func handleChangingEvent(_ changingEvent: ChangingDataEvent<T>) {
        switch changingEvent {
        case .dataSetting(data: let data):
            let replica = currentReplicaState.copy(
                data: data,
                loadingFromStorageRequired: false
            )
            updateState(replica)
        case .dataMutating(data: let data):
            let replica = currentReplicaState.copy(
                data: data,
                loadingFromStorageRequired: false
            )
            updateState(replica)
        }
    }

    private func handleLoadingEvent(_ loadingEvent: LoadingEvent<T>) {
        switch loadingEvent {
        case .loadingStarted:
            var replica = currentReplicaState
            replica.loading = true
            replica.error = nil
            replica.dataRequested = true

            updateState(replica)

        case .dataFromStorageLoaded(let data):
            let replica = currentReplicaState.copy(
                data: data,
                loadingFromStorageRequired: false
            )
            updateState(replica)

        case .loadingFinished(let event):
            handleLoadingFinishedEvent(event)
        }
    }

    private func handleFreshnessEvent(_ freshnessEvent: FreshnessEvent) {
        switch freshnessEvent {
        case .freshened:
            var replica = currentReplicaState
            replica.data?.isFresh = true

            updateState(replica)
        case .becameStale:
            var replica = currentReplicaState
            replica.data?.isFresh = false

            updateState(replica)
        }
    }

    private func handleLoadingFinishedEvent(_ event: LoadingFinished<T>) {
        switch event {
        case .success(let data):
            var replica = currentReplicaState
            replica.loading = false
            replica.data = data
            replica.error = nil
            replica.dataRequested = false
            replica.preloading = false

            updateState(replica)

        case .canceled:
            let replica = currentReplicaState.copy(
                loading: false,
                dataRequested: false,
                preloading: false
            )
            updateState(replica)

        case .error(let error):
            let replica = currentReplicaState.copy(
                loading: false,
                error: error,
                dataRequested: false,
                preloading: false
            )
            updateState(replica)
        }
    }

    func beginOptimisticUpdate(_ update: any OptimisticUpdate<T>) async {
        await replicaOptimisticUpdatesController.beginOptimisticUpdate(update: update)
    }

    func commitOptimisticUpdate(_ update: any OptimisticUpdate<T>) async {
        await replicaOptimisticUpdatesController.commitOptimisticUpdate(update: update)
    }

    func rollbackOptimisticUpdate(_ update: any OptimisticUpdate<T>) async {
        await replicaOptimisticUpdatesController.rollbackOptimisticUpdate(update: update)
    }

    public func withOptimisticUpdate(
            update: any OptimisticUpdate<T>,
            onSuccess: (@Sendable () async -> Void)? = nil,
            onError: (@Sendable (Error) async -> Void)? = nil,
            onCanceled: (@Sendable () async -> Void)? = nil,
            onFinished: (@Sendable () async -> Void)? = nil,
            block: @escaping @Sendable () async throws -> T
        ) async throws -> T {
            await beginOptimisticUpdate(update)

            do {
                let result = try await block()

                await commitOptimisticUpdate(update)

                if let onSuccess {
                    await onSuccess()
                }

                if let onFinished {
                    await onFinished()
                }

                return result
            } catch {
                await rollbackOptimisticUpdate(update)

                if let onError {
                    await onError(error)
                }

                if let onFinished {
                    await onFinished()
                }

                throw error
            }
        }
}

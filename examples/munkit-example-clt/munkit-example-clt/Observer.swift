//
//  Observer.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 16.04.2025.
//

import munkit
import munkit_example_core

actor Observer: Sendable {
    var activityStreams: [AsyncStreamBundle<Bool>] = []

    private let name: String
    private let monstersListReplica: any SingleReplica<DNDMonstersListModel>
    private let monstersReplica: any KeyedReplica<String, DNDMonsterModel>
    private var observingMonstersListReplicaStateTask: Task<Void, Never>?
    private var observingMonstersReplicaStateTask: Task<Void, Never>?
    private let keyStreamBundle: AsyncStreamBundle<String>

    init(
        name: String,
        monstersListReplica: any SingleReplica<DNDMonstersListModel>,
        monstersReplica: any KeyedReplica<String, DNDMonsterModel>
    ) async {
        self.name = name
        self.monstersListReplica = monstersListReplica
        self.monstersReplica = monstersReplica
        self.keyStreamBundle = AsyncStream<String>.makeStream()

        let monstersListActivityStreamBundle = AsyncStream<Bool>.makeStream()
        activityStreams.append(monstersListActivityStreamBundle)
        self.observingMonstersListReplicaStateTask = Task {
            for await state in await monstersListReplica.observe(
                activityStream: monstersListActivityStreamBundle.stream
            ).stateStream {
                await handleNewMonstersListState(state)
            }
        }

        let monstersActivityStreamBundle = AsyncStream<Bool>.makeStream()
        activityStreams.append(monstersActivityStreamBundle)
        self.observingMonstersReplicaStateTask = Task {
            for await state in await monstersReplica
                .observe(activityStream: monstersActivityStreamBundle.stream, keyStream: keyStreamBundle.stream)
                .stateStream { await handleNewMonstersState(state) }
        }
    }

    deinit {
        print("🗑️", name, #function)
    }

    func stopObserving() async {
        observingMonstersListReplicaStateTask?.cancel()
        observingMonstersListReplicaStateTask = nil
        observingMonstersReplicaStateTask?.cancel()
        observingMonstersReplicaStateTask = nil

        activityStreams.forEach { $0.continuation.finish() }
    }

    private func handleNewMonstersListState(_ state: SingleReplicaState<DNDMonstersListModel>) async {
        guard let data = state.data else { return }

        try? await Task.sleep(for: .seconds(1))
        keyStreamBundle.continuation.yield(data.value.results[0].index)

        try? await Task.sleep(for: .seconds(2))
        keyStreamBundle.continuation.yield(data.value.results[1].index)

        try? await Task.sleep(for: .seconds(2))
        keyStreamBundle.continuation.yield(data.value.results[0].index)

        try? await Task.sleep(for: .seconds(3))
        keyStreamBundle.continuation.yield(data.value.results[2].index)

        try? await Task.sleep(for: .seconds(3))
        keyStreamBundle.continuation.yield(data.value.results[3].index)
    }

    private func handleNewMonstersState(_ state: SingleReplicaState<DNDMonsterModel>) async {
        print("🦖")
    }
}

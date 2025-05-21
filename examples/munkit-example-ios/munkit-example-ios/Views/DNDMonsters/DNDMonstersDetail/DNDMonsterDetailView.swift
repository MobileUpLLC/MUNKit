//
//  DNDMonsterDetailView.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 15.05.2025.
//

import SwiftUI
import munkit
import munkit_example_core

struct DNDMonsterDetailView: View {
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(DNDMonstersRepository.self) private var dndMonstersRepository

    @State private var replicaState: SingleReplicaState<DNDMonsterModel>?
    @State private var replicaSetupped = false

    private let monsterIndexStream: AsyncStreamBundle<String>

    private let activityStream = AsyncStream<Bool>.makeStream()
    private let monsterIndex: String

    init(monsterIndex: String) {
        self.monsterIndex = monsterIndex
        self.monsterIndexStream = AsyncStream<String>.makeStream()
    }

    var body: some View {
        ReplicaStateView(
            replicaState: replicaState,
            refreshAction: {
                await dndMonstersRepository.getDNDMonstersReplica().revalidate(key: monsterIndex)
            },
            content: { DataView(monster: $0) }
        )
        .navigationTitle(replicaState?.data?.value.name ?? "Monster Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !replicaSetupped else {
                activityStream.continuation.yield(true)
                return
            }

            replicaSetupped = true

            navigationModel.performActionAfterPop {
                activityStream.continuation.finish()
                monsterIndexStream.continuation.finish()
            }

            Task {
                let observer = await dndMonstersRepository
                    .getDNDMonstersReplica()
                    .observe(activityStream: activityStream.stream, keyStream: monsterIndexStream.stream)

                activityStream.continuation.yield(true)
                monsterIndexStream.continuation.yield(monsterIndex)

                for await state in await observer.stateStream {
                    replicaState = state
                }
            }
        }
        .onDisappear {
            activityStream.continuation.yield(false)
        }
    }
}

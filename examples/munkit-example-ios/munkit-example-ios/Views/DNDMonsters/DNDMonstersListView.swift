//
//  DNDMonstersListView.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 29.04.2025.
//

import SwiftUI
import munkit
import munkit_example_core

struct DNDMonstersListView: View {
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(DNDMonstersRepository.self) private var dndMonstersRepository

    @State private var replicaState: SingleReplicaState<DNDMonstersListModel>?
    @State private var replicaSetupped = false

    private let activityStream = AsyncStream<Bool>.makeStream()

    var body: some View {
        ReplicaStateView(
            replicaState: replicaState,
            refreshAction: { await dndMonstersRepository.getDNDMonstersListReplica().revalidate() },
            content: { data in
                List {
                    ForEach(data.results, id: \.index) { monster in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(monster.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                            }
                            Spacer()
                        }
                        .padding()
                        .contentShape(Rectangle())
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemBackground))
                                .padding(.vertical, 2)
                        )
                        .onTapGesture {
                            navigationModel.path.append(Destination.dndMonsters(.dndMonster(monster.index)))
                        }
                    }
                }
                .listStyle(.plain)
            }
        )
        .navigationTitle("D&D Monsters")
        .onAppear {
            guard !replicaSetupped else {
                activityStream.continuation.yield(true)
                return
            }
            replicaSetupped = true

            Task {
                navigationModel.performActionAfterPop { activityStream.continuation.finish() }

                let observer = await dndMonstersRepository.getDNDMonstersListReplica().observe(
                    activityStream: activityStream.stream
                )
                activityStream.continuation.yield(true)

                for await state in await observer.stateStream {
                    replicaState = state
                }
            }
        }
        .onDisappear { activityStream.continuation.yield(false) }
    }
}

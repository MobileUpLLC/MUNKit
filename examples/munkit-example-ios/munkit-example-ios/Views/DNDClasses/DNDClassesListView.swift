//
//  DNDClassesListView.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 29.04.2025.
//

import SwiftUI
import munkit
import munkit_example_core

struct DNDClassesListView: View {
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(DNDClassesRepository.self) private var dndClassesRepository

    @State private var replicaState: SingleReplicaState<DNDClassesListModel>?
    @State private var replicaSetupped = false

    private let activityStream = AsyncStream<Bool>.makeStream()

    var body: some View {
        ReplicaStateView(
            replicaState: replicaState,
            refreshAction: {
                await dndClassesRepository.getDNDClassesListReplica().revalidate()
            },
            content: { data in
                List {
                    ForEach(data.results, id: \.index) { dndClass in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dndClass.name)
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
                    }
                }
                .listStyle(.plain)
            }
        )
        .navigationTitle("D&D Classes")
        .onAppear {
            guard !replicaSetupped else {
                activityStream.continuation.yield(true)
                return
            }

            replicaSetupped = true

            Task {
                navigationModel.performActionAfterPop { activityStream.continuation.finish() }

                let observer = await dndClassesRepository.getDNDClassesListReplica().observe(
                    activityStream: activityStream.stream
                )
                activityStream.continuation.yield(true)

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

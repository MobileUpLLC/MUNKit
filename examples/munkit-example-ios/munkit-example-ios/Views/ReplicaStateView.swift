//
//  ReplicaStateView.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 15.05.2025.
//

import SwiftUI

import munkit

struct ReplicaStateView<T: Sendable, Content: View>: View {
    let replicaState: SingleReplicaState<T>?
    let refreshAction: () async -> Void
    let content: (T) -> Content

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            switch replicaState {
            case .some(let state) where state.loading && state.data == nil:
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                    Text("Loading...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            case .some(let state) where state.error != nil:
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.system(size: 40))
                    Text("Error Loading Data")
                        .font(.headline)
                    Text(state.error?.localizedDescription ?? "Unknown error")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry") {
                        Task { await refreshAction() }
                    }
                    .buttonStyle(.borderedProminent)
                }
            case .some(let state) where state.data != nil:
                if let data = state.data?.value {
                    VStack {
                        content(data)
                            .refreshable {
                                await refreshAction()
                            }
                    }
                    .overlay {
                        if !(state.data?.isFresh ?? false) {
                            VStack {
                                Text("Data may be outdated")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(8)
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                Spacer()
                            }
                            .padding(.top, 8)
                        }
                    }
                }
            default:
                EmptyView()
            }
        }
    }
}

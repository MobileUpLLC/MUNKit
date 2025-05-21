//
//  DNDMonstersRepository.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit

public actor DNDMonstersRepository {
    private let networkService: NetworkService
    private var dndMonstersListReplica: (any SingleReplica<DNDMonstersListModel>)?
    private var dndMonstersReplica: (any KeyedReplica<String, DNDMonsterModel>)?

    public init(networkService: NetworkService) {
        self.networkService = networkService
    }

    public func getDNDMonstersListReplica() async -> any SingleReplica<DNDMonstersListModel> {
        guard let dndMonstersListReplica else {
            await createDNDMonstersListReplica()
            return await getDNDMonstersListReplica()
        }
        return dndMonstersListReplica
    }

    public func getDNDMonstersReplica() async -> any KeyedReplica<String, DNDMonsterModel> {
        guard let dndMonstersReplica else {
            await createDNDMonstersReplica()
            return await getDNDMonstersReplica()
        }
        return dndMonstersReplica
    }

    private func createDNDMonstersListReplica() async {
        self.dndMonstersListReplica = await ReplicasHolder.shared.getSingleReplica(
            name: "DNDMonstersListReplica",
            settings: .init(
                staleTime: 60,
                clearTime: 5,
                clearErrorTime: 1,
                cancelTime: 0.05,
                revalidateOnActiveObserverAdded: true
            ),
            storage: nil,
            fetcher: { [weak self] in
                guard let networkService = self?.networkService else {
                    throw CancellationError()
                }
                return try await networkService.executeRequest(target: .monsters(challengeRatings: nil))
            }
        )
    }

    private func createDNDMonstersReplica() async {
        self.dndMonstersReplica = await ReplicasHolder.shared.getKeydReplica(
            name: "DNDMonstersReplica",
            childNameFacroty: { "DNDMonstersChildReplica-\($0)" },
            childSettingsFactory: { _ in
                SingleReplicaSettings(
                    staleTime: 60,
                    clearTime: 60,
                    clearErrorTime: 5,
                    cancelTime: 10,
                    revalidateOnActiveObserverAdded: true
                )
            },
            settings: KeyedReplicaSettings(
                maxCount: 2,
                childRemovingPolicy: .byObservingTime
            ),
            fetcher: { [weak self] key in
                guard let networkService = self?.networkService else {
                    throw CancellationError()
                }
                return try await networkService.executeRequest(target: .monster(key))
            }
        )
    }
}

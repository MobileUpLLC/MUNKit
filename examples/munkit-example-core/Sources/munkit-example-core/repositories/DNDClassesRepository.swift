//
//  DNDClassesRepository.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit

public actor DNDClassesRepository {
    private let networkService: NetworkService

    public var dndClassesListReplica: (any SingleReplica<DNDClassesListModel>)?

    public init(networkService: NetworkService) {
        self.networkService = networkService
    }

    public func getDNDClassesListReplica() async -> any SingleReplica<DNDClassesListModel> {
        guard let dndClassesListReplica else {
            await createDNDClassesListReplica()
            return await getDNDClassesListReplica()
        }
        return dndClassesListReplica
    }

    private func createDNDClassesListReplica() async {
        self.dndClassesListReplica = await ReplicasHolder.shared.getSingleReplica(
            name: "DNDClassesListReplica",
            settings: .init(
                staleTime: 10,
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
                return try await networkService.executeRequest(target: .classes)
            }
        )
    }
}

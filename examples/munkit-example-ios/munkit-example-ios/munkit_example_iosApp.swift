//
//  munkit_example_iosApp.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 29.04.2025.
//

import SwiftUI
import munkit
import munkit_example_core

@main
struct munkit_example_iosApp: App {
    let navigationModel = NavigationModel()
    let dndClassesRepository: DNDClassesRepository
    let dndMonstersRepository: DNDMonstersRepository

    init() {
        let networkService = NetworkService(plugins: [MUNLoggerPlugin.instance])
        self.dndClassesRepository = DNDClassesRepository(networkService: networkService)
        self.dndMonstersRepository = DNDMonstersRepository(networkService: networkService)
    }

    var body: some Scene {
        WindowGroup {
            @Bindable var navigationModel = navigationModel
            NavigationStack(path: $navigationModel.path) {
                FirstView()
                    .navigationDestination(for: Destination.self) {
                        switch $0 {
                        case .dndClasses(let destination):
                            switch destination {
                            case .dndClassesList:
                                DNDClassesListView()
                            }
                        case .dndMonsters(let destination):
                            switch destination {
                            case .dndMonstersList:
                                DNDMonstersListView()
                            case .dndMonster(let index):
                                DNDMonsterDetailView(monsterIndex: index)
                            }
                        }
                    }
            }
            .environment(dndClassesRepository)
            .environment(dndMonstersRepository)
            .environment(navigationModel)
            .onAppear { MUNLogger.setupLogger(Logger()) }
        }
    }
}

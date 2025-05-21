//
//  Destination.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 30.04.2025.
//

enum Destination: Hashable {
    case dndClasses(DNDClassesDestination)
    case dndMonsters(DNDMonstersDestination)
}

enum DNDClassesDestination: Hashable {
    case dndClassesList
}

enum DNDMonstersDestination: Hashable {
    case dndMonster(String)
    case dndMonstersList
}

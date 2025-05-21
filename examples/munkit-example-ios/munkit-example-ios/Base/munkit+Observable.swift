//
//  munkit.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 30.04.2025.
//

import SwiftUI
import munkit_example_core

extension NetworkService: @retroactive Observable {}
extension DNDClassesRepository: @retroactive Observable {}
extension DNDMonstersRepository: @retroactive Observable {}

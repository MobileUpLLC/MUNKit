//
//  DNDMonsterDetailDataStatView.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 16.05.2025.
//

import SwiftUI

extension DNDMonsterDetailView.DataView {
    struct StatView: View {
        let title: String
        let value: String

        var body: some View {
            VStack {
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
                Text(value)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

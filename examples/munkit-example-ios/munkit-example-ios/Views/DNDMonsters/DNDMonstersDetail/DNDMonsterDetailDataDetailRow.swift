//
//  DNDMonsterDetailDataDetailRow.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 16.05.2025.
//

import SwiftUI

extension DNDMonsterDetailView.DataView {
    struct DetailRow: View {
        let title: String
        let value: String

        var body: some View {
            if !value.isEmpty {
                HStack(alignment: .top) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(width: 150, alignment: .leading)
                    Text(value)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
            }
        }
    }
}

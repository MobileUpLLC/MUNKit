//
//  FirstView.swift
//  munkit-example-ios
//
//  Created by Ilia Chub on 30.04.2025.
//

import SwiftUI

struct FirstView: View {
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            VStack {
                LinkButton(title: "D&D Classes List", value: .dndClasses(.dndClassesList))
                LinkButton(title: "D&D Monsters List", value: .dndMonsters(.dndMonstersList))
            }
        }
        .navigationTitle("munkit Example iOS")

    }
}

private struct LinkButton: View {
    let title: String
    let value: Destination

    var body: some View {
        NavigationLink(title, value: value)
            .foregroundStyle(.black)
            .font(.system(size: 20, weight: .bold))
            .padding()
            .background {
                Capsule()
                    .fill(.thinMaterial)
                    .stroke(.black, lineWidth: 1)
            }
    }
}

#Preview {
    FirstView()
}

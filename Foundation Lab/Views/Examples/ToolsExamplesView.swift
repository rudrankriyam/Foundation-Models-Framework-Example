//
//  ToolsExamplesView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI

struct ToolsExamplesView: View {
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(minimum: 150), spacing: 16),
            GridItem(.flexible(minimum: 150), spacing: 16)
        ], spacing: 16) {
            ForEach(ToolExample.allCases, id: \.self) { tool in
                NavigationLink(value: tool) {
                    GenericCardView(
                        icon: tool.icon,
                        title: tool.displayName,
                            subtitle: tool.shortDescription
                        )
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .navigationTitle("Tools")
#if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .navigationDestination(for: ToolExample.self) { tool in
            tool.destination
        }
    }
}

#Preview {
    NavigationStack {
        ToolsExamplesView()
    }
}

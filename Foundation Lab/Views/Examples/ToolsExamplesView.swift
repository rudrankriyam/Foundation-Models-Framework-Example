//
//  ToolsExamplesView.swift
//  FoundationLab
//
//  Created by Assistant on 7/8/25.
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
                    NavigationLink(destination: tool.createView()) {
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
    }
}

#Preview {
    NavigationStack {
        ToolsExamplesView()
    }
}

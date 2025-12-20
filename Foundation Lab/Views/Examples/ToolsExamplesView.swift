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
                    NavigationLink(destination: Self.toolView(for: tool)) {
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

extension ToolsExamplesView {
    @ViewBuilder
    private static func toolView(for tool: ToolExample) -> some View {
        switch tool {
        case .weather:
            WeatherToolView()
        case .web:
            WebToolView()
        case .contacts:
            ContactsToolView()
        case .calendar:
            CalendarToolView()
        case .reminders:
            RemindersToolView()
        case .location:
            LocationToolView()
        case .health:
            HealthToolView()
        case .music:
            MusicToolView()
        case .webMetadata:
            WebMetadataToolView()
        }
    }
}

#Preview {
    NavigationStack {
        ToolsExamplesView()
    }
}

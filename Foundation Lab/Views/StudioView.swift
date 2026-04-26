//
//  StudioView.swift
//  FoundationLab
//
//  Created by Codex on 4/26/26.
//

import SwiftUI

struct StudioView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xLarge) {
                examplesSection
                toolsSection
                schemasSection
                languagesSection
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
        }
        .navigationTitle("Studio")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .navigationDestination(for: ExampleType.self) { exampleType in
            exampleType.destination
        }
        .navigationDestination(for: ToolExample.self) { tool in
            tool.destination
        }
        .navigationDestination(for: DynamicSchemaExampleType.self) { example in
            example.destination
        }
        .navigationDestination(for: LanguageExample.self) { languageExample in
            languageExample.destination
        }
    }

    private var examplesSection: some View {
        StudioSection(
            title: "Model Controls",
            subtitle: "Generation options, guides, and structured output."
        ) {
            ForEach(ExampleType.studioExamples) { exampleType in
                NavigationLink(value: exampleType) {
                    GenericCardView(
                        icon: exampleType.icon,
                        title: exampleType.title,
                        subtitle: exampleType.subtitle
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var toolsSection: some View {
        StudioSection(
            title: "Tools",
            subtitle: "System capabilities the model can call."
        ) {
            ForEach(ToolExample.allCases, id: \.self) { tool in
                NavigationLink(value: tool) {
                    GenericCardView(
                        icon: tool.icon,
                        title: tool.displayName,
                        subtitle: tool.shortDescription
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var schemasSection: some View {
        StudioSection(
            title: "Dynamic Schemas",
            subtitle: "Build and validate generation schemas."
        ) {
            ForEach(DynamicSchemaExampleType.allCases) { example in
                NavigationLink(value: example) {
                    GenericCardView(
                        icon: example.icon,
                        title: example.title,
                        subtitle: example.subtitle
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var languagesSection: some View {
        StudioSection(
            title: "Languages",
            subtitle: "Detect, select, and manage multilingual sessions."
        ) {
            ForEach(LanguageExample.allCases) { languageExample in
                NavigationLink(value: languageExample) {
                    GenericCardView(
                        icon: languageExample.icon,
                        title: languageExample.title,
                        subtitle: languageExample.subtitle
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct StudioSection<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader(title: title, subtitle: subtitle)

            LazyVGrid(columns: adaptiveGridColumns, spacing: Spacing.large) {
                content
            }
        }
    }

    private var adaptiveGridColumns: [GridItem] {
#if os(iOS)
        [
            GridItem(.flexible(minimum: 140), spacing: Spacing.large),
            GridItem(.flexible(minimum: 140), spacing: Spacing.large)
        ]
#else
        [GridItem(.adaptive(minimum: 240), spacing: Spacing.large)]
#endif
    }
}

#Preview {
    NavigationStack {
        StudioView()
    }
}

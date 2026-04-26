//
//  StudioView.swift
//  FoundationLab
//
//  Created by Codex on 4/26/26.
//

import SwiftUI

struct StudioView: View {
    @State private var searchText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xLarge) {
                if hasResults {
                    examplesSection
                    toolsSection
                    schemasSection
                    languagesSection
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
        }
        .navigationTitle("Studio")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .searchable(text: $searchText, prompt: "Search Studio")
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
            ForEach(filteredStudioExamples) { exampleType in
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
            ForEach(filteredTools, id: \.self) { tool in
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
            ForEach(filteredSchemas) { example in
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
            ForEach(filteredLanguages) { languageExample in
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

    private var filteredStudioExamples: [ExampleType] {
        ExampleType.studioExamples.filter { matches($0.title, $0.subtitle) }
    }

    private var filteredTools: [ToolExample] {
        ToolExample.allCases.filter { matches($0.displayName, $0.shortDescription) }
    }

    private var filteredSchemas: [DynamicSchemaExampleType] {
        DynamicSchemaExampleType.allCases.filter { matches($0.title, $0.subtitle) }
    }

    private var filteredLanguages: [LanguageExample] {
        LanguageExample.allCases.filter { matches($0.title, $0.subtitle) }
    }

    private var hasResults: Bool {
        !filteredStudioExamples.isEmpty ||
        !filteredTools.isEmpty ||
        !filteredSchemas.isEmpty ||
        !filteredLanguages.isEmpty
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func matches(_ title: String, _ subtitle: String) -> Bool {
        let query = trimmedSearchText
        guard !query.isEmpty else { return true }

        return title.localizedStandardContains(query) ||
        subtitle.localizedStandardContains(query)
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

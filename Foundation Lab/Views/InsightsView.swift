//
//  InsightsView.swift
//  FoundationLab
//
//  Created by Codex on 4/26/26.
//

import SwiftUI

struct InsightsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xLarge) {
                SectionHeader(
                    title: "Applied Intelligence",
                    subtitle: "Production-shaped demos powered by the same model stack."
                )

                LazyVGrid(columns: adaptiveGridColumns, spacing: Spacing.large) {
                    ForEach(ExampleType.insightExamples) { exampleType in
                        NavigationLink(value: exampleType) {
                            GenericCardView(
                                icon: exampleType.icon,
                                title: exampleType.title,
                                subtitle: exampleType.subtitle
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    NavigationLink(value: LanguageExample.productionExample) {
                        GenericCardView(
                            icon: LanguageExample.productionExample.icon,
                            title: LanguageExample.productionExample.title,
                            subtitle: LanguageExample.productionExample.subtitle
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
        }
        .navigationTitle("Insights")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .navigationDestination(for: ExampleType.self) { exampleType in
            exampleType.destination
        }
        .navigationDestination(for: LanguageExample.self) { languageExample in
            languageExample.destination
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
        InsightsView()
    }
}

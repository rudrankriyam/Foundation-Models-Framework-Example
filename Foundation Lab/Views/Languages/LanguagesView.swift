//
//  LanguagesView.swift
//  FoundationLab
//
//  Created by Assistant on 12/30/25.
//

import SwiftUI
import FoundationModels

struct LanguagesView: View {
    @Namespace private var glassNamespace

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                LazyVGrid(columns: adaptiveGridColumns, spacing: Spacing.large) {
                    ForEach(LanguageExample.allCases) { languageExample in
                        NavigationLink(value: languageExample) {
                            GenericCardView(
                                icon: languageExample.icon,
                                title: languageExample.title,
                                subtitle: languageExample.subtitle
                            )
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.medium)
            }
            .padding(.vertical)
        }
        .navigationTitle("Supported Languages")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .navigationDestination(for: LanguageExample.self) { languageExample in
            languageExample.createView()
        }
    }

    private var adaptiveGridColumns: [GridItem] {
#if os(iOS)
        // iPhone: 2 columns with flexible sizing and better spacing
        return [
            GridItem(.flexible(minimum: 140), spacing: Spacing.large),
            GridItem(.flexible(minimum: 140), spacing: Spacing.large)
        ]
#elseif os(macOS)
        // Mac: Adaptive columns based on available width
        return Array(repeating: GridItem(.adaptive(minimum: 280), spacing: Spacing.large), count: 1)
#else
        // Default fallback for other platforms
        return [
            GridItem(.flexible(minimum: 140), spacing: Spacing.large),
            GridItem(.flexible(minimum: 140), spacing: Spacing.large)
        ]
#endif
    }
}

#Preview {
    NavigationStack {
        LanguagesView()
    }
}

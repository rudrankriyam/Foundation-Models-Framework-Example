//
//  LanguageDetectionView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 21/10/2025.
//

import SwiftUI
import FoundationModels

struct LanguageDetectionView: View {
    @Environment(LanguageService.self) private var languageService
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                descriptionSection

                Button("Refresh Supported Languages") {
                    Task {
                        await languageService.loadSupportedLanguages()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(languageService.isLoading)
                .padding(.horizontal)

                if languageService.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading languages...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }

                if let errorMessage = languageService.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                if !languageService.supportedLanguages.isEmpty {
                    languageListSection
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Language Detection")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .background(TopGradientView())
#endif
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            CodeViewer(
                code: """
let model = SystemLanguageModel.default
let supported = model.supportedLanguages // [Locale.Language]

for language in supported {
    let code = language.languageCode?.identifier ?? ""
    let region = language.region?.identifier ?? ""

    let name = Locale.current.localizedString(forLanguageCode: code) ?? code
    let regionName = region.isEmpty ? nil :
        (Locale.current.localizedString(forRegionCode: region) ?? region)

    print(regionName != nil ? "\\(name) (\\(regionName!))" : "\\(name)")
}
"""
            )
        }
        .padding(.horizontal)
    }

    private var languageListSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Supported Languages (\(languageService.supportedLanguages.count))")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.small) {
                ForEach(languageService.supportedLanguages.indices, id: \.self) { index in
                    let language = languageService.supportedLanguages[index]
                    LanguageCard(language: language, languageService: languageService)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct LanguageCard: View {
    let language: Locale.Language
    let languageService: LanguageService

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(displayName)
                .font(.body)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private var displayName: String {
        return languageService.getDisplayName(for: language)
    }
}

#Preview {
    NavigationStack {
        LanguageDetectionView()
            .background(TopGradientView())
    }
    .environment(LanguageService())
}

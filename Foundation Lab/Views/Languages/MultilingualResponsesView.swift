//
//  MultilingualResponsesView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationLabCore

struct MultilingualResponsesView: View {
    @State private var isRunning = false
    @State private var results: [LanguagePromptResult] = []
    @State private var errorMessage: String?

    @Environment(LanguageService.self) private var languageService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                descriptionSection

                Button("Generate Multilingual Responses") {
                    Task {
                        await generateMultilingualResponses()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isRunning)
                .padding(.horizontal)

                if isRunning {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating responses...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                if !results.isEmpty {
                    resultsSection
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Multilingual Play")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {

            CodeViewer(
                code: """
import FoundationLabCore

let prompts: [LanguagePrompt] = [
    .init(name: "English", text: "What is the capital of France?"),
    .init(name: "Spanish", text: "¿Cuál es la capital de España?"),
    .init(name: "French", text: "Quelle est la capitale de l'Allemagne?"),
    .init(name: "German", text: "Was ist die Hauptstadt von Italien?")
]

for prompt in prompts {
    let result = try await GenerateTextUseCase().execute(
        TextGenerationRequest(
            prompt: prompt.text,
            context: CapabilityInvocationContext(source: .app)
        )
    )
    print("\\(prompt.name): \\(result.content)")
}
"""
            )
        }
        .padding(.horizontal)
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Generated Responses")
                .font(.headline)
                .padding(.horizontal)

            LazyVStack(spacing: Spacing.medium) {
                ForEach(results, id: \.language) { result in
                    LanguageResponseCard(result: result)
                }
            }
            .padding(.horizontal)
        }
    }

    @MainActor
    private func generateMultilingualResponses() async {
        isRunning = true
        errorMessage = nil
        results = []

        // Generate prompts dynamically based on supported languages
        var prompts: [LanguagePrompt] = []

        // Sample prompts for different languages (you can expand this)
        let promptTemplates: [String: String] = [
            "en": "What is the capital of France? Please provide a brief answer.",
            "es": "¿Cuál es la capital de España? Por favor, proporciona una respuesta breve.",
            "fr": "Quelle est la capitale de l'Allemagne ? Veuillez donner une réponse brève.",
            "de": "Was ist die Hauptstadt von Italien? Bitte geben Sie eine kurze Antwort.",
            "it": "Qual è la capitale del Portogallo? Per favore, fornisci una risposta breve.",
            "pt": "Qual é a capital do Brasil? Por favor, forneça uma resposta breve.",
            "zh": "中国的首都是什么？请简要回答。",
            "ja": "日本の首都は何ですか？簡潔にお答えください。",
            "ko": "한국의 수도는 어디인가요? 간단히 답해주세요."
        ]

        // Create prompts for supported languages that we have templates for
        for language in languageService.supportedLanguages {
            let code = language.languageCode
            if let promptText = promptTemplates[code] {
                let displayName = languageService.getDisplayName(for: language)
                prompts.append(LanguagePrompt(
                    language: displayName,
                    flag: "🌐",
                    text: promptText
                ))
            }
        }

        // If no supported languages found with templates, use fallback
        if prompts.isEmpty {
            prompts = [
                LanguagePrompt(language: "English", flag: "🌐",
                              text: "What is the capital of France? Please provide a brief answer.")
            ]
        }

        for prompt in prompts {
            do {
                let response = try await GenerateTextUseCase().execute(
                    TextGenerationRequest(
                        prompt: prompt.text,
                        context: CapabilityInvocationContext(
                            source: .app,
                            localeIdentifier: Locale.current.identifier
                        )
                    )
                )

                let result = LanguagePromptResult(
                    language: prompt.language,
                    flag: prompt.flag,
                    prompt: prompt.text,
                    response: response.content,
                    isError: false
                )

                results.append(result)
            } catch {
                let errorResult = LanguagePromptResult(
                    language: prompt.language,
                    flag: prompt.flag,
                    prompt: prompt.text,
                    response: "Error: \(error.localizedDescription)",
                    isError: true
                )

                results.append(errorResult)
            }
        }

        isRunning = false
    }
}

struct LanguagePrompt {
    let language: String
    let flag: String
    let text: String
}

struct LanguagePromptResult {
    let language: String
    let flag: String
    let prompt: String
    let response: String
    let isError: Bool
}

struct LanguageResponseCard: View {
    let result: LanguagePromptResult

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Text(result.flag)
                    .font(.title2)

                Text(result.language)
                    .font(.headline)
                    .fontWeight(.medium)

                Spacer()

                if result.isError {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("PROMPT")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(result.prompt)
                    .font(.body)
                    .padding(.bottom, Spacing.small)

                Text("RESPONSE")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(result.response)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(result.isError ? .red : .primary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        MultilingualResponsesView()
    }
    .environment(LanguageService())
}

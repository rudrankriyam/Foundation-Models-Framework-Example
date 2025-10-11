//
//  SessionManagementView.swift
//  FoundationLab
//
//  Created by Assistant on 12/30/25.
//

import SwiftUI
import FoundationModels

struct SessionManagementView: View {
    @State private var conversationResults: [ConversationStep] = []
    @State private var isRunning = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                descriptionSection

                Button("Start Multilingual Conversation") {
                    Task {
                        await startMultilingualConversation()
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
                        Text("Running conversation...")
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

                if !conversationResults.isEmpty {
                    conversationSection
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Multiple Sessions")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            CodeViewer(
                code: """
let session = LanguageModelSession(model: SystemLanguageModel.default)

// English interaction
let english = try await session.respond(to: "Hello, how are you?")

// Switch to Spanish in the same session
let spanish = try await session.respond(to: "Hola, ¿cómo estás?")

// Ask to switch back to English
let switchBack = try await session.respond(to: "Now answer in English please")

// Test context retention
let memory = try await session.respond(to: "What language did I first speak to you in?")
"""
            )
        }
        .padding(.horizontal)
    }

    private var conversationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Conversation Flow")
                .font(.headline)
                .padding(.horizontal)

            LazyVStack(spacing: Spacing.small) {
                ForEach(conversationResults.indices, id: \.self) { index in
                    ConversationStepCard(
                        step: conversationResults[index],
                        stepNumber: index + 1
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    @MainActor
    private func startMultilingualConversation() async {
        isRunning = true
        errorMessage = nil
        conversationResults = []

        let conversationSteps = [
            ("🌐 English", "Hello, how are you?"),
            ("🌐 Spanish", "Hola, ¿cómo estás?"),
            ("🌐 English", "Now answer in English please"),
            ("🧠 Memory", "What language did I first speak to you in?"),
            ("🔄 Switch", "Please respond in French from now on"),
            ("🌐 French", "Comment allez-vous aujourd'hui?"),
            ("🤝 Mixed", "Can you parler both English and French in your response?")
        ]

        // Create single persistent session
        let session = LanguageModelSession(
            model: SystemLanguageModel.default,
            instructions: "You are a multilingual assistant who can naturally switch between languages and maintain conversational context."
        )

        for (language, prompt) in conversationSteps {
            do {
                let response = try await session.respond(to: prompt)

                let step = ConversationStep(
                    language: language,
                    prompt: prompt,
                    response: response.content,
                    isError: false
                )

                conversationResults.append(step)
            } catch {
                let errorStep = ConversationStep(
                    language: language,
                    prompt: prompt,
                    response: "Error: \(error.localizedDescription)",
                    isError: true
                )

                conversationResults.append(errorStep)
            }
        }

        isRunning = false
    }
}

struct ConversationStep {
    let language: String
    let prompt: String
    let response: String
    let isError: Bool
}

struct ConversationStepCard: View {
    let step: ConversationStep
    let stepNumber: Int

    var body: some View {
        VStack(spacing: Spacing.medium) {
            HStack {
                Text("\(stepNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(.blue))

                Text(step.language)
                    .font(.headline)
                    .fontWeight(.medium)

                Spacer()

                if step.isError {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.medium) {
                // User message
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: Spacing.small) {
                        Text("You")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        Text(step.prompt)
                            .font(.body)
                            .padding(.horizontal, Spacing.medium)
                            .padding(.vertical, Spacing.small)
                            .background(.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(16)
                    }
                }

                // AI response
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Assistant")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        Text(step.response)
                            .font(.body)
                            .padding(.horizontal, Spacing.medium)
                            .padding(.vertical, Spacing.small)
                            .background(step.isError ? .red.opacity(0.1) : .gray.opacity(0.1))
                            .foregroundColor(step.isError ? .red : .primary)
                            .cornerRadius(16)
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
}

#Preview {
    NavigationStack {
        SessionManagementView()
            .background(TopGradientView())
    }
}

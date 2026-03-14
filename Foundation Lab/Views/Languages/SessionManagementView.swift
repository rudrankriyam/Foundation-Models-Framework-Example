//
//  SessionManagementView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationLabCore

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
import FoundationLabCore

let result = try await RunConversationUseCase().execute(
    RunConversationRequest(
        prompts: [
            "Hello, how are you?",
            "Hola, ¿cómo estás?",
            "Now answer in English please",
            "What language did I first speak to you in?"
        ],
        systemPrompt: "You are a multilingual assistant who can naturally switch between languages and maintain conversational context.",
        context: CapabilityInvocationContext(source: .app)
    )
)
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

        do {
            let result = try await RunConversationUseCase().execute(
                RunConversationRequest(
                    prompts: conversationSteps.map(\.1),
                    systemPrompt: "You are a multilingual assistant who can naturally switch between languages and maintain conversational context.",
                    context: CapabilityInvocationContext(
                        source: .app,
                        localeIdentifier: Locale.current.identifier
                    )
                )
            )

            conversationResults = zip(conversationSteps, result.exchanges).map { stepInfo, exchange in
                ConversationStep(
                    language: stepInfo.0,
                    prompt: exchange.prompt,
                    response: exchange.response,
                    isError: exchange.isError
                )
            }
        } catch {
            errorMessage = error.localizedDescription
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
    }
}

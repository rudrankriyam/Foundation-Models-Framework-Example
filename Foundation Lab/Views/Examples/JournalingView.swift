//
//  JournalingView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 1/27/26.
//

import FoundationLabCore
import SwiftUI

struct JournalingView: View {
    @State private var currentPrompt = FoundationLabExampleDemo.journaling.defaultPrompt
    @State private var executor = ExampleExecutor()

    var body: some View {
        ExampleViewBase(
            title: "Journaling",
            description: "Gentle prompts and reflective summaries",
            defaultPrompt: FoundationLabExampleDemo.journaling.defaultPrompt,
            currentPrompt: $currentPrompt,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: DefaultPrompts.journalingCode(prompt: currentPrompt),
            onRun: executeJournaling,
            onReset: resetToDefaults
        ) {
            VStack(spacing: 16) {
                // Info Banner
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.purple)
                    Text("Generates a prompt, uplifting message, starters, summary, and themes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)

                // Prompt Suggestions
                PromptSuggestions(
                    suggestions: FoundationLabExampleDemo.journaling.suggestions,
                    onSelect: { currentPrompt = $0 }
                )

                // Prompt History
                if !executor.promptHistory.isEmpty {
                    PromptHistory(
                        history: executor.promptHistory,
                        onSelect: { currentPrompt = $0 }
                    )
                }

                // Result Display
                if !executor.result.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Reflection", systemImage: "square.and.pencil")
                            .font(.headline)

                        ResultDisplay(
                            result: executor.result,
                            isSuccess: executor.errorMessage == nil,
                            tokenCount: executor.lastTokenCount
                        )
                    }
                }
            }
        }
    }

    private func executeJournaling() {
        Task {
            await executor.executeStructured(
                prompt: currentPrompt,
                type: JournalEntrySummary.self,
                instructions: FoundationLabExampleDemo.journaling.defaultSystemPrompt
            ) { summary in
                summary.plainTextSummary
            }
        }
    }

    private func resetToDefaults() {
        currentPrompt = "" // Clear the prompt completely
        executor.clearAll() // Clear all results, errors, and history
    }
}

#Preview {
    NavigationStack {
        JournalingView()
    }
}

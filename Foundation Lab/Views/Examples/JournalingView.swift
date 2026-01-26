//
//  JournalingView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 1/27/26.
//

import FoundationModels
import SwiftUI

struct JournalingView: View {
    @State private var currentPrompt = DefaultPrompts.journaling
    @State private var executor = ExampleExecutor()

    var body: some View {
        ExampleViewBase(
            title: "Journaling",
            description: "Gentle prompts and reflective summaries",
            defaultPrompt: DefaultPrompts.journaling,
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
                    Text("Generates a gentle prompt and a 3-bullet summary of the entry")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)

                // Prompt Suggestions
                PromptSuggestions(
                    suggestions: DefaultPrompts.journalingSuggestions,
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
                        Label("Prompt + Summary", systemImage: "square.and.pencil")
                            .font(.headline)

                        ResultDisplay(
                            result: executor.result,
                            isSuccess: executor.errorMessage == nil
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
                type: JournalEntrySummary.self
            ) { summary in
                formattedSummary(summary)
            }
        }
    }

    private func resetToDefaults() {
        currentPrompt = "" // Clear the prompt completely
        executor.clearAll() // Clear all results, errors, and history
    }
}

private extension JournalingView {
    func formattedSummary(_ summary: JournalEntrySummary) -> String {
        let bullets = summary.summaryBullets.map { "- \($0)" }.joined(separator: "\n")
        return """
        Prompt:
        \(summary.prompt)

        Summary:
        \(bullets)
        """
    }
}

#Preview {
    NavigationStack {
        JournalingView()
    }
}

//
//  ChatInstructionsView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI

struct ChatInstructionsView: View {
    @Binding var instructions: String
    @Binding var useGreedySampling: Bool
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Customize AI Behavior")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Provide specific instructions to guide how the AI should respond. These instructions will " +
                         "apply to all new conversations.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }

                // Greedy Sampling Section
                VStack(alignment: .leading, spacing: Spacing.small) {
                    HStack {
                        Text("Greedy Sampling")
                            .font(.headline)
                        Spacer()
                        Toggle("", isOn: $useGreedySampling)
                            .labelsHidden()
                    }

                    Text("When enabled, the AI will always choose the most likely next word. This results in more " +
                         "predictable, deterministic responses. When disabled, the AI uses more creative sampling " +
                         "for varied responses.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Spacing.medium)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(12)

                TextEditor(text: $instructions)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .padding(Spacing.medium)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                Spacer()
            }
            .padding(Spacing.medium)
            .navigationTitle("Instructions")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    ChatInstructionsView(
        instructions: .constant("You are a helpful AI assistant. Please be concise and accurate in your responses."),
        useGreedySampling: .constant(false),
        onApply: { }
    )
}

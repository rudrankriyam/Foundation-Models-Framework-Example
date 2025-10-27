//
//  ChatInstructionsView.swift
//  FoundationLab
//
//  Created by Assistant on 12/17/24.
//

import SwiftUI

struct ChatInstructionsView: View {
    @Binding var instructions: String
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
        onApply: { }
    )
}

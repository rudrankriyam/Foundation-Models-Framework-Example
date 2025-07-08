//
//  InstructionsView.swift
//  FoundationLab
//
//  Created by Assistant on 7/1/25.
//

import SwiftUI

struct ChatInstructionsView: View {
    @Binding var showInstructions: Bool
    @Binding var instructions: String
    let onApply: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { showInstructions.toggle() }) {
                HStack(spacing: Spacing.small) {
                    Image(systemName: showInstructions ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Instructions")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !showInstructions {
                        Text("Customize AI behavior")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
            }
            .buttonStyle(.plain)
            
            if showInstructions {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    TextEditor(text: $instructions)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(Spacing.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                    
                    HStack {
                        Text("Changes will apply to new conversations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Apply Now") {
                            onApply()
                            showInstructions = false
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        #if os(iOS) || os(macOS)
                        .buttonStyle(.glassProminent)
                        #else
                        .buttonStyle(.bordered)
                        #endif
                    }
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.bottom, Spacing.small)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.regularMaterial)
        .cornerRadius(12)
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
    }
}

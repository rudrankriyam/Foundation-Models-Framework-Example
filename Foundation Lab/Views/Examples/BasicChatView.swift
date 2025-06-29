//
//  BasicChatView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import SwiftUI

struct BasicChatView: View {
  @State private var currentPrompt = DefaultPrompts.basicChat
  @State private var instructions = DefaultPrompts.basicChatInstructions
  @State private var executor = ExampleExecutor()
  @State private var showInstructions = false
  
  var body: some View {
    ExampleViewBase(
      title: "Basic Chat",
      description: "Simple conversation with the AI assistant",
      defaultPrompt: DefaultPrompts.basicChat,
      currentPrompt: $currentPrompt,
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage,
      codeExample: DefaultPrompts.basicChatCode(
        prompt: currentPrompt,
        instructions: showInstructions && !instructions.isEmpty ? instructions : nil
      ),
      onRun: executeChat,
      onReset: resetToDefaults
    ) {
      VStack(spacing: Spacing.large) {
        // Instructions Section
        if showInstructions || !instructions.isEmpty {
          VStack(alignment: .leading, spacing: Spacing.small) {
            Button(action: { showInstructions.toggle() }) {
              HStack(spacing: Spacing.small) {
                Image(systemName: showInstructions ? "chevron.down" : "chevron.right")
                  .font(.caption2)
                  .foregroundColor(.secondary)
                
                Text("INSTRUCTIONS")
                  .font(.footnote)
                  .fontWeight(.medium)
                  .foregroundColor(.secondary)
                
                Spacer()
              }
            }
            .buttonStyle(.plain)
            
            if showInstructions {
              TextEditor(text: $instructions)
                .font(.body)
                .padding(Spacing.medium)
                #if os(iOS)
                .background(Color(UIColor.quaternarySystemFill))
                #else
                .background(Color(NSColor.quaternaryLabelColor).opacity(0.05))
                #endif
                .cornerRadius(12)
                .frame(minHeight: 80)
            }
          }
        } else {
          Button(action: { showInstructions = true }) {
            HStack(spacing: Spacing.small) {
              Image(systemName: "plus.circle")
                .font(.callout)
              Text("Add Instructions")
                .font(.callout)
            }
            .foregroundColor(.accentColor)
          }
          .buttonStyle(.plain)
        }
        
        // Prompt Suggestions
        PromptSuggestions(
          suggestions: DefaultPrompts.basicChatSuggestions,
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
          ExampleResultDisplay(
            result: executor.result,
            isSuccess: executor.errorMessage == nil
          )
        }
      }
    }
  }
  
  private func executeChat() {
    Task {
      await executor.executeBasic(
        prompt: currentPrompt,
        instructions: instructions.isEmpty ? nil : instructions
      )
    }
  }
  
  private func resetToDefaults() {
    currentPrompt = DefaultPrompts.basicChat
    instructions = DefaultPrompts.basicChatInstructions
  }
}

#Preview {
  NavigationStack {
    BasicChatView()
  }
}
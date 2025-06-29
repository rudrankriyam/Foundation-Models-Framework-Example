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
        VStack(alignment: .leading, spacing: 0) {
          Button(action: { showInstructions.toggle() }) {
            HStack(spacing: Spacing.small) {
              Image(systemName: showInstructions ? "chevron.down" : "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary)
              
              Text("Instructions")
                .font(.callout)
                .foregroundColor(.primary)
              
              Spacer()
            }
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
                .frame(minHeight: 80)
            }
            .padding(.top, Spacing.small)
            .transition(.opacity.combined(with: .move(edge: .top)))
          }
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
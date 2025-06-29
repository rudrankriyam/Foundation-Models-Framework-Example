//
//  BasicChatView.swift
//  FoundationLab
//
//  Created by Claude on 1/29/25.
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
      icon: "bubble.left.and.bubble.right",
      description: "Simple conversation with the AI assistant",
      defaultPrompt: DefaultPrompts.basicChat,
      currentPrompt: $currentPrompt,
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage,
      codeExample: DefaultPrompts.basicChatCode,
      onRun: executeChat,
      onReset: resetToDefaults
    ) {
      VStack(spacing: 16) {
        // Instructions Section
        VStack(alignment: .leading, spacing: 8) {
          Button(action: { showInstructions.toggle() }) {
            HStack {
              Label("Instructions", systemImage: "text.alignleft")
                .font(.headline)
              Spacer()
              Image(systemName: showInstructions ? "chevron.up" : "chevron.down")
                .font(.caption)
            }
            .foregroundColor(.primary)
          }
          .buttonStyle(.plain)
          
          if showInstructions {
            TextEditor(text: $instructions)
              .font(.body)
              .padding(8)
              .background(Color.secondaryBackgroundColor)
              .cornerRadius(8)
              .frame(minHeight: 80)
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
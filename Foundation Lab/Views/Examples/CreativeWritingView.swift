//
//  CreativeWritingView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import SwiftUI

struct CreativeWritingView: View {
  @State private var currentPrompt = DefaultPrompts.creativeWriting
  @State private var instructions = ""
  @State private var executor = ExampleExecutor()
  @State private var showInstructions = false
  
  var body: some View {
    ExampleViewBase(
      title: "Creative Writing",
      description: "Generate stories, poems, and creative content",
      defaultPrompt: DefaultPrompts.creativeWriting,
      currentPrompt: $currentPrompt,
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage,
      codeExample: DefaultPrompts.creativeWritingCode(prompt: currentPrompt, instructions: showInstructions && !instructions.isEmpty ? instructions : nil),
      onRun: executeCreativeWriting,
      onReset: resetToDefaults
    ) {
      VStack(spacing: 16) {
        // Info Banner
        HStack {
          Image(systemName: "info.circle")
            .foregroundColor(.indigo)
          Text("Creates structured story outlines with plot, characters, and themes")
            .font(.caption)
            .foregroundColor(.secondary)
          Spacer()
        }
        .padding()
        .background(Color.indigo.opacity(0.1))
        .cornerRadius(8)
        
        // Prompt Suggestions
        PromptSuggestions(
          suggestions: DefaultPrompts.creativeWritingSuggestions,
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
            Label("Story Outline", systemImage: "book.closed")
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
  
  private func executeCreativeWriting() {
    Task {
      await executor.executeStructured(
        prompt: currentPrompt,
        type: StoryOutline.self
      ) { story in
        """
        📖 Title: \(story.title)
        
        🎭 Genre: \(story.genre)
        
        👤 Protagonist:
        \(story.protagonist)
        
        ⚔️ Central Conflict:
        \(story.conflict)
        
        📍 Setting:
        \(story.setting)
        
        🎯 Major Themes:
        \(story.themes.map { "• \($0)" }.joined(separator: "\n"))
        """
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
    CreativeWritingView()
  }
}

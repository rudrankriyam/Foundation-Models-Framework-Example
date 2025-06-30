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
  @State private var instructions = DefaultPrompts.creativeWritingInstructions
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
            
            ExampleResultDisplay(
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
        type: StoryOutline.self,
        instructions: instructions.isEmpty ? nil : instructions
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
    currentPrompt = DefaultPrompts.creativeWriting
    instructions = DefaultPrompts.creativeWritingInstructions
  }
}

#Preview {
  NavigationStack {
    CreativeWritingView()
  }
}
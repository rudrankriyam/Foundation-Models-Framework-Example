//
//  StructuredDataView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import SwiftUI

struct StructuredDataView: View {
  @State private var currentPrompt = DefaultPrompts.structuredData
  @State private var instructions = DefaultPrompts.structuredDataInstructions
  @State private var executor = ExampleExecutor()
  @State private var showInstructions = false
  
  var body: some View {
    ExampleViewBase(
      title: "Structured Data",
      description: "Generate and parse structured information",
      defaultPrompt: DefaultPrompts.structuredData,
      currentPrompt: $currentPrompt,
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage,
      codeExample: DefaultPrompts.structuredDataCode(
        prompt: currentPrompt,
        instructions: showInstructions && !instructions.isEmpty ? instructions : nil
      ),
      onRun: executeStructuredData,
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
            .foregroundColor(.blue)
          Text("Generates structured book recommendations with title, author, genre, and description")
            .font(.caption)
            .foregroundColor(.secondary)
          Spacer()
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
        
        // Prompt Suggestions
        PromptSuggestions(
          suggestions: DefaultPrompts.structuredDataSuggestions,
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
            Label("Generated Book Recommendation", systemImage: "book")
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
  
  private func executeStructuredData() {
    Task {
      await executor.executeStructured(
        prompt: currentPrompt,
        type: BookRecommendation.self,
        instructions: instructions.isEmpty ? nil : instructions
      ) { book in
        """
        📚 Title: \(book.title)
        ✍️ Author: \(book.author)
        🏷️ Genre: \(book.genre)
        
        📖 Description:
        \(book.description)
        """
      }
    }
  }
  
  private func resetToDefaults() {
    currentPrompt = DefaultPrompts.structuredData
    instructions = DefaultPrompts.structuredDataInstructions
  }
}

#Preview {
  NavigationStack {
    StructuredDataView()
  }
}
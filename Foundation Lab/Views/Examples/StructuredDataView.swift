//
//  StructuredDataView.swift
//  FoundationLab
//
//  Created by Claude on 1/29/25.
//

import FoundationModels
import SwiftUI

struct StructuredDataView: View {
  @State private var currentPrompt = DefaultPrompts.structuredData
  @State private var executor = ExampleExecutor()
  
  var body: some View {
    ExampleViewBase(
      title: "Structured Data",
      icon: "list.bullet.rectangle",
      description: "Generate and parse structured information",
      defaultPrompt: DefaultPrompts.structuredData,
      currentPrompt: $currentPrompt,
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage,
      codeExample: DefaultPrompts.structuredDataCode,
      onRun: executeStructuredData,
      onReset: resetToDefaults
    ) {
      VStack(spacing: 16) {
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
        type: BookRecommendation.self
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
  }
}

#Preview {
  NavigationStack {
    StructuredDataView()
  }
}
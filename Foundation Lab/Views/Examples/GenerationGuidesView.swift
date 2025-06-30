//
//  GenerationGuidesView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import SwiftUI

struct GenerationGuidesView: View {
  @State private var currentPrompt = DefaultPrompts.generationGuides
  @State private var instructions = DefaultPrompts.generationGuidesInstructions
  @State private var executor = ExampleExecutor()
  @State private var showInstructions = false
  
  var body: some View {
    ExampleViewBase(
      title: "Generation Guides",
      description: "Guided generation with constraints and structured output",
      defaultPrompt: DefaultPrompts.generationGuides,
      currentPrompt: $currentPrompt,
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage,
      codeExample: DefaultPrompts.generationGuidesCode(
        prompt: currentPrompt,
        instructions: showInstructions && !instructions.isEmpty ? instructions : nil
      ),
      onRun: executeGenerationGuides,
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
            .foregroundColor(.purple)
          Text("Uses @Guide annotations to structure product reviews with ratings, pros, cons, and recommendations")
            .font(.caption)
            .foregroundColor(.secondary)
          Spacer()
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
        
        // Prompt Suggestions
        PromptSuggestions(
          suggestions: DefaultPrompts.generationGuidesSuggestions,
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
            Label("Generated Product Review", systemImage: "star.leadinghalf.filled")
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
  
  private func executeGenerationGuides() {
    Task {
      await executor.executeStructured(
        prompt: currentPrompt,
        type: ProductReview.self,
        instructions: instructions.isEmpty ? nil : instructions
      ) { review in
        """
        🛍️ Product: \(review.productName)
        ⭐ Rating: \(review.rating)/5
        
        ✅ Pros:
        \(review.pros.map { "• \($0)" }.joined(separator: "\n"))
        
        ❌ Cons:
        \(review.cons.map { "• \($0)" }.joined(separator: "\n"))
        
        💬 Review:
        \(review.reviewText)
        
        📌 Recommendation:
        \(review.recommendation)
        """
      }
    }
  }
  
  private func resetToDefaults() {
    currentPrompt = DefaultPrompts.generationGuides
    instructions = DefaultPrompts.generationGuidesInstructions
  }
}

#Preview {
  NavigationStack {
    GenerationGuidesView()
  }
}
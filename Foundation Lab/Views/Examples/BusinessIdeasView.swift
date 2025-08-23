//
//  BusinessIdeasView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import SwiftUI

struct BusinessIdeasView: View {
  @State private var currentPrompt = DefaultPrompts.businessIdeas
  @State private var executor = ExampleExecutor()
  
  var body: some View {
    ExampleViewBase(
      title: "Business Ideas",
      description: "Generate innovative business concepts and strategies",
      defaultPrompt: DefaultPrompts.businessIdeas,
      currentPrompt: $currentPrompt,
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage,
      codeExample: DefaultPrompts.businessIdeasCode(prompt: currentPrompt),
      onRun: executeBusinessIdea,
      onReset: resetToDefaults
    ) {
      VStack(spacing: 16) {
        // Info Banner
        HStack {
          Image(systemName: "info.circle")
            .foregroundColor(.orange)
          Text("Generates structured business ideas with market analysis and revenue models")
            .font(.caption)
            .foregroundColor(.secondary)
          Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        
        // Prompt Suggestions
        PromptSuggestions(
          suggestions: DefaultPrompts.businessIdeasSuggestions,
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
            Label("Generated Business Concept", systemImage: "briefcase")
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
  
  private func executeBusinessIdea() {
    Task {
      await executor.executeStructured(
        prompt: currentPrompt,
        type: BusinessIdea.self
      ) { idea in
        """
        💡 Business Name: \(idea.name)
        
        📝 Description:
        \(idea.description)
        
        🎯 Target Market:
        \(idea.targetMarket)
        
        💪 Key Advantages:
        \(idea.advantages.map { "• \($0)" }.joined(separator: "\n"))
        
        💰 Revenue Model:
        \(idea.revenueModel)
        
        💵 Estimated Startup Cost:
        \(idea.estimatedStartupCost)
        
        ⏱️ Timeline:
        \(idea.timeline ?? "To be determined")
        """
      }
    }
  }
  
  private func resetToDefaults() {
    currentPrompt = DefaultPrompts.businessIdeas
  }
}

#Preview {
  NavigationStack {
    BusinessIdeasView()
  }
}

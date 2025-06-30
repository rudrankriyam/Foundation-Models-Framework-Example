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
  @State private var instructions = DefaultPrompts.businessIdeasInstructions
  @State private var executor = ExampleExecutor()
  @State private var showInstructions = false
  
  var body: some View {
    ExampleViewBase(
      title: "Business Ideas",
      description: "Generate innovative business concepts and strategies",
      defaultPrompt: DefaultPrompts.businessIdeas,
      currentPrompt: $currentPrompt,
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage,
      codeExample: DefaultPrompts.businessIdeasCode(
        prompt: currentPrompt,
        instructions: showInstructions && !instructions.isEmpty ? instructions : nil
      ),
      onRun: executeBusinessIdea,
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
            
            ExampleResultDisplay(
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
        type: BusinessIdea.self,
        instructions: instructions.isEmpty ? nil : instructions
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
    instructions = DefaultPrompts.businessIdeasInstructions
  }
}

#Preview {
  NavigationStack {
    BusinessIdeasView()
  }
}
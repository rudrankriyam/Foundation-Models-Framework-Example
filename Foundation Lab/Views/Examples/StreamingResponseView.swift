//
//  StreamingResponseView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import SwiftUI

struct StreamingResponseView: View {
  @State private var currentPrompt = DefaultPrompts.streaming
  @State private var instructions = DefaultPrompts.streamingInstructions
  @State private var executor = ExampleExecutor()
  @State private var streamingText = ""
  @State private var isStreaming = false
  @State private var showInstructions = false
  
  var body: some View {
    ExampleViewBase(
      title: "Streaming Response",
      description: "Real-time response streaming as text is generated",
      defaultPrompt: DefaultPrompts.streaming,
      currentPrompt: $currentPrompt,
      isRunning: isStreaming,
      errorMessage: executor.errorMessage,
      codeExample: DefaultPrompts.streamingResponseCode(
        prompt: currentPrompt,
        instructions: showInstructions && !instructions.isEmpty ? instructions : nil
      ),
      onRun: executeStreaming,
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
            .foregroundColor(.green)
          Text("Watch as the AI generates text in real-time, character by character")
            .font(.caption)
            .foregroundColor(.secondary)
          Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
        
        // Prompt Suggestions
        PromptSuggestions(
          suggestions: DefaultPrompts.streamingSuggestions,
          onSelect: { currentPrompt = $0 }
        )
        
        // Prompt History
        if !executor.promptHistory.isEmpty {
          PromptHistory(
            history: executor.promptHistory,
            onSelect: { currentPrompt = $0 }
          )
        }
        
        // Streaming Result Display
        if !streamingText.isEmpty || isStreaming {
          VStack(alignment: .leading, spacing: 12) {
            HStack {
              Label("Streaming Output", systemImage: "text.cursor")
                .font(.headline)
              
              if isStreaming {
                ProgressView()
                  .scaleEffect(0.8)
              }
              
              Spacer()
            }
            
            ScrollViewReader { proxy in
              ScrollView {
                Text(streamingText)
                  .font(.system(.body, design: .monospaced))
                  .textSelection(.enabled)
                  .padding()
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .background(Color.secondaryBackgroundColor)
                  .cornerRadius(8)
                  .id("streamingText")
              }
              .frame(maxHeight: 300)
              .onChange(of: streamingText) {
                withAnimation {
                  proxy.scrollTo("streamingText", anchor: .bottom)
                }
              }
            }
          }
        }
      }
    }
  }
  
  private func executeStreaming() {
    Task {
      isStreaming = true
      streamingText = ""
      
      await executor.executeStreaming(
        prompt: currentPrompt,
        instructions: instructions.isEmpty ? nil : instructions
      ) { partialResult in
        streamingText = partialResult
      }
      
      isStreaming = false
    }
  }
  
  private func resetToDefaults() {
    currentPrompt = DefaultPrompts.streaming
    instructions = DefaultPrompts.streamingInstructions
    streamingText = ""
  }
}

#Preview {
  NavigationStack {
    StreamingResponseView()
  }
}
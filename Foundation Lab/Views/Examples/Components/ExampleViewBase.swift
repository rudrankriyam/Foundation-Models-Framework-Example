//
//  ExampleViewBase.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import SwiftUI

/// Base component for example views providing consistent UI elements
struct ExampleViewBase<Content: View>: View {
  let title: String
  let description: String
  let defaultPrompt: String
  @Binding var currentPrompt: String
  let isRunning: Bool
  let errorMessage: String?
  let codeExample: String?
  let onRun: () -> Void
  let onReset: () -> Void
  let content: Content
  
  init(
    title: String,
    description: String,
    defaultPrompt: String,
    currentPrompt: Binding<String>,
    isRunning: Bool = false,
    errorMessage: String? = nil,
    codeExample: String? = nil,
    onRun: @escaping () -> Void,
    onReset: @escaping () -> Void,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.description = description
    self.defaultPrompt = defaultPrompt
    self._currentPrompt = currentPrompt
    self.isRunning = isRunning
    self.errorMessage = errorMessage
    self.codeExample = codeExample
    self.onRun = onRun
    self.onReset = onReset
    self.content = content()
  }
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Spacing.large) {
        // Title and description at top
        VStack(alignment: .leading, spacing: Spacing.small) {
          Text(title)
            .font(.title3)
            .fontWeight(.semibold)
          Text(description)
            .font(.callout)
            .foregroundColor(.secondary)
        }
        
        promptSection
        actionButtons
        
        if let error = errorMessage {
          Text(error)
            .font(.callout)
            .foregroundColor(.secondary)
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        
        content
        
        if let code = codeExample {
          CodeDisclosure(code: code)
        }
      }
      .padding(.horizontal, Spacing.medium)
      .padding(.vertical, Spacing.large)
    }
    #if os(iOS)
    .scrollDismissesKeyboard(.interactively)
    .navigationBarHidden(true)
    #endif
  }
  
  private var promptSection: some View {
    VStack(alignment: .leading, spacing: Spacing.small) {
      Text("PROMPT")
        .font(.footnote)
        .fontWeight(.medium)
        .foregroundColor(.secondary)
      
      TextEditor(text: $currentPrompt)
        .font(.body)
        .scrollContentBackground(.hidden)
        .padding(Spacing.medium)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .frame(minHeight: 100)
    }
  }
  
  private var actionButtons: some View {
    HStack(spacing: Spacing.small) {
      Button(action: onReset) {
        Text("Reset")
          .font(.callout)
          .fontWeight(.medium)
          .frame(maxWidth: .infinity)
          .padding(.vertical, Spacing.small)
      }
      .buttonStyle(.glassProminent)
      .tint(.secondary)
      .disabled(currentPrompt == defaultPrompt)
      
      Button(action: onRun) {
        HStack(spacing: Spacing.small) {
          if isRunning {
            ProgressView()
              .scaleEffect(0.8)
              .tint(.white)
          }
          Text(isRunning ? "Running..." : "Run")
            .font(.callout)
            .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.small)
      }
      .buttonStyle(.glassProminent)
      .disabled(isRunning || currentPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
  }
}

// MARK: - Supporting Views

/// Reusable prompt suggestions view
struct PromptSuggestions: View {
  let suggestions: [String]
  let onSelect: (String) -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.small) {
      Text("SUGGESTIONS")
        .font(.footnote)
        .fontWeight(.medium)
        .foregroundColor(.secondary)
      
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: Spacing.small) {
          ForEach(suggestions, id: \.self) { suggestion in
            Button(action: { onSelect(suggestion) }) {
              Text(suggestion)
                .font(.callout)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
                .background(Color.gray.opacity(0.1))
                .foregroundColor(.primary)
                .overlay(
                  RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(20)
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }
}

/// Result display with copy functionality
struct ExampleResultDisplay: View {
  let result: String
  let isSuccess: Bool
  @State private var isCopied = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.small) {
      HStack {
        Text("RESULT")
          .font(.footnote)
          .fontWeight(.medium)
          .foregroundColor(.secondary)
        
        Spacer()
        
        Button(action: copyToClipboard) {
          Text(isCopied ? "Copied" : "Copy")
            .font(.callout)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, 4)
        }
        .buttonStyle(.glassProminent)
      }
      
      ScrollView {
        Text(LocalizedStringKey(result))
          .font(.body)
          .textSelection(.enabled)
          .padding(Spacing.medium)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.gray.opacity(0.1))
          .cornerRadius(12)
      }
      .frame(maxHeight: 300)
    }
  }
  
  private func copyToClipboard() {
    #if os(iOS)
    UIPasteboard.general.string = result
    #elseif os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(result, forType: .string)
    #endif
    
    isCopied = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      isCopied = false
    }
  }
}

#Preview {
  NavigationStack {
    ExampleViewBase(
      title: "Sample Example",
      description: "This is a sample example for demonstration",
      defaultPrompt: "Tell me a joke",
      currentPrompt: .constant("Tell me a joke"),
      isRunning: false,
      errorMessage: nil,
      onRun: {},
      onReset: {}
    ) {
      ExampleResultDisplay(
        result: "Why don't scientists trust atoms? Because they make up everything!",
        isSuccess: true
      )
    }
  }
}
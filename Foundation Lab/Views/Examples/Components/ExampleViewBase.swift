//
//  ExampleViewBase.swift
//  FoundationLab
//
//  Created by Claude on 1/29/25.
//

import FoundationModels
import SwiftUI

/// Base component for example views providing consistent UI elements
struct ExampleViewBase<Content: View>: View {
  let title: String
  let icon: String
  let description: String
  let defaultPrompt: String
  @Binding var currentPrompt: String
  let isRunning: Bool
  let errorMessage: String?
  let onRun: () -> Void
  let onReset: () -> Void
  let content: Content
  
  init(
    title: String,
    icon: String,
    description: String,
    defaultPrompt: String,
    currentPrompt: Binding<String>,
    isRunning: Bool = false,
    errorMessage: String? = nil,
    onRun: @escaping () -> Void,
    onReset: @escaping () -> Void,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.icon = icon
    self.description = description
    self.defaultPrompt = defaultPrompt
    self._currentPrompt = currentPrompt
    self.isRunning = isRunning
    self.errorMessage = errorMessage
    self.onRun = onRun
    self.onReset = onReset
    self.content = content()
  }
  
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        headerView
        promptSection
        actionButtons
        
        if let error = errorMessage {
          ErrorBanner(message: error)
        }
        
        content
      }
      .padding()
    }
    #if os(iOS)
    .scrollDismissesKeyboard(.interactively)
    #endif
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.large)
  }
  
  private var headerView: some View {
    HStack(alignment: .top) {
      Image(systemName: icon)
        .font(.system(size: 40))
        .foregroundColor(.accentColor)
        .frame(width: 60, height: 60)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(12)
      
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.title2)
          .fontWeight(.semibold)
        
        Text(description)
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      
      Spacer()
    }
  }
  
  private var promptSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("Prompt", systemImage: "text.quote")
        .font(.headline)
      
      #if os(iOS)
      TextEditor(text: $currentPrompt)
        .font(.body)
        .padding(8)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .frame(minHeight: 100)
      #else
      TextEditor(text: $currentPrompt)
        .font(.body)
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .frame(minHeight: 100)
      #endif
    }
  }
  
  private var actionButtons: some View {
    HStack(spacing: 12) {
      Button(action: onReset) {
        Label("Reset", systemImage: "arrow.counterclockwise")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.bordered)
      .disabled(currentPrompt == defaultPrompt)
      
      Button(action: onRun) {
        HStack {
          if isRunning {
            ProgressView()
              .scaleEffect(0.8)
          } else {
            Image(systemName: "play.fill")
          }
          Text("Run Example")
        }
        .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
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
    VStack(alignment: .leading, spacing: 8) {
      Text("Try these prompts:")
        .font(.caption)
        .foregroundColor(.secondary)
      
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(suggestions, id: \.self) { suggestion in
            Button(action: { onSelect(suggestion) }) {
              Text(suggestion)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(.accentColor)
                .cornerRadius(15)
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
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Label("Result", systemImage: isSuccess ? "checkmark.circle" : "xmark.circle")
          .font(.headline)
          .foregroundColor(isSuccess ? .green : .red)
        
        Spacer()
        
        Button(action: copyToClipboard) {
          Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
            .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
      }
      
      ScrollView {
        Text(result)
          .font(.system(.body, design: .monospaced))
          .textSelection(.enabled)
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.secondaryBackgroundColor)
          .cornerRadius(8)
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
      icon: "sparkles",
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
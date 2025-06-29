//
//  PromptField.swift
//  FoundationLab
//
//  Created by Claude on 1/29/25.
//

import SwiftUI

/// A reusable prompt field component with built-in features
struct PromptField: View {
  @Binding var text: String
  let placeholder: String
  let minHeight: CGFloat
  
  init(
    text: Binding<String>,
    placeholder: String = "Enter your prompt here...",
    minHeight: CGFloat = 100
  ) {
    self._text = text
    self.placeholder = placeholder
    self.minHeight = minHeight
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Label("Prompt", systemImage: "text.quote")
          .font(.headline)
        
        Spacer()
        
        if !text.isEmpty {
          Text("\(text.count) characters")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      
      ZStack(alignment: .topLeading) {
        #if os(iOS)
        let backgroundColor = Color(UIColor.secondarySystemBackground)
        #else
        let backgroundColor = Color(NSColor.controlBackgroundColor)
        #endif
        
        TextEditor(text: $text)
          .font(.body)
          .padding(8)
          .background(backgroundColor)
          .cornerRadius(8)
          .frame(minHeight: minHeight)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
          )
        
        if text.isEmpty {
          Text(placeholder)
            .font(.body)
            .foregroundColor(.secondary.opacity(0.6))
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .allowsHitTesting(false)
        }
      }
    }
  }
}

/// A simplified prompt field for single-line inputs
struct SimplePromptField: View {
  @Binding var text: String
  let placeholder: String
  let icon: String?
  
  init(
    text: Binding<String>,
    placeholder: String = "Enter text...",
    icon: String? = nil
  ) {
    self._text = text
    self.placeholder = placeholder
    self.icon = icon
  }
  
  var body: some View {
    HStack {
      if let icon = icon {
        Image(systemName: icon)
          .foregroundColor(.secondary)
      }
      
      TextField(placeholder, text: $text)
        .textFieldStyle(RoundedBorderTextFieldStyle())
    }
  }
}

/// Prompt history view for quick access to previous prompts
struct PromptHistory: View {
  let history: [String]
  let onSelect: (String) -> Void
  @State private var isExpanded = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Button(action: { isExpanded.toggle() }) {
        HStack {
          Label("Recent Prompts", systemImage: "clock.arrow.circlepath")
            .font(.caption)
          
          Spacer()
          
          Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
            .font(.caption)
        }
        .foregroundColor(.secondary)
      }
      .buttonStyle(.plain)
      
      if isExpanded && !history.isEmpty {
        VStack(alignment: .leading, spacing: 4) {
          ForEach(history.prefix(5), id: \.self) { prompt in
            Button(action: { onSelect(prompt) }) {
              Text(prompt)
                .font(.caption)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }
}

#Preview("PromptField") {
  VStack(spacing: 20) {
    PromptField(
      text: .constant(""),
      placeholder: "What would you like to know?"
    )
    
    PromptField(
      text: .constant("Tell me about Swift programming"),
      minHeight: 60
    )
  }
  .padding()
}

#Preview("SimplePromptField") {
  VStack(spacing: 20) {
    SimplePromptField(
      text: .constant(""),
      placeholder: "Enter city name",
      icon: "location"
    )
    
    SimplePromptField(
      text: .constant("San Francisco")
    )
  }
  .padding()
}

#Preview("PromptHistory") {
  PromptHistory(
    history: [
      "Tell me a joke",
      "Explain quantum computing",
      "Write a haiku about programming",
      "What is machine learning?",
      "Create a recipe for chocolate cake"
    ],
    onSelect: { print("Selected: \($0)") }
  )
  .padding()
}
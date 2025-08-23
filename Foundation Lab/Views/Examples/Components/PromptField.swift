//
//  PromptField.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
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
    VStack(alignment: .leading, spacing: Spacing.small) {
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
        TextEditor(text: $text)
          .font(.body)
          .scrollContentBackground(.hidden)
          .padding(Spacing.small)
          .background(Color.gray.opacity(0.1))
          .cornerRadius(CornerRadius.small)
          .frame(minHeight: minHeight)
        
        if text.isEmpty {
          Text(placeholder)
            .font(.body)
            .foregroundColor(.secondary.opacity(0.6))
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
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
    VStack(alignment: .leading, spacing: 0) {
      Button(action: { 
        isExpanded.toggle()
      }) {
        HStack(spacing: Spacing.small) {
          Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            .font(.caption2)
            .foregroundColor(.secondary)
          
          Text("Recent")
            .font(.callout)
            .foregroundColor(.primary)
          
          Spacer()
        }
      }
      .buttonStyle(.plain)
      
      if isExpanded && !history.isEmpty {
        VStack(alignment: .leading, spacing: Spacing.small) {
          ForEach(history.prefix(5), id: \.self) { prompt in
            Button(action: { onSelect(prompt) }) {
              Text(prompt)
                .font(.callout)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.small)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .foregroundColor(.primary)
          }
        }
        .padding(.top, Spacing.small)
        .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
  }
}

#Preview("PromptField") {
  VStack(spacing: Spacing.xLarge) {
    PromptField(
      text: .constant(""),
      placeholder: "What would you like to know?"
    )
    
    PromptField(
      text: .constant("Tell me about Swift programming"),
      minHeight: 80
    )
  }
  .padding()
}

#Preview("SimplePromptField") {
  VStack(spacing: Spacing.xLarge) {
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
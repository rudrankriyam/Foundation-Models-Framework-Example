//
//  CodeViewer.swift
//  FoundationLab
//
//  Created by Claude on 1/29/25.
//

import SwiftUI

/// A view for displaying syntax-highlighted code snippets
struct CodeViewer: View {
  let code: String
  let language: String
  @State private var isCopied = false
  
  init(code: String, language: String = "swift") {
    self.code = code
    self.language = language
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.sm) {
      HStack {
        Text("CODE")
          .font(.footnote)
          .fontWeight(.medium)
          .foregroundColor(.secondary)
        
        Spacer()
        
        Button(action: copyToClipboard) {
          Text(isCopied ? "Copied" : "Copy")
            .font(.callout)
            .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
      }
      
      ScrollView {
        Text(code)
          .font(.system(.callout, design: .monospaced))
          .textSelection(.enabled)
          .padding(Spacing.md)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(maxHeight: 400)
      #if os(iOS)
      .background(Color(UIColor.quaternarySystemFill))
      #else
      .background(Color(NSColor.quaternaryLabelColor).opacity(0.05))
      #endif
      .cornerRadius(12)
    }
  }
  
  private func copyToClipboard() {
    #if os(iOS)
    UIPasteboard.general.string = code
    #elseif os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(code, forType: .string)
    #endif
    
    isCopied = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      isCopied = false
    }
  }
}

/// Collapsible code section with disclosure
struct CodeDisclosure: View {
  let code: String
  let language: String
  @State private var isExpanded = false
  
  init(code: String, language: String = "swift") {
    self.code = code
    self.language = language
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Button(action: { 
        withAnimation(.easeInOut(duration: 0.2)) {
          isExpanded.toggle()
        }
      }) {
        HStack(spacing: Spacing.sm) {
          Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            .font(.caption2)
            .foregroundColor(.secondary)
          
          Text("View Code")
            .font(.callout)
            .foregroundColor(.primary)
          
          Spacer()
        }
        .padding(Spacing.md)
        #if os(iOS)
      .background(Color(UIColor.quaternarySystemFill))
      #else
      .background(Color(NSColor.quaternaryLabelColor).opacity(0.05))
      #endif
        .cornerRadius(12)
      }
      .buttonStyle(.plain)
      
      if isExpanded {
        CodeViewer(code: code, language: language)
          .padding(.top, Spacing.sm)
          .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
  }
}

#Preview("CodeViewer") {
  ScrollView {
    VStack(spacing: 20) {
      CodeViewer(code: """
import FoundationModels

let session = LanguageModelSession()
let response = try await session.generate(
    with: "Tell me a joke",
    using: .conversational
)
print(response)
""")
      
      CodeViewer(code: """
@Generable
struct Book {
    let title: String
    let author: String
    let genre: String
    let yearPublished: Int
}

let book = try await session.generate(
    prompt: "Suggest a sci-fi book",
    as: Book.self
)
""")
    }
    .padding()
  }
}

#Preview("CodeDisclosure") {
  ScrollView {
    VStack(spacing: 20) {
      CodeDisclosure(code: """
// Basic chat example
let session = LanguageModelSession()
let response = try await session.generate(
    with: prompt,
    using: .conversational
)
""")
      
      CodeDisclosure(code: """
// Structured data example
@Generable
struct BusinessIdea {
    let name: String
    let description: String
    let targetMarket: String
    let advantages: [String]
    let challenges: [String]
}

let idea = try await session.generate(
    prompt: prompt,
    as: BusinessIdea.self
)
""")
    }
    .padding()
  }
}
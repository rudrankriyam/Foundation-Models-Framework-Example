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
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Label("Code Example", systemImage: "chevron.left.forwardslash.chevron.right")
          .font(.headline)
        
        Spacer()
        
        Button(action: copyToClipboard) {
          HStack(spacing: 4) {
            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
            Text(isCopied ? "Copied" : "Copy")
              .font(.caption)
          }
          .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
      }
      
      ScrollView(.horizontal, showsIndicators: true) {
        ScrollView(.vertical, showsIndicators: true) {
          Text(code)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: 400)
      }
      .background(Color.secondaryBackgroundColor)
      .cornerRadius(8)
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
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
          isExpanded.toggle()
        }
      }) {
        HStack {
          Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            .font(.caption)
            .frame(width: 20)
          
          Text("View Code")
            .font(.subheadline)
            .fontWeight(.medium)
          
          Spacer()
          
          Image(systemName: "swift")
            .font(.caption)
            .foregroundColor(.orange)
        }
        .foregroundColor(.primary)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.secondaryBackgroundColor)
        .cornerRadius(8)
      }
      .buttonStyle(.plain)
      
      if isExpanded {
        CodeViewer(code: code, language: language)
          .padding(.top, 8)
          .transition(.asymmetric(
            insertion: .push(from: .top).combined(with: .opacity),
            removal: .push(from: .bottom).combined(with: .opacity)
          ))
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
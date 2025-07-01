//
//  CodeViewer.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import HighlightSwift
import SwiftUI

/// A view for displaying syntax-highlighted code snippets
struct CodeViewer: View {
  let code: String
  let language: String
  @State private var isCopied = false
  
  @Environment(\.colorScheme) private var colorScheme
  @State var highlightedCode: AttributedString?
  
  init(code: String, language: String = "swift") {
    self.code = code
    self.language = language
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.small) {
      HStack {
        Text("CODE")
          .font(.footnote)
          .fontWeight(.medium)
          .foregroundColor(.secondary)
        
        Spacer()
        
        Button(action: copyToClipboard) {
          Text(isCopied ? "Copied" : "Copy")
            .font(.callout)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
        }
        .buttonStyle(.glassProminent)
      }
      
      ScrollView {
        ScrollView {
          Text(highlightedCode ?? AttributedString(code))
            .font(highlightedCode == nil ? .system(.callout, design: .monospaced) : nil)
            .textSelection(.enabled)
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
      .frame(maxHeight: 400)  // TODO: Make this configurable or remove constraint
      .background(Color.gray.opacity(0.1))
      .cornerRadius(CornerRadius.medium)
      .task {
          do {
              let highlight = Highlight()
              self.highlightedCode = try await highlight
                  .attributedText(code,
                    language: "swift",
                    colors: colorScheme == .dark ? .dark(.xcode) : .light(.xcode)
                  )
          } catch {
              self.highlightedCode = nil
          }
      }
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
        isExpanded.toggle()
      }) {
        HStack(spacing: Spacing.small) {
          Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            .font(.caption2)
            .foregroundColor(.secondary)
          
          Text("View Code")
            .font(.callout)
            .foregroundColor(.primary)
          
          Spacer()
        }
      }
      .buttonStyle(.plain)
      
      if isExpanded {
        CodeViewer(code: code, language: language)
          .padding(.top, Spacing.small)
          .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
  }
}

#Preview("CodeViewer") {
  ScrollView {
    VStack(spacing: Spacing.large) {
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
    VStack(spacing: Spacing.large) {
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

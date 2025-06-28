//
//  WebToolView.swift
//  FoundationLab
//
//  Created by Claude on 1/14/25.
//

import FoundationModels
import SwiftUI

struct WebToolView: View {
  @State private var isRunning = false
  @State private var result: String = ""
  @State private var errorMessage: String?
  @State private var searchQuery: String = ""

  var body: some View {
    ToolViewBase(
      title: "Web Search",
      icon: "magnifyingglass",
      description: "Search the web for any topic using AI-powered search",
      isRunning: isRunning,
      errorMessage: errorMessage
    ) {
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Search Query")
            .font(.subheadline)
            .fontWeight(.medium)

          TextField("What would you like to search for?", text: $searchQuery)
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }

        Button(action: executeWebSearch) {
          HStack {
            if isRunning {
              ProgressView()
                .scaleEffect(0.8)
                .foregroundColor(.white)
            } else {
              Image(systemName: "magnifyingglass")
            }

            Text("Search Web")
              .fontWeight(.medium)
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.accentColor)
          .foregroundColor(.white)
          .cornerRadius(12)
        }
        .disabled(isRunning || searchQuery.isEmpty)

        if !result.isEmpty {
          ResultDisplay(result: result, isSuccess: errorMessage == nil)
        }
      }
    }
  }

  private func executeWebSearch() {
    Task {
      await performWebSearch()
    }
  }

  @MainActor
  private func performWebSearch() async {
    isRunning = true
    errorMessage = nil
    result = ""

    do {
      let session = LanguageModelSession(tools: [WebTool()])
      let response = try await session.respond(to: Prompt(searchQuery))
      result = response.content
    } catch {
      errorMessage = "Failed to search: \(error.localizedDescription)"
    }

    isRunning = false
  }
}

#Preview {
  NavigationStack {
    WebToolView()
  }
}

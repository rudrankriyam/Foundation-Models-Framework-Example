//
//  WebToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import FoundationModelsTools
import SwiftUI

struct WebToolView: View {
  @State private var executor = ToolExecutor()
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
      VStack(alignment: .leading, spacing: Spacing.large) {
        VStack(alignment: .leading, spacing: Spacing.small) {
          Text("SEARCH QUERY")
            .font(.footnote)
            .fontWeight(.medium)
            .foregroundColor(.secondary)

          TextEditor(text: $searchQuery)
            .font(.body)
            .scrollContentBackground(.hidden)
            .padding(Spacing.medium)
            .frame(height: 50)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }

        Button(action: executeWebSearch) {
          HStack(spacing: Spacing.small) {
            if isRunning {
              ProgressView()
                .scaleEffect(0.8)
                .tint(.white)
            }
            Text(isRunning ? "Searching..." : "Search Web")
              .font(.callout)
              .fontWeight(.medium)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, Spacing.small)
        }
        .buttonStyle(.glassProminent)
        .disabled(isRunning || searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

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

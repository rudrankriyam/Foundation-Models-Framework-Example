//
//  WebToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import SwiftUI

struct WebToolView: View {
  @State private var executor = ToolExecutor()
  @State private var searchQuery: String = ""

  var body: some View {
    ToolViewBase(
      title: "Web Search",
      icon: "magnifyingglass",
      description: "Search the web using a free keyless endpoint (limited)",
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage
    ) {
      VStack(alignment: .leading, spacing: Spacing.large) {
        BannerView(
          message: "Keyless Search1API (free, limited to 20 requests/day).",
          type: .info
        )

        ToolInputField(
          label: "Search Query",
          text: $searchQuery,
          placeholder: "Enter your search query"
        )

        ToolExecuteButton(
          "Search Web",
          systemImage: "magnifyingglass",
          isRunning: executor.isRunning,
          action: executeWebSearch
        )
        .disabled(executor.isRunning || searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

        if !executor.result.isEmpty {
          ResultDisplay(result: executor.result, isSuccess: executor.errorMessage == nil)
        }
      }
    }
  }

  private func executeWebSearch() {
    Task {
      await executor.execute(
        tool: Search1WebSearchTool(),
        prompt: searchQuery
      )
    }
  }
}

#Preview {
  NavigationStack {
    WebToolView()
  }
}

//
//  WebMetadataToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import FoundationModelsTools
import SwiftUI

struct WebMetadataToolView: View {
  @State private var executor = ToolExecutor()
  @State private var url: String = ""

  var body: some View {
    ToolViewBase(
      title: "Web Metadata",
      icon: "link.circle",
      description: "Fetch webpage metadata and generate social media summaries",
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage
    ) {
      VStack(alignment: .leading, spacing: Spacing.large) {
        VStack(alignment: .leading, spacing: Spacing.small) {
          Text("WEBSITE URL")
            .font(.footnote)
            .fontWeight(.medium)
            .foregroundColor(.secondary)

          TextEditor(text: $url)
            .font(.body)
            .scrollContentBackground(.hidden)
            .padding(Spacing.medium)
            .frame(minHeight: 50, maxHeight: 120)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            #if os(iOS)
            .keyboardType(.URL)
            .autocapitalization(.none)
            #endif
        }

        ToolExecuteButton(
          "Generate Summary",
          systemImage: "link.circle",
          isRunning: executor.isRunning,
          action: executeWebMetadata
        )
        .disabled(executor.isRunning || url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

        if !executor.result.isEmpty {
          ResultDisplay(result: executor.result, isSuccess: executor.errorMessage == nil)
        }
      }
    }
  }

  private func executeWebMetadata() {
    guard let validatedURL = validatedURL() else {
      executor.errorMessage = "Enter a valid http or https URL."
      return
    }

    Task {
      await executor.execute(
        tool: WebMetadataTool(),
        prompt: "Generate a social media summary for \(validatedURL)"
      )
    }
  }

  private func validatedURL() -> String? {
    let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let parsedURL = URL(string: trimmedURL),
          let scheme = parsedURL.scheme?.lowercased(),
          ["http", "https"].contains(scheme),
          parsedURL.host != nil else {
      return nil
    }
    return trimmedURL
  }
}

#Preview {
  NavigationStack {
    WebMetadataToolView()
  }
}

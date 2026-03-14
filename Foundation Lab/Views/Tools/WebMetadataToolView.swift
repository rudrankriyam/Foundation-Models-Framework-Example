//
//  WebMetadataToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationLabCore
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
    let trimmedURL = url.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedURL.isEmpty else {
      executor.result = ""
      executor.successMessage = nil
      executor.errorMessage = "Please enter a valid URL"
      return
    }

    guard isValidWebURL(trimmedURL) else {
      executor.result = ""
      executor.successMessage = nil
      executor.errorMessage = "URL must use http or https"
      return
    }

    Task {
      await executor.executeCapability(
        successMessage: "Web page summary generated successfully!"
      ) {
        try await GenerateWebPageSummaryUseCase().execute(
          GenerateWebPageSummaryRequest(
            url: trimmedURL,
            context: CapabilityInvocationContext(
              source: .app,
              localeIdentifier: Locale.current.identifier
            )
          )
        )
      }
    }
  }

  private func isValidWebURL(_ value: String) -> Bool {
    guard let parsedURL = URL(string: value),
          let scheme = parsedURL.scheme?.lowercased(),
          ["http", "https"].contains(scheme),
          parsedURL.host != nil else {
      return false
    }

    return true
  }
}

#Preview {
  NavigationStack {
    WebMetadataToolView()
  }
}

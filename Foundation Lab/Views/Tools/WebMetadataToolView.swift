//
//  WebMetadataToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import SwiftUI

struct WebMetadataToolView: View {
  @State private var isRunning = false
  @State private var result: String = ""
  @State private var errorMessage: String?
  @State private var url: String = ""

  var body: some View {
    ToolViewBase(
      title: "Web Metadata",
      icon: "link.circle",
      description: "Fetch webpage metadata and generate social media summaries",
      isRunning: isRunning,
      errorMessage: errorMessage
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
            .frame(height: 50)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            #if os(iOS)
              .keyboardType(.URL)
              .autocapitalization(.none)
            #endif
        }

        Button(action: executeWebMetadata) {
          HStack(spacing: Spacing.small) {
            if isRunning {
              ProgressView()
                .scaleEffect(0.8)
                .tint(.white)
            }
            Text(isRunning ? "Generating Summary..." : "Generate Summary")
              .font(.callout)
              .fontWeight(.medium)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, Spacing.small)
        }
        .buttonStyle(.glassProminent)
        .disabled(isRunning || url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

        if !result.isEmpty {
          ResultDisplay(result: result, isSuccess: errorMessage == nil)
        }
      }
    }
  }

  private func executeWebMetadata() {
    Task {
      await performWebMetadataRequest()
    }
  }

  @MainActor
  private func performWebMetadataRequest() async {
    isRunning = true
    errorMessage = nil
    result = ""

    do {
      let session = LanguageModelSession(tools: [WebMetadataTool()])
      let response = try await session.respond(
        to: Prompt("Generate a social media summary for \(url)")
      )
      result = response.content
    } catch {
      errorMessage = "Failed to generate summary: \(error.localizedDescription)"
    }

    isRunning = false
  }
}

#Preview {
  NavigationStack {
    WebMetadataToolView()
  }
}

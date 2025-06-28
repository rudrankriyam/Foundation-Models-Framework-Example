//
//  WebMetadataToolView.swift
//  FoundationLab
//
//  Created by Claude on 1/14/25.
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
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Website URL")
            .font(.subheadline)
            .fontWeight(.medium)

          TextField("Enter website URL", text: $url)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .keyboardType(.URL)
            .autocapitalization(.none)
        }

        Button(action: executeWebMetadata) {
          HStack {
            if isRunning {
              ProgressView()
                .scaleEffect(0.8)
                .foregroundColor(.white)
            } else {
              Image(systemName: "link.circle")
            }

            Text("Generate Summary")
              .fontWeight(.medium)
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.accentColor)
          .foregroundColor(.white)
          .cornerRadius(12)
        }
        .disabled(isRunning || url.isEmpty)

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

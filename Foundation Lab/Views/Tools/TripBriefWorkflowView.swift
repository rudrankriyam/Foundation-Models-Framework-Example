//
//  TripBriefWorkflowView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 2/4/26.
//

import FoundationModels
import FoundationModelsTools
import SwiftUI

/// A compact workflow component that demonstrates multi-tool orchestration
/// by combining Weather and Web Metadata tools to generate trip briefs.
struct TripBriefWorkflowView: View {
  @State private var executor = ToolExecutor()
  @State private var destination: String = "Tokyo, Japan"
  @State private var guideURL: String = "https://www.lonelyplanet.com/japan/tokyo"

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.medium) {
      workflowHeader

      inputSection

      executeButton

      if !executor.result.isEmpty {
        ResultDisplay(
          result: executor.result,
          isSuccess: executor.errorMessage == nil
        )
      }

      if let error = executor.errorMessage {
        errorView(error)
      }
    }
    .padding(Spacing.medium)
    #if os(iOS) || os(macOS)
      .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.medium))
    #else
      .background(Color.gray.opacity(0.1))
      .cornerRadius(CornerRadius.medium)
    #endif
  }

  private var workflowHeader: some View {
    HStack {
      Image(systemName: "airplane.departure")
        .font(.title3)
        .foregroundStyle(Color.main)

      VStack(alignment: .leading, spacing: 2) {
        Text("Trip Brief")
          .font(.headline)
          .foregroundColor(.primary)
        Text("Weather + destination insights")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()
    }
  }

  private var inputSection: some View {
    VStack(spacing: Spacing.small) {
      HStack {
        Text("Destination")
          .font(.caption)
          .foregroundColor(.secondary)
          .frame(width: 80, alignment: .leading)

        TextField("e.g., Tokyo, Japan", text: $destination)
          .textFieldStyle(.plain)
          .padding(Spacing.small)
          .background(Color.gray.opacity(0.1))
          .cornerRadius(CornerRadius.small)
      }

      HStack {
        Text("Guide URL")
          .font(.caption)
          .foregroundColor(.secondary)
          .frame(width: 80, alignment: .leading)

        TextField("https://...", text: $guideURL)
          .textFieldStyle(.plain)
          .padding(Spacing.small)
          .background(Color.gray.opacity(0.1))
          .cornerRadius(CornerRadius.small)
          #if os(iOS)
            .keyboardType(.URL)
            .autocapitalization(.none)
          #endif
      }
    }
  }

  private var executeButton: some View {
    ToolExecuteButton(
      "Generate Trip Brief",
      systemImage: "sparkles",
      isRunning: executor.isRunning,
      action: executeTripBrief
    )
    .disabled(!isInputValid)
  }

  private var isInputValid: Bool {
    !destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !guideURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  private func errorView(_ error: String) -> some View {
    Text(error)
      .font(.caption)
      .foregroundColor(.red)
      .padding(Spacing.small)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(Color.red.opacity(0.1))
      .cornerRadius(CornerRadius.small)
  }

  private func executeTripBrief() {
    Task {
      await executor.executeWithCustomSession(
        sessionBuilder: {
          LanguageModelSession(tools: [WeatherTool(), WebMetadataTool()]) {
            Instructions(tripBriefInstructions)
          }
        },
        prompt: buildPrompt()
      )
    }
  }

  private var tripBriefInstructions: String {
    """
    You are a travel assistant that creates concise trip briefs. You have access to:
    - A weather tool to get current conditions for the destination
    - A web metadata tool to extract information from travel guide URLs

    When creating a trip brief:
    1. First, get the current weather for the destination
    2. Then, extract key information from the provided URL
    3. Combine these into a brief with 3-5 bullet points

    Format your response as:
    ## Trip Brief: [Destination]

    **Weather:** [Brief weather summary with temperature]

    **Key Insights:**
    - [Bullet point 1]
    - [Bullet point 2]
    - [Bullet point 3]

    **Source:** [URL title/citation]
    """
  }

  private func buildPrompt() -> String {
    """
    Create a trip brief for \(destination).

    Please:
    1. Check the current weather in \(destination)
    2. Extract key travel insights from this guide: \(guideURL)
    3. Combine into a 3-5 bullet brief with the weather summary and citations
    """
  }
}

#Preview {
  TripBriefWorkflowView()
    .padding()
}

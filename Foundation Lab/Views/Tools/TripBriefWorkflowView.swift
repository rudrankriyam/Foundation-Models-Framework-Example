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
        TripBriefResultView(result: executor.result)
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

// MARK: - Trip Brief Result View

/// A visually rich result display for trip briefs with sections for weather, insights, and source.
struct TripBriefResultView: View {
  let result: String
  @State private var isCopied = false

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.medium) {
      // Header
      HStack {
        Text("TRIP BRIEF")
          .font(.footnote)
          .fontWeight(.semibold)
          .foregroundColor(.secondary)

        Spacer()

        Button(action: copyToClipboard) {
          HStack(spacing: 4) {
            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
            if isCopied {
              Text("Copied!")
                .font(.caption2)
            }
          }
          .font(.caption)
          .padding(.horizontal, Spacing.small)
          .padding(.vertical, 4)
        }
        .buttonStyle(.glass)
      }

      // Content sections
      ScrollView {
        VStack(alignment: .leading, spacing: Spacing.medium) {
          // Weather Section
          if let weatherSection = extractSection(prefix: "**Weather:**") {
            SectionCard(
              icon: "cloud.sun.fill",
              iconColor: .orange,
              title: "Weather",
              content: weatherSection
            )
          }

          // Key Insights Section
          if let insightsSection = extractInsights() {
            SectionCard(
              icon: "lightbulb.fill",
              iconColor: .yellow,
              title: "Key Insights",
              content: insightsSection,
              isBulletList: true
            )
          }

          // Source Section
          if let sourceSection = extractSection(prefix: "**Source:**") {
            SectionCard(
              icon: "link",
              iconColor: .blue,
              title: "Source",
              content: sourceSection
            )
          }

          // Fallback: show full result if parsing fails
          if !hasParsedContent {
            Text(LocalizedStringKey(result))
              .font(.body)
              .textSelection(.enabled)
          }
        }
        .padding(Spacing.small)
      }
      .frame(maxHeight: 400)
      .background(Color.gray.opacity(0.05))
      .cornerRadius(CornerRadius.medium)
    }
  }

  private var hasParsedContent: Bool {
    extractSection(prefix: "**Weather:**") != nil
      || extractInsights() != nil
      || extractSection(prefix: "**Source:**") != nil
  }

  private func extractSection(
    prefix: String,
    endMarkers: [String] = ["**Weather:**", "**Key Insights:**", "**Source:**", "##"]
  ) -> String? {
    guard let range = result.range(of: prefix) else { return nil }
    let afterPrefix = result[range.upperBound...]
    // Find next section or end
    var endIndex = afterPrefix.endIndex

    for marker in endMarkers {
      if marker != prefix, let markerRange = afterPrefix.range(of: marker) {
        if markerRange.lowerBound < endIndex {
          endIndex = markerRange.lowerBound
        }
      }
    }

    let content = String(afterPrefix[..<endIndex])
      .trimmingCharacters(in: .whitespacesAndNewlines)
    return content.isEmpty ? nil : content
  }

  private func extractInsights() -> String? {
    extractSection(
      prefix: "**Key Insights:**",
      endMarkers: ["**Source:**", "##"]
    )
  }

  private func copyToClipboard() {
    #if os(iOS)
      UIPasteboard.general.string = result
    #elseif os(macOS)
      NSPasteboard.general.clearContents()
      NSPasteboard.general.setString(result, forType: .string)
    #endif

    isCopied = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      isCopied = false
    }
  }
}

/// A styled card for individual sections of the trip brief
struct SectionCard: View {
  let icon: String
  let iconColor: Color
  let title: String
  let content: String
  var isBulletList: Bool = false

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.small) {
      // Section header
      HStack(spacing: Spacing.small) {
        Image(systemName: icon)
          .font(.subheadline)
          .foregroundStyle(iconColor)

        Text(title)
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundColor(.primary)
      }

      // Section content
      if isBulletList {
        VStack(alignment: .leading, spacing: 6) {
          ForEach(parseBulletPoints(), id: \.self) { point in
            HStack(alignment: .top, spacing: 8) {
              Circle()
                .fill(iconColor.opacity(0.6))
                .frame(width: 6, height: 6)
                .padding(.top, 6)

              Text(point)
                .font(.callout)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
        }
      } else {
        Text(content)
          .font(.callout)
          .foregroundColor(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }
    }
    .padding(Spacing.medium)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.gray.opacity(0.08))
    .cornerRadius(CornerRadius.small)
  }

  private func parseBulletPoints() -> [String] {
    content
      .components(separatedBy: "\n")
      .map { line in
        line.trimmingCharacters(in: .whitespaces)
          .replacingOccurrences(of: "^-\\s*", with: "", options: .regularExpression)
          .replacingOccurrences(of: "^•\\s*", with: "", options: .regularExpression)
      }
      .filter { !$0.isEmpty }
  }
}

#Preview {
  TripBriefWorkflowView()
    .padding()
    .frame(minHeight: 800)
}
#Preview("With Sample Result") {
  let sampleResult = """
    ## Trip Brief: Tokyo, Japan

    **Weather:** Currently 18°C (64°F) with partly cloudy skies. Expect mild temperatures with a chance of light rain in the evening.

    **Key Insights:**
    - Visit Senso-ji Temple in Asakusa early morning to avoid crowds
    - The JR Pass offers unlimited travel on most JR trains and is essential for day trips
    - Try authentic ramen in the Shinjuku district, especially at Fuunji
    - Cherry blossom season (late March to early April) is peak tourist time
    - Don't miss the Shibuya Crossing experience at night

    **Source:** Lonely Planet Tokyo Travel Guide
    """

  VStack {
    TripBriefResultView(result: sampleResult)
  }
  .padding()
  .frame(minHeight: 600)
}


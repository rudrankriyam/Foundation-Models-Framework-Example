//
//  DynamicProfileBuilderView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct DynamicProfileBuilderView: View {
    @State private var currentPrompt = "Summarize this release note for developers."
    @State private var temperature = 0.4
    @State private var maxTokens = 240.0
    @State private var reasoningLevel = ReasoningLevelChoice.moderate
    @State private var toolMode = DynamicToolMode.allowed

    var body: some View {
        ExampleViewBase(
            title: "Dynamic Profile",
            description: "Compose Xcode 27 session profile options",
            defaultPrompt: "Summarize this release note for developers.",
            currentPrompt: $currentPrompt,
            codeExample: codeExample,
            onRun: {},
            onReset: reset
        ) {
            VStack(spacing: Spacing.medium) {
                Xcode27Section("Profile Controls", systemImage: "slider.horizontal.3") {
                    VStack(spacing: 16) {
                        labeledSlider("Temperature", value: $temperature, range: 0...1)
                        labeledSlider("Maximum tokens", value: $maxTokens, range: 64...1_000)

                        Picker("Reasoning", selection: $reasoningLevel) {
                            ForEach(ReasoningLevelChoice.allCases) { level in
                                Text(level.title).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("Tools", selection: $toolMode) {
                            ForEach(DynamicToolMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Xcode27Section("Generated Recipe", systemImage: "curlybraces") {
                    Text(recipePreview)
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private func labeledSlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(title == "Maximum tokens" ? "\(Int(value.wrappedValue))" : value.wrappedValue.formatted(.number.precision(.fractionLength(2))))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Slider(value: value, in: range)
                .accessibilityLabel(title)
        }
    }

    private var recipePreview: String {
        """
        temperature: \(temperature.formatted(.number.precision(.fractionLength(2))))
        maximumResponseTokens: \(Int(maxTokens))
        reasoningLevel: .\(reasoningLevel.rawValue)
        toolCallingMode: .\(toolMode.rawValue)
        """
    }

    private var codeExample: String {
        """
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
            let profile = LanguageModelSession.Profile {
                DynamicInstructions("Be concise and developer-focused.")
            }
            .temperature(\(temperature.formatted(.number.precision(.fractionLength(2)))))
            .maximumResponseTokens(\(Int(maxTokens)))
            .reasoningLevel(.\(reasoningLevel.rawValue))
            .toolCallingMode(.\(toolMode.rawValue))

            let session = LanguageModelSession(profile: profile)
        }
        """
    }

    private func reset() {
        currentPrompt = ""
        temperature = 0.4
        maxTokens = 240
        reasoningLevel = .moderate
        toolMode = .allowed
    }
}

private enum ReasoningLevelChoice: String, CaseIterable, Identifiable {
    case light
    case moderate
    case deep

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

private enum DynamicToolMode: String, CaseIterable, Identifiable {
    case allowed
    case required
    case disallowed

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

#Preview {
    NavigationStack {
        DynamicProfileBuilderView()
    }
}


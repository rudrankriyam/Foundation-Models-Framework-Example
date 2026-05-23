//
//  StudioView.swift
//  FoundationLab
//
//  Created by Codex on 4/26/26.
//

import SwiftUI

struct StudioView: View {
    @State private var searchText = ""
    @State private var selectedWorkspace: StudioWorkspace = .promptTesting

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xLarge) {
                studioHeader
                workspaceOverview
                selectedWorkspacePanel
                recentRunsSection

                if hasResults {
                    referenceLibrarySection
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
        }
        .navigationTitle("Studio")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .searchable(text: $searchText, prompt: "Search Studio")
        .navigationDestination(for: ExampleType.self) { exampleType in
            exampleType.destination
        }
        .navigationDestination(for: ToolExample.self) { tool in
            tool.destination
        }
        .navigationDestination(for: DynamicSchemaExampleType.self) { example in
            example.destination
        }
        .navigationDestination(for: LanguageExample.self) { languageExample in
            languageExample.destination
        }
    }

    private var studioHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack(alignment: .top, spacing: Spacing.medium) {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)
#if os(iOS) || os(macOS)
                    .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.medium))
#else
                    .background(Color.secondaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.medium))
#endif

                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text("Studio")
                        .font(.largeTitle.bold())

                    Text("Prompt tests, structured output validation, benchmark runs, and model capability maps for local Foundation Models.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: Spacing.small) {
                StudioPill(icon: "iphone.and.arrow.forward", title: "iPhone")
                StudioPill(icon: "macbook", title: "Mac")
                StudioPill(icon: "lock.shield", title: "On-device")
            }
        }
        .padding()
#if os(iOS) || os(macOS)
        .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.xLarge))
#else
        .background(Color.secondaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.xLarge))
#endif
        .accessibilityElement(children: .combine)
    }

    private var workspaceOverview: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader(
                title: "Workspaces",
                subtitle: "The Studio surface stays inside Foundation Lab."
            )

            LazyVGrid(columns: workspaceGridColumns, spacing: Spacing.large) {
                ForEach(StudioWorkspace.allCases) { workspace in
                    Button {
                        selectedWorkspace = workspace
                    } label: {
                        StudioWorkspaceCard(
                            workspace: workspace,
                            isSelected: selectedWorkspace == workspace
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var selectedWorkspacePanel: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            HStack(alignment: .center, spacing: Spacing.medium) {
                Label(selectedWorkspace.title, systemImage: selectedWorkspace.icon)
                    .font(.title3.bold())

                Spacer(minLength: 0)

                Text(selectedWorkspace.status)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .background(Color.secondaryBackgroundColor, in: .capsule)
            }

            Text(selectedWorkspace.subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)

            Divider()

            LazyVGrid(columns: detailGridColumns, spacing: Spacing.large) {
                StudioMetricBlock(
                    title: selectedWorkspace.metricTitle,
                    value: selectedWorkspace.metricValue,
                    systemImage: "chart.bar.xaxis"
                )

                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Milestones")
                        .font(.subheadline.weight(.semibold))

                    ForEach(selectedWorkspace.checkpoints, id: \.self) { checkpoint in
                        Label(checkpoint, systemImage: "circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .labelStyle(.titleAndIcon)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
#if os(iOS) || os(macOS)
        .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.large))
#else
        .background(Color.secondaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.large))
#endif
    }

    private var recentRunsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader(
                title: "Run Notes",
                subtitle: "Seed rows for the first Studio data model."
            )

            LazyVGrid(columns: runGridColumns, spacing: Spacing.large) {
                ForEach(StudioRunSummary.samples) { run in
                    StudioRunCard(run: run)
                }
            }
        }
    }

    private var referenceLibrarySection: some View {
        VStack(alignment: .leading, spacing: Spacing.xLarge) {
            SectionHeader(
                title: "Reference Library",
                subtitle: "Current Foundation Lab examples linked from Studio."
            )

            examplesSection
            toolsSection
            schemasSection
            languagesSection
        }
    }

    private var examplesSection: some View {
        StudioSection(
            title: "Model Controls",
            subtitle: "Generation options, guides, and structured output."
        ) {
            ForEach(filteredStudioExamples) { exampleType in
                NavigationLink(value: exampleType) {
                    GenericCardView(
                        icon: exampleType.icon,
                        title: exampleType.title,
                        subtitle: exampleType.subtitle
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var toolsSection: some View {
        StudioSection(
            title: "Tools",
            subtitle: "System capabilities the model can call."
        ) {
            ForEach(filteredTools, id: \.self) { tool in
                NavigationLink(value: tool) {
                    GenericCardView(
                        icon: tool.icon,
                        title: tool.displayName,
                        subtitle: tool.shortDescription
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var schemasSection: some View {
        StudioSection(
            title: "Dynamic Schemas",
            subtitle: "Build and validate generation schemas."
        ) {
            ForEach(filteredSchemas) { example in
                NavigationLink(value: example) {
                    GenericCardView(
                        icon: example.icon,
                        title: example.title,
                        subtitle: example.subtitle
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var languagesSection: some View {
        StudioSection(
            title: "Languages",
            subtitle: "Detect, select, and manage multilingual sessions."
        ) {
            ForEach(filteredLanguages) { languageExample in
                NavigationLink(value: languageExample) {
                    GenericCardView(
                        icon: languageExample.icon,
                        title: languageExample.title,
                        subtitle: languageExample.subtitle
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var filteredStudioExamples: [ExampleType] {
        ExampleType.studioExamples.filter { matches($0.title, $0.subtitle) }
    }

    private var filteredTools: [ToolExample] {
        ToolExample.allCases.filter { matches($0.displayName, $0.shortDescription) }
    }

    private var filteredSchemas: [DynamicSchemaExampleType] {
        DynamicSchemaExampleType.allCases.filter { matches($0.title, $0.subtitle) }
    }

    private var filteredLanguages: [LanguageExample] {
        LanguageExample.allCases.filter { matches($0.title, $0.subtitle) }
    }

    private var hasResults: Bool {
        !filteredStudioExamples.isEmpty ||
        !filteredTools.isEmpty ||
        !filteredSchemas.isEmpty ||
        !filteredLanguages.isEmpty
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func matches(_ title: String, _ subtitle: String) -> Bool {
        let query = trimmedSearchText
        guard !query.isEmpty else { return true }

        return title.localizedStandardContains(query) ||
        subtitle.localizedStandardContains(query)
    }
}

private struct StudioSection<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            SectionHeader(title: title, subtitle: subtitle)

            LazyVGrid(columns: adaptiveGridColumns, spacing: Spacing.large) {
                content
            }
        }
    }

    private var adaptiveGridColumns: [GridItem] {
#if os(iOS)
        [
            GridItem(.flexible(minimum: 140), spacing: Spacing.large),
            GridItem(.flexible(minimum: 140), spacing: Spacing.large)
        ]
#else
        [GridItem(.adaptive(minimum: 240), spacing: Spacing.large)]
#endif
    }
}

private struct StudioWorkspaceCard: View {
    let workspace: StudioWorkspace
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack(alignment: .center, spacing: Spacing.medium) {
                Image(systemName: workspace.icon)
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .frame(width: 32, height: 32)

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.body)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            }

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(workspace.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(workspace.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: Spacing.small) {
                Text(workspace.metricValue)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                Text(workspace.metricTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .contentShape(.rect)
#if os(iOS) || os(macOS)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: CornerRadius.large))
#else
        .background(Color.secondaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.large))
#endif
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct StudioMetricBlock: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(value)
                    .font(.title2.bold())

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StudioRunCard: View {
    let run: StudioRunSummary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                Text(run.name)
                    .font(.headline)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text(run.score)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.tint)
            }

            Text(run.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
#if os(iOS) || os(macOS)
        .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.large))
#else
        .background(Color.secondaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.large))
#endif
        .accessibilityElement(children: .combine)
    }
}

private struct StudioPill: View {
    let icon: String
    let title: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(Color.secondaryBackgroundColor, in: .capsule)
    }
}

private extension StudioView {
    var workspaceGridColumns: [GridItem] {
#if os(iOS)
        [
            GridItem(.flexible(minimum: 150), spacing: Spacing.large),
            GridItem(.flexible(minimum: 150), spacing: Spacing.large)
        ]
#else
        [GridItem(.adaptive(minimum: 220), spacing: Spacing.large)]
#endif
    }

    var detailGridColumns: [GridItem] {
#if os(iOS)
        [GridItem(.flexible(minimum: 180), spacing: Spacing.large)]
#else
        [
            GridItem(.fixed(180), spacing: Spacing.large),
            GridItem(.flexible(minimum: 240), spacing: Spacing.large)
        ]
#endif
    }

    var runGridColumns: [GridItem] {
#if os(iOS)
        [GridItem(.flexible(minimum: 220), spacing: Spacing.large)]
#else
        [GridItem(.adaptive(minimum: 260), spacing: Spacing.large)]
#endif
    }
}

#Preview {
    NavigationStack {
        StudioView()
    }
}

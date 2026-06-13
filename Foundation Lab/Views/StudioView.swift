//
//  StudioView.swift
//  FoundationLab
//
//  Created by Codex on 4/26/26.
//

import SwiftUI
import FoundationLabCore

struct StudioView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var selectedWorkspace: StudioWorkspace = .promptTesting
    @State private var selectedStage: StudioPipelineStage = .settings
    @State private var promptText = "Summarize what makes Apple Foundation Models useful for an offline journaling app."
    @State private var selectedPromptVariants: Set<StudioPromptVariant> = Set(StudioPromptVariant.allCases)
    @State private var promptRuns: [StudioPromptRun] = []
    @State private var selectedPromptRun: StudioPromptRun?
    @State private var isRunningPromptTests = false
    @State private var promptTestError: String?
    @State private var studioCreatedAt = Date.now

#if os(macOS)
    @State private var adapterStudioViewModel = AdapterStudioViewModel()
#endif

    private let generateTextUseCase = GenerateTextUseCase()

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                compactLayout
            } else {
                workbenchLayout
            }
        }
        .navigationTitle("Studio")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
#if os(iOS)
            if selectedWorkspace == .promptTesting {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: runPromptTests) {
                        Label("Run", systemImage: isRunningPromptTests ? "hourglass" : "play.fill")
                    }
                    .disabled(isRunningPromptTests || !canRunPromptTests)
                }
            }
#endif
        }
    }

    private var workbenchLayout: some View {
        VStack(spacing: 0) {
#if os(macOS)
            GeometryReader { proxy in
                if proxy.size.width < 920 {
                    narrowWorkbenchLayout
                } else {
                    HSplitView {
                        primaryWorkbenchColumn
                            .frame(minWidth: 0, idealWidth: 820, maxWidth: .infinity, maxHeight: .infinity)
                            .layoutPriority(1)

                        activityInspector
                            .frame(minWidth: 240, idealWidth: 300, maxWidth: 320)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
#else
            HStack(spacing: 0) {
                studioSourceList
                    .frame(width: 250)

                Divider()

                VStack(spacing: 0) {
                    stageBar
                    Divider()
                    mainWorkspace
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                activityInspector
                    .frame(width: 280)
            }
#endif

            Divider()
            statusBar
        }
        .background(Color.secondaryBackgroundColor.opacity(0.28))
    }

    private var primaryWorkbenchColumn: some View {
        VStack(spacing: 0) {
            stageBar
            Divider()
            mainWorkspace
        }
    }

    private var narrowWorkbenchLayout: some View {
        VStack(spacing: 0) {
            stageBar
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    workspaceHeader
                    compactStageContent
                }
                .padding()
            }
        }
    }

    private var compactLayout: some View {
        VStack(spacing: 0) {
            compactStageBar
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    compactWorkspacePicker
                    compactStageContent
                    activityInspectorContent
                }
                .padding()
            }
        }
    }

    private var studioSourceList: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("Foundation Lab")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Label("Local Evaluation Studio", systemImage: "doc.text.magnifyingglass")
                    .font(.headline)
            }

            sourceSection("Workspaces") {
                ForEach(StudioWorkspace.allCases) { workspace in
                    sourceRow(
                        title: workspace.title,
                        subtitle: workspace.status,
                        systemImage: workspace.icon,
                        isSelected: selectedWorkspace == workspace
                    ) {
                        selectedWorkspace = workspace
                    }
                }
            }

            workspaceSources

            Spacer(minLength: 0)
        }
        .padding(Spacing.large)
        .background(.regularMaterial)
    }

    @ViewBuilder
    private var workspaceSources: some View {
        switch selectedWorkspace {
        case .promptTesting:
            sourceSection("Prompt Sources") {
                ForEach(StudioPromptVariant.allCases) { variant in
                    sourceRow(
                        title: variant.title,
                        subtitle: selectedPromptVariants.contains(variant) ? "Included" : "Excluded",
                        systemImage: selectedPromptVariants.contains(variant) ? "checkmark.square.fill" : "square",
                        isSelected: selectedPromptVariants.contains(variant)
                    ) {
                        togglePromptVariant(variant)
                    }
                }
            }
        case .benchmarkRuns:
            sourceSection("Runners") {
                sourceInfoRow(title: "Mac CLI", subtitle: "Publishable", systemImage: "terminal")
                sourceInfoRow(title: "Device Runner", subtitle: "iPhone and iPad", systemImage: "iphone")
                sourceInfoRow(title: "Simulator", subtitle: "Validation only", systemImage: "hammer")
            }
        case .adapterComparison:
            sourceSection("Surfaces") {
                sourceInfoRow(title: "Base Model", subtitle: "Fresh session", systemImage: "cpu")
                sourceInfoRow(title: "Custom Adapter", subtitle: ".fmadapter", systemImage: "shippingbox")
                sourceInfoRow(title: "Training CLI", subtitle: "fmas", systemImage: "terminal")
            }
        case .structuredOutput, .capabilityMatrix:
            EmptyView()
        }
    }

    private func sourceSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            VStack(spacing: Spacing.xSmall) {
                content()
            }
        }
    }

    private func sourceInfoRow(title: String, subtitle: String, systemImage: String) -> some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: systemImage)
                .font(.body)
                .frame(width: 20)

            Text(title)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .font(.callout)
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
    }

    private func sourceRow(
        title: String,
        subtitle: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: Spacing.small) {
                Image(systemName: systemImage)
                    .font(.body)
                    .frame(width: 20)

                Text(title)
                    .lineLimit(1)

                Spacer(minLength: 0)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white.opacity(0.86) : .secondary)
                    .lineLimit(1)
            }
            .font(.callout)
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(isSelected ? Color.accentColor : Color.clear, in: .rect(cornerRadius: CornerRadius.small))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var stageBar: some View {
        HStack(spacing: Spacing.large) {
#if os(macOS)
            Picker("Workspace", selection: $selectedWorkspace) {
                ForEach(StudioWorkspace.allCases) { workspace in
                    Label(workspace.title, systemImage: workspace.icon)
                        .tag(workspace)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 220)

            if selectedWorkspace == .promptTesting {
                Button(
                    "Run selected prompt variants",
                    systemImage: isRunningPromptTests ? "hourglass" : "play.fill",
                    action: runPromptTests
                )
                .labelStyle(.iconOnly)
                .font(.title3)
                .frame(width: 34, height: 34)
                .buttonStyle(.borderless)
                .disabled(isRunningPromptTests || !canRunPromptTests)
                .help("Run selected prompt variants")
            }
#endif

            Picker("Stage", selection: $selectedStage) {
                ForEach(StudioPipelineStage.allCases) { stage in
                    Label(stage.title, systemImage: stage.systemImage)
                        .tag(stage)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 560)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.small)
        .background(.bar)
    }

    private var compactStageBar: some View {
        HStack(spacing: Spacing.xSmall) {
            ForEach(StudioPipelineStage.allCases) { stage in
                Button {
                    selectedStage = stage
                } label: {
                    Text(stage.title)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .foregroundStyle(selectedStage == stage ? .white : .primary)
                        .background(
                            selectedStage == stage ? Color.accentColor : Color.secondaryBackgroundColor,
                            in: .capsule
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(.bar)
    }

    private var mainWorkspace: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xLarge) {
                workspaceHeader
                stageContent
            }
            .padding(.horizontal, 34)
            .padding(.vertical, Spacing.xLarge)
            .frame(maxWidth: 960, alignment: .leading)
        }
        .background(.background)
    }

    private var workspaceHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(selectedWorkspace.title)
                .font(.title.bold())

            Text(selectedWorkspace.subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var stageContent: some View {
        if selectedWorkspace == .adapterComparison {
            adapterStudioContent
        } else if selectedWorkspace == .benchmarkRuns {
            AppBenchStudioContent(stage: selectedStage)
        } else {
            switch selectedStage {
            case .settings:
                promptSettingsContent
            case .runs:
                runsContent
            case .evaluation:
                evaluationContent
            case .preview:
                previewContent
            case .output:
                outputContent
            }
        }
    }

    @ViewBuilder
    private var compactStageContent: some View {
        if selectedWorkspace == .adapterComparison {
            adapterStudioContent
        } else if selectedWorkspace == .benchmarkRuns {
            AppBenchStudioContent(stage: selectedStage)
        } else {
            switch selectedStage {
            case .settings:
                compactPromptSettingsContent
            case .runs:
                runsContent
            case .evaluation:
                evaluationContent
            case .preview:
                previewContent
            case .output:
                outputContent
            }
        }
    }

    @ViewBuilder
    private var adapterStudioContent: some View {
#if os(macOS)
        AdapterStudioContent(
            stage: selectedStage,
            viewModel: adapterStudioViewModel
        )
#else
        AdapterStudioContent(stage: selectedStage)
#endif
    }

    private var promptSettingsContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xLarge) {
            settingsPanel(title: "Data") {
                HStack(alignment: .top, spacing: Spacing.large) {
                    promptDataSlot(
                        title: "Base Prompt",
                        systemImage: "text.quote",
                        isEnabled: true
                    ) {
                        TextEditor(text: $promptText)
                            .font(.body)
                            .frame(minHeight: 140)
                            .scrollContentBackground(.hidden)
                            .padding(Spacing.small)
                            .background(Color.tertiaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.large))
                    }

                    promptDataSlot(
                        title: "Variants",
                        systemImage: "square.stack.3d.up",
                        isEnabled: !selectedPromptVariants.isEmpty
                    ) {
                        VStack(alignment: .leading, spacing: Spacing.small) {
                            ForEach(StudioPromptVariant.allCases) { variant in
                                Toggle(isOn: variantBinding(for: variant)) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(variant.title)
                                            .font(.callout)
                                        Text(variant.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            settingsPanel(title: "Parameters") {
                VStack(spacing: 0) {
                    parameterRow(title: "Execution", value: "Sequential local runs")
                    parameterRow(title: "Selected Variants", value: "\(selectedPromptVariants.count)")
                    parameterRow(title: "Prompt Characters", value: "\(promptText.count)")
                    parameterRow(title: "Result Capture", value: "Output, latency, token count")
                }
            }

            if let promptTestError {
                Label(promptTestError, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
            }
        }
    }

    private var compactPromptSettingsContent: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            compactPanel(title: "Base Prompt", systemImage: "text.quote") {
                TextEditor(text: $promptText)
                    .font(.body)
                    .frame(minHeight: 180)
                    .scrollContentBackground(.hidden)
                    .padding(Spacing.small)
                    .background(.background, in: .rect(cornerRadius: CornerRadius.small))
            }

            compactPanel(title: "Variants", systemImage: "square.stack.3d.up") {
                VStack(spacing: 0) {
                    ForEach(StudioPromptVariant.allCases) { variant in
                        Toggle(isOn: variantBinding(for: variant)) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(variant.title)
                                    .font(.callout.weight(.semibold))

                                Text(variant.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.vertical, Spacing.medium)

                        if variant != StudioPromptVariant.allCases.last {
                            Divider()
                        }
                    }
                }
            }

            compactPanel(title: "Run Configuration", systemImage: "slider.horizontal.3") {
                VStack(spacing: 0) {
                    compactParameterRow(title: "Execution", value: "Sequential")
                    compactParameterRow(title: "Variants", value: "\(selectedPromptVariants.count)")
                    compactParameterRow(title: "Prompt", value: "\(promptText.count) characters")
                    compactParameterRow(title: "Capture", value: "Output, latency, tokens")
                }
            }

            if let promptTestError {
                Label(promptTestError, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
            }
        }
    }

    private func compactPanel<Content: View>(
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            content()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tertiaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.large))
    }

    private func compactParameterRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.callout.weight(.medium))

            Spacer(minLength: Spacing.medium)

            Text(value)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, Spacing.small)
    }

    private func settingsPanel<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            Text(title)
                .font(.title3.bold())

            content()
        }
    }

    private func promptDataSlot<Content: View>(
        title: String,
        systemImage: String,
        isEnabled: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                    .foregroundStyle(isEnabled ? .primary : .secondary)

                Spacer(minLength: 0)

                Image(systemName: "questionmark.circle")
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
            .background(Color.tertiaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.large))

            content()

            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 260, alignment: .topLeading)
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(.quaternary, lineWidth: 1)
        }
    }

    private func parameterRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.callout.weight(.medium))
                .frame(width: 170, alignment: .trailing)

            Text(value)
                .font(.callout)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.medium)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var runsContent: some View {
        Group {
            if promptRuns.isEmpty, isRunningPromptTests {
                runningPromptState
            } else if promptRuns.isEmpty {
                unavailableState(
                    title: "Prompt runs unavailable",
                    subtitle: "Set up the prompt source and run selected variants to view run progress."
                )
            } else {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    ForEach(promptRuns) { run in
                        runRow(run)
                        Divider()
                    }
                }
            }
        }
    }

    private var runningPromptState: some View {
        VStack(spacing: Spacing.medium) {
            Spacer(minLength: 120)

            ProgressView()
                .controlSize(.large)

            Text("Running selected variants")
                .font(.headline)

            Text("Results will appear here as soon as the first prompt run finishes.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer(minLength: 120)
        }
        .frame(maxWidth: .infinity)
    }

    private func runRow(_ run: StudioPromptRun) -> some View {
        Button {
            selectedPromptRun = run
        } label: {
            HStack(alignment: .top, spacing: Spacing.large) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(run.variant.title)
                        .font(.headline)
                    Text(run.finishedAt, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 150, alignment: .leading)

                Text(run.output)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(run.durationLabel)
                        .font(.headline.monospacedDigit())
                    Text(run.tokenLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 100, alignment: .trailing)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .padding(.vertical, Spacing.small)
        .help("Show full prompt run")
        .popover(
            isPresented: Binding(
                get: { selectedPromptRun?.id == run.id },
                set: { isPresented in
                    if !isPresented, selectedPromptRun?.id == run.id {
                        selectedPromptRun = nil
                    }
                }
            ),
            arrowEdge: .trailing
        ) {
            runDetailPopover(run)
                .presentationCompactAdaptation(.popover)
        }
    }

    private func runDetailPopover(_ run: StudioPromptRun) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(run.variant.title)
                        .font(.headline)
                    Text(run.finishedAt, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(run.durationLabel)
                        .font(.headline.monospacedDigit())
                    Text(run.tokenLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("Prompt")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(run.prompt)
                    .font(.callout)
                    .textSelection(.enabled)
            }

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("Output")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ScrollView {
                    Text(run.output)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 260)
            }
        }
        .padding()
        .frame(width: 420)
    }

    private var evaluationContent: some View {
        Group {
            if promptRuns.isEmpty {
                unavailableState(
                    title: "Evaluation unavailable",
                    subtitle: "Run at least one variant to compare latency, tokens, and answer shape."
                )
            } else {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    settingsPanel(title: "Comparison") {
                        VStack(spacing: 0) {
                            ForEach(promptRuns) { run in
                                parameterRow(title: run.variant.title, value: "\(run.durationLabel) • \(run.tokenLabel)")
                            }
                        }
                    }
                }
            }
        }
    }

    private var previewContent: some View {
        Group {
            if let latestRun = latestFinishedRun {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Text(latestRun.variant.title)
                        .font(.title3.bold())
                    Text(latestRun.output)
                        .font(.body)
                        .textSelection(.enabled)
                }
            } else {
                unavailableState(
                    title: "Preview unavailable",
                    subtitle: "Run a prompt variant to preview the most recent generated output."
                )
            }
        }
    }

    private var outputContent: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            settingsPanel(title: "Run Artifact") {
                VStack(spacing: 0) {
                    parameterRow(title: "Format", value: "Studio run summary")
                    parameterRow(title: "Runs", value: "\(promptRuns.count)")
                    parameterRow(title: "Status", value: promptRuns.isEmpty ? "No exportable runs" : "Ready")
                }
            }

            Button {
                selectedStage = .runs
            } label: {
                Label("Review Runs", systemImage: "doc.text.magnifyingglass")
            }
            .disabled(promptRuns.isEmpty)
        }
    }

    private func unavailableState(title: String, subtitle: String) -> some View {
        VStack(spacing: Spacing.medium) {
            Spacer(minLength: 120)

            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer(minLength: 120)
        }
        .frame(maxWidth: .infinity)
    }

    private var activityInspector: some View {
        VStack(spacing: 0) {
            activityInspectorContent
            Spacer(minLength: 0)
        }
        .background(Color.secondaryBackgroundColor.opacity(0.45))
    }

    @ViewBuilder
    private var activityInspectorContent: some View {
        if selectedWorkspace == .adapterComparison {
            AdapterStudioInspector()
        } else if selectedWorkspace == .benchmarkRuns {
            AppBenchStudioInspector()
        } else {
            VStack(alignment: .leading, spacing: Spacing.large) {
                inspectorMetrics

                VStack(alignment: .leading, spacing: Spacing.small) {
                    HStack {
                        Text("Activity")
                            .font(.headline)
                        Spacer()
                        Text(Date.now, style: .date)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    ForEach(activityEvents) { event in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(event.title)
                                    .font(.callout)
                                Spacer()
                                Text(event.date, style: .time)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }

                            Text(event.detail)
                                .font(.callout.weight(.semibold))
                        }
                        .padding(.vertical, Spacing.small)

                        Divider()
                    }
                }
            }
            .padding(Spacing.large)
        }
    }

    private var inspectorMetrics: some View {
        HStack(spacing: 0) {
            inspectorMetric(value: "\(promptRuns.count)", title: "Runs")
            Divider()
            inspectorMetric(value: averageDurationLabel, title: "Average")
            Divider()
            inspectorMetric(value: "\(selectedPromptVariants.count)", title: "Variants")
        }
        .frame(height: 52)
    }

    private func inspectorMetric(value: String, title: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.monospacedDigit())
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var compactWorkspacePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            HStack(alignment: .firstTextBaseline) {
                Text("Workspace")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: Spacing.medium)

                Menu {
                    Picker("Workspace", selection: $selectedWorkspace) {
                        ForEach(StudioWorkspace.allCases) { workspace in
                            Label(workspace.title, systemImage: workspace.icon)
                                .tag(workspace)
                        }
                    }
                } label: {
                    HStack(spacing: Spacing.xSmall) {
                        Text(selectedWorkspace.title)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2.weight(.semibold))
                    }
                    .font(.callout.weight(.medium))
                }
                .buttonStyle(.plain)
            }

            Text(selectedWorkspace.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusBar: some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)

            Text(statusText)
                .font(.callout.weight(.medium))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.xSmall)
        .background(.bar)
    }

    private var canRunPromptTests: Bool {
        selectedWorkspace == .promptTesting &&
        !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedPromptVariants.isEmpty
    }

    private var averageDurationLabel: String {
        guard !promptRuns.isEmpty else { return "--" }
        let totalDuration = promptRuns.reduce(0) { $0 + $1.duration }
        return (totalDuration / Double(promptRuns.count)).formatted(.number.precision(.fractionLength(2))) + "s"
    }

    private var latestFinishedRun: StudioPromptRun? {
        promptRuns.max { $0.finishedAt < $1.finishedAt }
    }

    private var activityEvents: [StudioActivityEvent] {
        if promptRuns.isEmpty {
            return [
                StudioActivityEvent(
                    id: "studio-created",
                    title: "Studio Created",
                    detail: "Local Evaluation Studio",
                    date: studioCreatedAt
                )
            ]
        }

        return promptRuns.prefix(6).map {
            StudioActivityEvent(
                id: $0.id.uuidString,
                title: "Prompt Variant Completed",
                detail: $0.variant.title,
                date: $0.finishedAt
            )
        }
    }

    private var statusIcon: String {
        if selectedWorkspace == .adapterComparison { return "shippingbox.fill" }
        if selectedWorkspace == .benchmarkRuns { return "checkmark.circle.fill" }
        if isRunningPromptTests { return "hourglass" }
        if promptRuns.isEmpty { return "info.circle.fill" }
        return "checkmark.circle.fill"
    }

    private var statusColor: Color {
        if selectedWorkspace == .adapterComparison { return .blue }
        if selectedWorkspace == .benchmarkRuns { return .green }
        if isRunningPromptTests { return .orange }
        if promptRuns.isEmpty { return .secondary }
        return .green
    }

    private var statusText: String {
        if selectedWorkspace == .adapterComparison {
#if os(macOS)
            return "Adapter comparison is available locally on this Mac"
#else
            return "Adapter comparison requires Foundation Lab for macOS"
#endif
        }
        if selectedWorkspace == .benchmarkRuns {
            return "AppBench is available through the Mac CLI and physical-device runner"
        }
        if isRunningPromptTests { return "Running selected prompt variants" }
        if promptRuns.isEmpty { return "Prompt run required" }
        return "\(promptRuns.count) prompt runs completed"
    }

    private func variantBinding(for variant: StudioPromptVariant) -> Binding<Bool> {
        Binding {
            selectedPromptVariants.contains(variant)
        } set: { isSelected in
            if isSelected {
                selectedPromptVariants.insert(variant)
            } else {
                selectedPromptVariants.remove(variant)
            }
        }
    }

    private func togglePromptVariant(_ variant: StudioPromptVariant) {
        if selectedPromptVariants.contains(variant) {
            selectedPromptVariants.remove(variant)
        } else {
            selectedPromptVariants.insert(variant)
        }
    }

    private func runPromptTests() {
        guard canRunPromptTests, !isRunningPromptTests else { return }

        isRunningPromptTests = true

        Task {
            await performPromptTests()
        }
    }

    @MainActor
    private func performPromptTests() async {
        let trimmedPrompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty, !selectedPromptVariants.isEmpty else {
            isRunningPromptTests = false
            return
        }

        promptTestError = nil
        selectedStage = .runs
        defer { isRunningPromptTests = false }

        var newRuns: [StudioPromptRun] = []
        let variants = StudioPromptVariant.allCases.filter { selectedPromptVariants.contains($0) }

        do {
            for variant in variants {
                let startedAt = Date()
                let result = try await generateTextUseCase.execute(
                    TextGenerationRequest(
                        prompt: trimmedPrompt,
                        systemPrompt: variant.systemPrompt,
                        generationOptions: variant.generationOptions,
                        context: CapabilityInvocationContext(
                            source: .app,
                            localeIdentifier: Locale.current.identifier
                        )
                    )
                )

                newRuns.append(
                    StudioPromptRun(
                        variant: variant,
                        prompt: trimmedPrompt,
                        output: result.content,
                        duration: Date().timeIntervalSince(startedAt),
                        tokenCount: result.metadata.tokenCount,
                        finishedAt: Date()
                    )
                )
            }

            promptRuns = newRuns + promptRuns
        } catch {
            if !newRuns.isEmpty {
                promptRuns = newRuns + promptRuns
            }

            promptTestError = error.localizedDescription
            selectedStage = newRuns.isEmpty ? .settings : .runs
        }
    }
}

#Preview {
    NavigationStack {
        StudioView()
    }
}

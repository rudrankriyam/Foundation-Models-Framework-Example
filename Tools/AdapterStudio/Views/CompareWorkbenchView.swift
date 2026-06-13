//
//  CompareWorkbenchView.swift
//  Adapter Studio
//
//  Created by Rudrank Riyam on 10/22/25.
//

import SwiftUI
import Observation
import Foundation

#if canImport(AppKit)
import AppKit
#endif

import LiquidGlasKit

/// Primary workspace for running side-by-side model comparisons.
struct CompareWorkbenchView: View {
    @State private var compareViewModel: CompareViewModel
    @State private var adapterProvider: AdapterProvider?
    @State private var adapterInitializationError: String?

    @FocusState private var promptIsFocused: Bool

    init() {
        _compareViewModel = State(initialValue: CompareViewModel())

        do {
            let provider = try AdapterProvider()
            _adapterProvider = State(initialValue: provider)
            _adapterInitializationError = State(initialValue: nil)
        } catch {
            _adapterProvider = State(initialValue: nil)
            _adapterInitializationError = State(initialValue: error.localizedDescription)
        }
    }

    var body: some View {
        @Bindable var viewModel = compareViewModel

        NavigationStack {
            ZStack(alignment: .top) {
                background

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header(viewModel: viewModel, context: currentAdapterContext)
                        promptSection(prompt: $viewModel.prompt, isRunning: viewModel.isRunning)
                        comparisonColumns(viewModel: viewModel, context: currentAdapterContext)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            configureEngineIfNeeded()
        }
        .onChange(of: adapterProvider?.context?.metadata.location) { _, _ in
            configureEngineIfNeeded()
        }
        .alert("Adapter Provider Error", isPresented: Binding(
            get: { adapterInitializationError != nil },
            set: { newValue in
                if newValue == false {
                    adapterInitializationError = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {
                adapterInitializationError = nil
            }
        } message: {
            Text(adapterInitializationError ?? "")
        }
    }
}

private extension CompareWorkbenchView {
    var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.09, blue: 0.12),
                Color(red: 0.05, green: 0.05, blue: 0.07)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
            .ignoresSafeArea()
    }

    var currentAdapterContext: AdapterContext? {
        adapterProvider?.context
    }

    func header(viewModel: CompareViewModel, context: AdapterContext?) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Adapter Studio")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text(statusDescription(for: viewModel.state))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }

                Spacer()

                if viewModel.isRunning {
                    Button(action: cancelRun) {
                        Label("Cancel", systemImage: "stop.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }

            adapterStatusView(context: context)
        }
    }

    func promptSection(prompt: Binding<String>, isRunning: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prompt")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.85))

            TextEditor(text: prompt)
                .focused($promptIsFocused)
                .padding(12)
                .frame(minHeight: 140)
                .scrollContentBackground(.hidden)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isRunning ? Color.blue.opacity(0.6) : Color.white.opacity(0.1), lineWidth: 1)
                )
                .textSelection(.enabled)

            HStack {
                Button(
                    action: { prompt.wrappedValue = "" },
                    label: {
                        Label("Clear", systemImage: "eraser")
                    }
                )
                .disabled(prompt.wrappedValue.isEmpty)

                Spacer()

                Button(
                    action: runCurrentPrompt,
                    label: {
                        Label(isRunning ? "Running" : "Run", systemImage: isRunning ? "hourglass" : "play.fill")
                    }
                )
                .disabled(prompt.wrappedValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isRunning)
            }
        }
        .padding()
        .glassCard(radius: 24)
    }

    func comparisonColumns(viewModel: CompareViewModel, context: AdapterContext?) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Responses")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.85))

            HStack(alignment: .top, spacing: 16) {
                SessionColumnView(
                    title: "Base",
                    subtitle: "System Language Model",
                    column: viewModel.baseColumn,
                    isActive: viewModel.isRunning
                )

                SessionColumnView(
                    title: "Adapter",
                    subtitle: context?.metadata.fileName ?? "No Adapter Selected",
                    column: viewModel.adapterColumn,
                    isActive: viewModel.isRunning
                )
            }
        }
        .padding()
        .glassCard(radius: 24)
    }

    @ViewBuilder
    func adapterStatusView(context: AdapterContext?) -> some View {
        if let context {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 12) {
                    Label("Adapter Loaded", systemImage: "checkmark.seal.fill")

                    Spacer()

                    Button(action: reopenAdaptersDirectory) {
                        Label("Show in Finder", systemImage: "folder")
                    }

                    VStack(alignment: .trailing) {
                        Button(action: importAdapter) {
                            Label("Import Adapter", systemImage: "tray.and.arrow.down")
                        }

                        existingAdaptersMenu
                    }
                }

                metadataGrid(for: context.metadata)
            }
        } else {
            HStack(spacing: 12) {
                Label("No adapter selected", systemImage: "exclamationmark.triangle")

                Spacer()

                VStack(alignment: .trailing) {
                    Button(action: importAdapter) {
                        Label("Import Adapter", systemImage: "tray.and.arrow.down")
                    }

                    existingAdaptersMenu
                }
            }
        }
    }

    func metadataGrid(for metadata: AdapterMetadata) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            LabeledContent("Name") {
                Text(metadata.fileName)
                    .foregroundStyle(.white)
            }
            .foregroundStyle(.white.opacity(0.6))

            if let modified = metadata.modifiedAt {
                LabeledContent("Modified") {
                    Text(modifiedFormatted(modified))
                        .foregroundStyle(.white)
                }
                .foregroundStyle(.white.opacity(0.6))
            }

            LabeledContent("Size") {
                Text(byteCountFormatter.string(fromByteCount: Int64(metadata.fileSize)))
                    .foregroundStyle(.white)
            }
            .foregroundStyle(.white.opacity(0.6))
        }
    }

    var existingAdaptersMenu: some View {
        Menu {
            if let provider = adapterProvider {
                let urls = provider.availableAdapterURLs()
                if urls.isEmpty {
                    Text("No saved adapters")
                } else {
                    ForEach(urls, id: \.self) { url in
                        Button(url.lastPathComponent) {
                            loadAdapter(at: url)
                        }
                    }
                    Divider()
                    Button("Reload Active Adapter") {
                        if let current = provider.context?.metadata.location {
                            loadAdapter(at: current)
                        }
                    }
                }
            } else {
                Text("Provider unavailable")
            }
        } label: {
            Label("Adapters", systemImage: "arrow.2.circlepath")
        }
    }

    func statusDescription(for state: CompareViewModel.State) -> String {
        switch state {
        case .idle:
            return "Ready for comparison"
        case .running(let prompt):
            return "Running comparison for \(truncatedPrompt(prompt))"
        case .failed(let message):
            return "Failed: \(message)"
        case .completed:
            return "Comparison complete"
        }
    }

    func runCurrentPrompt() {
        compareViewModel.submitCurrentPrompt()
    }

    func cancelRun() {
        compareViewModel.cancel()
    }

    func importAdapter() {
        guard let provider = adapterProvider else { return }
        provider.selectAndLoadAdapter()
        compareViewModel.configureAdapter(provider.context)
        if let error = provider.lastError {
            adapterInitializationError = error.localizedDescription
        } else {
            adapterInitializationError = nil
        }
    }

    func loadAdapter(at url: URL) {
        guard let provider = adapterProvider else { return }
        provider.loadExistingAdapter(at: url)
        compareViewModel.configureAdapter(provider.context)
        if let error = provider.lastError {
            adapterInitializationError = error.localizedDescription
        } else {
            adapterInitializationError = nil
        }
    }

    func reopenAdaptersDirectory() {
        guard let directory = try? AdapterProvider.defaultAdaptersDirectory() else { return }

        NSWorkspace.shared.activateFileViewerSelecting([directory])
    }

    func configureEngineIfNeeded() {
        compareViewModel.configureAdapter(adapterProvider?.context)
    }

    func modifiedFormatted(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    func truncatedPrompt(_ prompt: String) -> String {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 40 else { return trimmed }
        let prefix = trimmed.prefix(37)
        return "\(prefix)…"
    }

    func stateIdentifier(for state: CompareViewModel.State) -> String {
        switch state {
        case .idle:
            return "idle"
        case .running(let prompt):
            return "running_\(prompt.hashValue)"
        case .failed(let message):
            return "failed_\(message.hashValue)"
        case .completed(let result):
            return "completed_\(result.prompt.hashValue)"
        }
    }

}

private let byteCountFormatter: ByteCountFormatter = {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useMB, .useGB]
    formatter.countStyle = .file
    return formatter
}()

#if DEBUG
#Preview {
    CompareWorkbenchView()
        .frame(width: 1200, height: 820)
}
#endif

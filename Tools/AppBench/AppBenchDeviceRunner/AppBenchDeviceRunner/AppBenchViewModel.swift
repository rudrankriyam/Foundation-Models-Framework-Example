import AppBenchCore
import Observation
import SwiftUI

@MainActor
@Observable
final class AppBenchViewModel {
    var selectedSuite: AppBenchSuite = .quick {
        didSet {
            guard selectedSuite != oldValue else { return }
            applySampleDefaults(for: selectedSuite)
        }
    }
    var selectedModel: AppBenchModel = .onDevice
    var selectedSessionMode: AppBenchSessionMode = .cold
    var selectedReasoningLevel: AppBenchReasoningLevel = .none
    var selectedFallbackMode: AppBenchFallbackMode = .disabled
    var selectedConnectivity: AppBenchConnectivity = .normal
    var warmupCount = 5
    var repetitions = 20
    var samplesPerScenario = 1
    var useAllSamples = false
    var randomizeOrder = true
    var randomSeed: UInt64 = 20_260_929
    var isRunning = false
    var result: AppBenchRunResult?
    var errorMessage = ""
    var showError = false

    var selectedScenarios: [AppBenchScenario] {
        AppBenchScenarioCatalog.scenarios(for: selectedSuite)
    }

    func run() {
        guard !isRunning else { return }

        isRunning = true
        result = nil

        let configuration = makeConfiguration()

        Task {
            do {
                result = try await AppBenchRunner(configuration: configuration).run()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
            isRunning = false
        }
    }

    func makeConfiguration() -> AppBenchRunConfiguration {
        AppBenchRunConfiguration(
            suite: selectedSuite,
            model: selectedModel,
            warmupCount: warmupCount,
            repetitions: repetitions,
            sampleLimit: samplesPerScenario,
            useAllSamples: useAllSamples,
            sessionMode: selectedSessionMode,
            reasoningLevel: selectedReasoningLevel,
            fallbackMode: selectedFallbackMode,
            connectivity: selectedConnectivity,
            randomizeOrder: randomizeOrder,
            randomSeed: randomSeed
        )
    }

    func copyMarkdown() {
        guard let result else { return }
        let markdown = AppBenchReport(result: result).markdown()

        #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(markdown, forType: .string)
        #else
            UIPasteboard.general.string = markdown
        #endif
    }

    private func applySampleDefaults(for suite: AppBenchSuite) {
        if let sampleLimit = suite.defaultSampleLimit {
            samplesPerScenario = sampleLimit
            useAllSamples = false
        } else {
            useAllSamples = true
        }
    }
}

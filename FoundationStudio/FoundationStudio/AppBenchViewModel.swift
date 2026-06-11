import AppBenchCore
import Observation
import SwiftUI

@MainActor
@Observable
final class AppBenchViewModel {
    var selectedSuite: AppBenchSuite = .quick
    var selectedModel: AppBenchModel = .onDevice
    var warmupCount = 1
    var repetitions = 3
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

        let configuration = AppBenchRunConfiguration(
            suite: selectedSuite,
            model: selectedModel,
            warmupCount: warmupCount,
            repetitions: repetitions
        )

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
}

#if os(macOS)
import Foundation
import FoundationModels
import Observation
import OSLog

@MainActor
@Observable
final class AdapterStudioViewModel {
    var prompt = ""
    var isShowingError = false

    private(set) var baseColumn = AdapterStudioColumnState()
    private(set) var adapterColumn = AdapterStudioColumnState()
    private(set) var state: AdapterStudioRunState = .idle
    private(set) var lastResult: ModelCompareResult?
    private(set) var adapterContext: AdapterContext?
    private(set) var availableAdapters: [URL] = []
    private(set) var presentedError = ""

    @ObservationIgnored private let engine: ModelCompareEngine
    @ObservationIgnored private let provider: AdapterProvider?
    @ObservationIgnored private var streamTask: Task<Void, Never>?
    @ObservationIgnored private let logger = Logger(
        subsystem: "com.rudrankriyam.foundationlab",
        category: "AdapterStudio"
    )

    init(
        engine: ModelCompareEngine? = nil,
        provider: AdapterProvider? = nil
    ) {
        self.engine = engine ?? ModelCompareEngine()

        if let provider {
            self.provider = provider
        } else {
            do {
                self.provider = try AdapterProvider()
            } catch {
                self.provider = nil
                presentedError = error.localizedDescription
                isShowingError = true
            }
        }

        refreshAvailableAdapters()
    }

    deinit {
        streamTask?.cancel()
    }

    var isRunning: Bool {
        if case .running = state {
            true
        } else {
            false
        }
    }

    var canRun: Bool {
        adapterContext != nil
            && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isRunning
    }

    var statusDescription: String {
        switch state {
        case .idle:
            if let adapterContext {
                "Ready with \(adapterContext.metadata.fileName)"
            } else {
                "Import an adapter to begin"
            }
        case .running(let prompt):
            "Comparing \"\(prompt.prefix(48))\""
        case .failed(let message):
            "Comparison failed: \(message)"
        case .completed:
            "Comparison complete"
        }
    }

    func importAdapter() {
        guard let provider else {
            present(error: "The adapter directory is unavailable.")
            return
        }

        do {
            guard let context = try provider.selectAndLoadAdapter() else { return }
            applyAdapter(context)
        } catch {
            present(error: error.localizedDescription)
        }
    }

    func loadAdapter(at url: URL) {
        guard let provider else {
            present(error: "The adapter directory is unavailable.")
            return
        }

        do {
            applyAdapter(try provider.loadExistingAdapter(at: url))
        } catch {
            present(error: error.localizedDescription)
        }
    }

    func showAdaptersDirectory() {
        provider?.revealAdaptersDirectory()
    }

    func refreshAvailableAdapters() {
        availableAdapters = provider?.availableAdapterURLs() ?? []
    }

    func clearPrompt() {
        prompt = ""
    }

    func submitCurrentPrompt() {
        submitCurrentPrompt(options: GenerationOptions())
    }

    func submitCurrentPrompt(options: GenerationOptions) {
        let trimmedPrompt = prompt.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        guard canRun else { return }

        cancel()
        baseColumn.reset()
        adapterColumn.reset()
        lastResult = nil
        state = .running(prompt: trimmedPrompt)

        let stream = engine.submit(prompt: trimmedPrompt, options: options)
        streamTask = Task { [weak self] in
            guard let self else { return }

            for await event in stream {
                guard !Task.isCancelled else { return }
                handle(event)
            }

            streamDidComplete()
        }
    }

    func cancel() {
        streamTask?.cancel()
        streamTask = nil
        engine.cancelCurrentRun()

        if isRunning {
            state = .idle
        }
    }
}

private extension AdapterStudioViewModel {
    func applyAdapter(_ context: AdapterContext) {
        cancel()
        adapterContext = context
        engine.configureAdapter(context)
        refreshAvailableAdapters()
        baseColumn.reset()
        adapterColumn.reset()
        lastResult = nil
        state = .idle
    }

    func handle(_ event: ModelCompareEvent) {
        switch event {
        case .started(let prompt):
            state = .running(prompt: prompt)
        case .availabilityIssue(let source, let availability):
            registerIssue(
                for: source,
                message: "Unavailable: \(String(describing: availability))"
            )
        case .token(let source, let text, let metrics):
            updateColumn(for: source, text: text, metrics: metrics)
        case .failed(let source, let error):
            registerIssue(for: source, message: error.message)
        case .finished(let result):
            applyCompletion(result)
        }
    }

    func updateColumn(
        for source: ModelCompareSource,
        text: String,
        metrics: ModelCompareResponseMetrics
    ) {
        switch source {
        case .base:
            baseColumn.text = text
            baseColumn.metrics = metrics
        case .adapter:
            adapterColumn.text = text
            adapterColumn.metrics = metrics
        }
    }

    func registerIssue(for source: ModelCompareSource, message: String) {
        switch source {
        case .base:
            baseColumn.errorMessage = message
        case .adapter:
            adapterColumn.errorMessage = message
        }

        logger.error(
            "\(source.displayName, privacy: .public) comparison failed: \(message, privacy: .public)"
        )
    }

    func applyCompletion(_ result: ModelCompareResult) {
        lastResult = result

        if let base = result.base {
            baseColumn.text = base.text
            baseColumn.metrics = base.metrics
        }

        if let adapter = result.adapter {
            adapterColumn.text = adapter.text
            adapterColumn.metrics = adapter.metrics
        }

        state = .completed(result)
    }

    func streamDidComplete() {
        streamTask = nil
        guard case .running = state else { return }

        let errors = [baseColumn.errorMessage, adapterColumn.errorMessage]
            .compactMap { $0 }

        if errors.isEmpty {
            state = .idle
        } else {
            state = .failed(message: errors.joined(separator: " | "))
        }
    }

    func present(error: String) {
        presentedError = error
        isShowingError = true
    }
}
#endif

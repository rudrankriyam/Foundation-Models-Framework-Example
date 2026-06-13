#if os(macOS)
import Foundation
import FoundationModels
import OSLog

@MainActor
final class ModelCompareEngine {
    private enum RunOutcome {
        case success(ModelCompareResponseSummary)
        case failure(ModelCompareError)
        case availability(SystemLanguageModel.Availability)
        case skipped
        case cancelled
    }

    private struct StreamRequest {
        let prompt: String
        let options: GenerationOptions
        let continuation: AsyncStream<ModelCompareEvent>.Continuation
    }

    private let logger = Logger(
        subsystem: "com.rudrankriyam.foundationlab",
        category: "AdapterComparison"
    )
    private let baseModel: SystemLanguageModel
    private var adapterModel: SystemLanguageModel?
    private var currentRunTask: Task<Void, Never>?
    private var activeStreamTasks: [Task<RunOutcome, Never>] = []

    init(model: SystemLanguageModel = .default) {
        baseModel = model
    }

    func cancelCurrentRun() {
        currentRunTask?.cancel()
        currentRunTask = nil
        activeStreamTasks.forEach { $0.cancel() }
        activeStreamTasks.removeAll()
    }

    func configureAdapter(_ context: AdapterContext?) {
        cancelCurrentRun()
        adapterModel = context.map { SystemLanguageModel(adapter: $0.adapter) }
    }

    func submit(
        prompt: String,
        options: GenerationOptions = GenerationOptions()
    ) -> AsyncStream<ModelCompareEvent> {
        cancelCurrentRun()

        return AsyncStream { continuation in
            continuation.yield(.started(prompt: prompt))

            let runTask = Task { [weak self] in
                guard let self else { return }
                await self.runComparison(
                    prompt: prompt,
                    options: options,
                    continuation: continuation
                )
            }
            currentRunTask = runTask

            continuation.onTermination = { @Sendable _ in
                runTask.cancel()
                Task { @MainActor [weak self] in
                    self?.currentRunTask = nil
                }
            }
        }
    }
}

private extension ModelCompareEngine {
    private func runComparison(
        prompt: String,
        options: GenerationOptions,
        continuation: AsyncStream<ModelCompareEvent>.Continuation
    ) async {
        activeStreamTasks.forEach { $0.cancel() }
        activeStreamTasks.removeAll()

        let baseTask = makeStreamTask(
            source: .base,
            model: baseModel,
            prompt: prompt,
            options: options,
            continuation: continuation
        )
        activeStreamTasks.append(baseTask)

        let adapterTask: Task<RunOutcome, Never>?
        if let adapterModel {
            let task = makeStreamTask(
                source: .adapter,
                model: adapterModel,
                prompt: prompt,
                options: options,
                continuation: continuation
            )
            activeStreamTasks.append(task)
            adapterTask = task
        } else {
            adapterTask = nil
        }

        let baseOutcome = await baseTask.value
        let adapterOutcome = await adapterTask?.value ?? .skipped
        activeStreamTasks.removeAll()

        guard !Task.isCancelled else {
            continuation.finish()
            return
        }

        let baseSummary = processOutcome(baseOutcome, for: .base, continuation: continuation)
        let adapterSummary = processOutcome(adapterOutcome, for: .adapter, continuation: continuation)

        if baseSummary != nil || adapterSummary != nil {
            continuation.yield(
                .finished(
                    ModelCompareResult(
                        prompt: prompt,
                        base: baseSummary,
                        adapter: adapterSummary
                    )
                )
            )
        }

        continuation.finish()
        currentRunTask = nil
    }

    private func makeStreamTask(
        source: ModelCompareSource,
        model: SystemLanguageModel,
        prompt: String,
        options: GenerationOptions,
        continuation: AsyncStream<ModelCompareEvent>.Continuation
    ) -> Task<RunOutcome, Never> {
        Task { [weak self] in
            guard let self else { return .cancelled }
            return await self.streamModel(
                source: source,
                model: model,
                request: StreamRequest(
                    prompt: prompt,
                    options: options,
                    continuation: continuation
                )
            )
        }
    }

    private func processOutcome(
        _ outcome: RunOutcome,
        for source: ModelCompareSource,
        continuation: AsyncStream<ModelCompareEvent>.Continuation
    ) -> ModelCompareResponseSummary? {
        switch outcome {
        case .success(let summary):
            return summary
        case .failure(let error):
            continuation.yield(.failed(source: source, error: error))
            return nil
        case .availability(let availability):
            continuation.yield(.availabilityIssue(source: source, status: availability))
            return nil
        case .skipped:
            logger.info("Skipped \(source.displayName, privacy: .public); no model was configured.")
            return nil
        case .cancelled:
            logger.debug("Cancelled \(source.displayName, privacy: .public) comparison.")
            return nil
        }
    }

    private func streamModel(
        source: ModelCompareSource,
        model: SystemLanguageModel,
        request: StreamRequest
    ) async -> RunOutcome {
        let availability = model.availability
        guard availability == .available else {
            let availabilityDescription = String(describing: availability)
            logger.error(
                "Model unavailable for \(source.displayName, privacy: .public): \(availabilityDescription, privacy: .public)"
            )
            return .availability(availability)
        }

        var metrics = ModelCompareResponseMetrics(startedAt: .now)
        let session = LanguageModelSession(model: model)

        do {
            let stream = session.streamResponse(
                to: request.prompt,
                options: request.options
            )
            var latestContent = ""

            for try await snapshot in stream {
                guard !Task.isCancelled else { return .cancelled }

                metrics.markFirstToken()
                latestContent = renderPartialText(from: snapshot)
                request.continuation.yield(
                    .token(
                        source: source,
                        text: latestContent,
                        metrics: metrics
                    )
                )
            }

            guard !Task.isCancelled else { return .cancelled }

            metrics.markCompleted()
            return .success(
                ModelCompareResponseSummary(
                    source: source,
                    text: latestContent,
                    metrics: metrics
                )
            )
        } catch {
            guard !Task.isCancelled else { return .cancelled }

            let errorDescription = error.localizedDescription
            logger.error(
                "Streaming failed for \(source.displayName, privacy: .public): \(errorDescription, privacy: .public)"
            )
            return .failure(ModelCompareError(message: errorDescription))
        }
    }

    private func renderPartialText(
        from snapshot: LanguageModelSession.ResponseStream<String>.Snapshot
    ) -> String {
        if let value = try? snapshot.rawContent.value(String.self) {
            return value
        }

        let json = snapshot.rawContent.jsonString
        if let data = json.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(String.self, from: data) {
            return decoded
        }

        return json
    }
}
#endif

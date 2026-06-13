//
//  ModelCompareEngine.swift
//  Adapter Studio
//
//  Created by Rudrank Riyam on 10/22/25.
//

import Foundation
import FoundationModels
import OSLog

/// Coordinates streaming comparisons between the base system model and a selected adapter.
///
/// The engine owns long-lived `LanguageModelSession` instances so prompts can be submitted without
/// reinitializing the Foundation Models runtime. Results are surfaced as an `AsyncStream` of events
/// containing partial tokens, availability issues, and final summaries for persistence.
@MainActor
final class ModelCompareEngine {

    /// Internal representation of a model run outcome.
    private enum RunOutcome {
        case success(ModelCompareResponseSummary)
        case failure(ModelCompareError)
        case availability(SystemLanguageModel.Availability)
        case skipped
        case cancelled
    }

    /// Request parameters for streaming a model response.
    private struct StreamRequest {
        let prompt: String
        let options: GenerationOptions
        let continuation: AsyncStream<ModelCompareEvent>.Continuation
    }

    private let logger = Logger(
        subsystem: "com.rudrankriyam.foundation-model-adapterstudio",
        category: "ModelCompareEngine"
    )
    private let baseModel: SystemLanguageModel
    private var baseSession: LanguageModelSession

    private var adapterModel: SystemLanguageModel?
    private var adapterSession: LanguageModelSession?

    private var currentRunTask: Task<Void, Never>?
    private var activeStreamTasks: [Task<RunOutcome, Never>] = []

    /// Context describing the currently configured adapter, if any.
    private(set) var adapterContext: AdapterContext?

    /// Creates an engine backed by the supplied base system model.
    ///
    /// - Parameter model: The system model to use for baseline responses. Defaults to `.default`.
    init(model: SystemLanguageModel = .default) {
        self.baseModel = model
        self.baseSession = LanguageModelSession(model: model)
    }

    /// Cancels the active comparison, if any.
    func cancelCurrentRun() {
        currentRunTask?.cancel()
        currentRunTask = nil
        activeStreamTasks.forEach { $0.cancel() }
        activeStreamTasks.removeAll()
    }

    /// Configures the engine to use the supplied adapter for subsequent comparisons.
    ///
    /// Passing `nil` clears any previously loaded adapter and terminates in-flight runs.
    func configureAdapter(_ context: AdapterContext?) {
        cancelCurrentRun()
        adapterContext = context

        guard let context else {
            adapterModel = nil
            adapterSession = nil
            return
        }

        let model = SystemLanguageModel(adapter: context.adapter)
        adapterModel = model
        adapterSession = LanguageModelSession(model: model)
    }

    /// Starts a comparison run and returns an async stream describing progress.
    ///
    /// The returned stream begins with a `.started` event, followed by zero or more `.token`
    /// updates, and terminates with `.finished` or `.failed` events before completing.
    func submit(prompt: String, options: GenerationOptions = GenerationOptions()) -> AsyncStream<ModelCompareEvent> {
        cancelCurrentRun()

        return AsyncStream { continuation in
            continuation.yield(.started(prompt: prompt))

            let runTask = Task { [weak self] in
                guard let self else { return }
                await self.runComparison(prompt: prompt, options: options, continuation: continuation)
            }

            self.currentRunTask = runTask

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
    // swiftlint:disable:next function_body_length
    private func runComparison(
        prompt: String,
        options: GenerationOptions,
        continuation: AsyncStream<ModelCompareEvent>.Continuation
    ) async {
        activeStreamTasks.forEach { $0.cancel() }
        activeStreamTasks.removeAll()

        let baseTask = Task { [weak self] () -> RunOutcome in
            guard let self else { return .cancelled }
            return await self.streamSession(
                source: .base,
                model: self.baseModel,
                session: self.baseSession,
                request: StreamRequest(
                    prompt: prompt,
                    options: options,
                    continuation: continuation
                )
            )
        }
        activeStreamTasks.append(baseTask)

        let adapterTask: Task<RunOutcome, Never>?
        if let adapterModel, let adapterSession {
            let task = Task { [weak self] () -> RunOutcome in
                guard let self else { return .cancelled }
                return await self.streamSession(
                    source: .adapter,
                    model: adapterModel,
                    session: adapterSession,
                    request: StreamRequest(
                        prompt: prompt,
                        options: options,
                        continuation: continuation
                    )
                )
            }
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
            let result = ModelCompareResult(prompt: prompt, base: baseSummary, adapter: adapterSummary)
            continuation.yield(.finished(result))
        }

        continuation.finish()
        currentRunTask = nil
    }

    /// Converts a run outcome into a response summary and emits side-effect events when needed.
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
        case .availability(let availability):
            continuation.yield(.availabilityIssue(source: source, status: availability))
        case .skipped:
            logger.info("Comparison skipped for \(source.displayName, privacy: .public) – no configured session.")
        case .cancelled:
            logger.debug("Comparison cancelled for \(source.displayName, privacy: .public).")
        }
        return nil
    }

    /// Streams a single model response and reports partial tokens back to the caller.
    private func streamSession(
        source: ModelCompareSource,
        model: SystemLanguageModel,
        session: LanguageModelSession,
        request: StreamRequest
    ) async -> RunOutcome {
        let availability = model.availability
        guard availability == .available else {
            let statusDescription = String(describing: availability)
            logger.error(
                "Model unavailable for \(source.displayName, privacy: .public): \(statusDescription, privacy: .public)"
            )
            return .availability(model.availability)
        }

        var metrics = ModelCompareResponseMetrics(startedAt: Date())

        do {
            let stream = session.streamResponse(to: request.prompt, options: request.options)
            var latestContent = ""

            for try await snapshot in stream {
                guard !Task.isCancelled else {
                    return .cancelled
                }

                metrics.markFirstToken()
                let partial = renderPartialText(from: snapshot)
                latestContent = partial
                request.continuation.yield(.token(source: source, text: partial, metrics: metrics))
            }

            guard !Task.isCancelled else {
                return .cancelled
            }

            metrics.markCompleted()

            let summary = ModelCompareResponseSummary(
                source: source,
                text: latestContent,
                metrics: metrics,
                transcript: []
            )

            return .success(summary)
        } catch {
            if Task.isCancelled {
                return .cancelled
            }

            let compareError = ModelCompareError(message: error.localizedDescription)
            let errorMessage = "Streaming failure for \(source.displayName): \(error.localizedDescription)"
            logger.error("\(errorMessage)")
            return .failure(compareError)
        }
    }

    /// Normalizes the partial snapshot into a user-friendly string.
    private func renderPartialText(from snapshot: LanguageModelSession.ResponseStream<String>.Snapshot) -> String {
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

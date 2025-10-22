//
//  CompareViewModel.swift
//  Adapter Studio
//
//  Created by Rudrank Riyam on 10/22/25.
//

import Foundation
import FoundationModels
import Observation

/// Bridges ``ModelCompareEngine`` events into observable state for SwiftUI views.
@MainActor
@Observable
final class CompareViewModel {
    
    /// High-level UI states surfaced to the view layer.
    enum State {
        case idle
        case running(prompt: String)
        case failed(message: String)
        case completed(result: ModelCompareResult)
    }
    
    /// Streaming information for a single column in the UI.
    struct ColumnState {
        var text: String = ""
        var metrics: ModelCompareResponseMetrics?
        
        mutating func reset() {
            text = ""
            metrics = nil
        }
    }
    
    /// The current prompt text bound to the UI.
    var prompt: String = ""
    
    /// Snapshot of the baseline model output.
    private(set) var baseColumn = ColumnState()
    
    /// Snapshot of the adapter model output.
    private(set) var adapterColumn = ColumnState()
    
    /// Most recent comparison state.
    private(set) var state: State = .idle
    
    /// Previously completed comparison result, if any.
    private(set) var lastResult: ModelCompareResult?
    
    /// Most recent error message, used to drive alerts or banners.
    private(set) var lastErrorMessage: String?
    
    /// Returns `true` when the engine is currently producing output.
    var isRunning: Bool {
        if case .running = state {
            return true
        }
        return false
    }
    
    @ObservationIgnored private let engine: ModelCompareEngine
    @ObservationIgnored private var streamTask: Task<Void, Never>?
    
    init(engine: ModelCompareEngine? = nil) {
        if let engine {
            self.engine = engine
        } else {
            self.engine = ModelCompareEngine()
        }
    }
    
    deinit {
        streamTask?.cancel()
    }
}

// MARK: - Adapter Configuration

extension CompareViewModel {
    
    /// Forwards adapter context updates to the compare engine.
    func configureAdapter(_ context: AdapterContext?) {
        engine.configureAdapter(context)
    }
}

// MARK: - Prompt Submission

extension CompareViewModel {
    
    /// Starts a comparison run using the current prompt value.
    func submitCurrentPrompt(options: GenerationOptions = GenerationOptions()) {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedPrompt.isEmpty == false else {
            return
        }
        
        cancel()
        prepareForRun(prompt: trimmedPrompt)
        
        let stream = engine.submit(prompt: trimmedPrompt, options: options)
        
        streamTask = Task { [weak self] in
            guard let self else { return }
            for await event in stream {
                await self.handle(event)
            }
            
            self.streamDidComplete()
        }
    }
    
    /// Cancels the active comparison task, if any.
    func cancel() {
        streamTask?.cancel()
        streamTask = nil
        engine.cancelCurrentRun()
    }
}

// MARK: - Private Helpers

private extension CompareViewModel {
    
    func prepareForRun(prompt: String) {
        baseColumn.reset()
        adapterColumn.reset()
        lastResult = nil
        lastErrorMessage = nil
        state = .running(prompt: prompt)
    }
    
    func streamDidComplete() {
        streamTask = nil
        if case .running = state {
            state = .idle
        }
    }
    
    func handle(_ event: ModelCompareEvent) async {
        switch event {
        case .started(let prompt):
            state = .running(prompt: prompt)
            
        case .availabilityIssue(let source, let status):
            let message = "Model unavailable (\(source.displayName)): \(String(describing: status))"
            registerFailure(message: message)
            
        case .token(let source, let text, let metrics):
            updateColumn(for: source, text: text, metrics: metrics)
            
        case .failed(_, let error):
            registerFailure(message: error.message)
            
        case .finished(let result):
            applyCompletion(result)
        }
    }
    
    func updateColumn(for source: ModelCompareSource, text: String, metrics: ModelCompareResponseMetrics) {
        switch source {
        case .base:
            baseColumn.text = text
            baseColumn.metrics = metrics
        case .adapter:
            adapterColumn.text = text
            adapterColumn.metrics = metrics
        }
    }
    
    func registerFailure(message: String) {
        lastErrorMessage = message
        state = .failed(message: message)
        cancel()
    }
    
    func applyCompletion(_ result: ModelCompareResult) {
        lastResult = result
        
        if let baseSummary = result.base {
            baseColumn.text = baseSummary.text
            baseColumn.metrics = baseSummary.metrics
        }
        
        if let adapterSummary = result.adapter {
            adapterColumn.text = adapterSummary.text
            adapterColumn.metrics = adapterSummary.metrics
        }
        
        state = .completed(result: result)
    }
}

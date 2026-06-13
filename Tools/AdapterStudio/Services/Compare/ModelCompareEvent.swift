//
//  ModelCompareEvent.swift
//  Adapter Studio
//
//  Created by Rudrank Riyam on 10/22/25.
//

import Foundation
import FoundationModels

/// Events surfaced during a comparison run.
enum ModelCompareEvent: Sendable {

    /// Indicates the run started and includes the prompt text.
    case started(prompt: String)

    /// Emitted when a model is unavailable for the current device state.
    case availabilityIssue(source: ModelCompareSource, status: SystemLanguageModel.Availability)

    /// Partial token update with the current aggregated content and metrics.
    case token(source: ModelCompareSource, text: String, metrics: ModelCompareResponseMetrics)

    /// Terminal error for a specific model.
    case failed(source: ModelCompareSource, error: ModelCompareError)

    /// Final combined summary after both models finish or fail.
    case finished(ModelCompareResult)
}

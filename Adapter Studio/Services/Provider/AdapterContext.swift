//
//  AdapterContext.swift
//  Adapter Studio
//
//  Created by Rudrank Riyam on 10/22/25.
//

import Foundation
import FoundationModels

/// A loaded adapter instance paired with descriptive metadata.
struct AdapterContext {

    /// The instantiated adapter ready to be supplied to `SystemLanguageModel(adapter:guardrails:)` so Adapter Studio
    /// can reuse the same instance across prompts without reloading from disk.
    let adapter: SystemLanguageModel.Adapter

    /// File-system metadata for the adapter package, enabling the UI to surface size, timestamps, and creator-defined
    /// fields alongside the preview.
    let metadata: AdapterMetadata
}

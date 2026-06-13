import Foundation
import FoundationModels

enum AppBenchPartialResponsePolicy {
    static func shouldPreserve(
        _ response: String,
        after error: LanguageModelSession.GenerationError
    ) -> Bool {
        !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && AppBenchSafetyClassifier.outcome(for: error) == nil
    }
}

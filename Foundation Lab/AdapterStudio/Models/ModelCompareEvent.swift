#if os(macOS)
import FoundationModels

enum ModelCompareEvent: Sendable {
    case started(prompt: String)
    case availabilityIssue(source: ModelCompareSource, status: SystemLanguageModel.Availability)
    case token(source: ModelCompareSource, text: String, metrics: ModelCompareResponseMetrics)
    case failed(source: ModelCompareSource, error: ModelCompareError)
    case finished(ModelCompareResult)
}
#endif

#if os(macOS)
struct ModelCompareResponseSummary: Sendable {
    let source: ModelCompareSource
    let text: String
    let metrics: ModelCompareResponseMetrics
}
#endif

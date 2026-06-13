#if os(macOS)
struct ModelCompareResult: Sendable {
    let prompt: String
    let base: ModelCompareResponseSummary?
    let adapter: ModelCompareResponseSummary?
}
#endif

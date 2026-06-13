#if os(macOS)
struct AdapterStudioColumnState {
    var text = ""
    var metrics: ModelCompareResponseMetrics?
    var errorMessage: String?

    mutating func reset() {
        text = ""
        metrics = nil
        errorMessage = nil
    }
}
#endif

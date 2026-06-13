#if os(macOS)
enum AdapterStudioRunState {
    case idle
    case running(prompt: String)
    case failed(message: String)
    case completed(ModelCompareResult)
}
#endif

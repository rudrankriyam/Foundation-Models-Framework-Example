#if os(macOS)
enum ModelCompareSource: String, Sendable {
    case base
    case adapter

    var displayName: String {
        switch self {
        case .base:
            "Base"
        case .adapter:
            "Adapter"
        }
    }
}
#endif

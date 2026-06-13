#if os(macOS)
import FoundationModels

struct AdapterContext {
    let adapter: SystemLanguageModel.Adapter
    let metadata: AdapterMetadata
}
#endif

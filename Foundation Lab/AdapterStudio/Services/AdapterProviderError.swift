#if os(macOS)
import Foundation

enum AdapterProviderError: LocalizedError {
    case directoryCreationFailed(String)
    case directoryNotWritable(String)
    case invalidFileExtension(URL)
    case copyFailed(String)
    case loadFailed(String)
    case fileTooLarge(UInt64)
    case sizeCalculationFailed(URL, String)

    var errorDescription: String? {
        switch self {
        case .directoryCreationFailed(let message):
            "Failed to prepare the adapter directory: \(message)"
        case .directoryNotWritable(let path):
            "The adapter directory is not writable: \(path)"
        case .invalidFileExtension(let url):
            "\"\(url.lastPathComponent)\" is not an .fmadapter package."
        case .copyFailed(let message):
            "Could not import the adapter: \(message)"
        case .loadFailed(let message):
            "Could not load the adapter: \(message)"
        case .fileTooLarge(let size):
            "The adapter is too large "
                + "(\(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)))."
        case .sizeCalculationFailed(let url, let message):
            "Could not measure \"\(url.lastPathComponent)\": \(message)"
        }
    }
}
#endif

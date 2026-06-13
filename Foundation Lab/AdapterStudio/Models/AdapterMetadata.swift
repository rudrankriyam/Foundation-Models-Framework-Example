#if os(macOS)
import Foundation

struct AdapterMetadata: Sendable {
    let location: URL
    let fileName: String
    let fileSize: UInt64
    let createdAt: Date?
    let modifiedAt: Date?
    let creatorDefinedMetadata: [String: String]
}
#endif

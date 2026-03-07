import Foundation

public enum InvocationSource: String, Sendable, Hashable, Codable {
    case app
    case appIntent
    case cli
    case automation
    case unknown
}

public struct CapabilityInvocationContext: Sendable, Hashable, Codable {
    public let source: InvocationSource
    public let localeIdentifier: String?
    public let correlationID: UUID

    public init(
        source: InvocationSource,
        localeIdentifier: String? = nil,
        correlationID: UUID = UUID()
    ) {
        self.source = source
        self.localeIdentifier = localeIdentifier
        self.correlationID = correlationID
    }
}

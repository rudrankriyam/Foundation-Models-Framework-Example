import Foundation

public enum FoundationLabCoreError: LocalizedError, Sendable, Equatable {
    case invalidRequest(String)
    case unavailableCapability(String)
    case providerFailure(String)
    case unsupportedEnvironment(String)

    public var errorDescription: String? {
        switch self {
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .unavailableCapability(let message):
            return "Unavailable capability: \(message)"
        case .providerFailure(let message):
            return "Provider failure: \(message)"
        case .unsupportedEnvironment(let message):
            return "Unsupported environment: \(message)"
        }
    }
}

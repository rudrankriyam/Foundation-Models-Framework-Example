import Foundation

public protocol CapabilityRequest: Sendable {}

public protocol CapabilityResult: Sendable {}

public struct CapabilityDescriptor: Sendable, Hashable {
    public let id: String
    public let displayName: String
    public let summary: String

    public init(id: String, displayName: String, summary: String) {
        self.id = id
        self.displayName = displayName
        self.summary = summary
    }
}

/// A task-oriented use case that can be shared by the app, App Intents, and CLI adapters.
public protocol CapabilityUseCase: Sendable {
    associatedtype Request: CapabilityRequest
    associatedtype Output: CapabilityResult

    static var descriptor: CapabilityDescriptor { get }

    func execute(_ request: Request) async throws -> Output
}

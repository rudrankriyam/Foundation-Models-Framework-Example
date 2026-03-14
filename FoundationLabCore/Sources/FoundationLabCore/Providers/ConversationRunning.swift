import Foundation

public protocol ConversationRunning: Sendable {
    func runConversation(for request: RunConversationRequest) async throws -> RunConversationResult
}

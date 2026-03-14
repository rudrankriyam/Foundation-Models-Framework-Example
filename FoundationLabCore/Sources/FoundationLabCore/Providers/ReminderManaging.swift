import Foundation

public protocol ReminderManaging: Sendable {
    func manageReminders(for request: ManageRemindersRequest) async throws -> TextGenerationResult
}

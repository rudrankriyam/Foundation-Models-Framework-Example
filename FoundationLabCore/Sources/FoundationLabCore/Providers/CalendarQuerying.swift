import Foundation

public protocol CalendarQuerying: Sendable {
    func queryCalendar(for request: QueryCalendarRequest) async throws -> TextGenerationResult
}

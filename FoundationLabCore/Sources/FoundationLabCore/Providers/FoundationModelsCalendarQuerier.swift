import Foundation
import FoundationModelsTools

public struct FoundationModelsCalendarQuerier: CalendarQuerying {
    private let toolInvoker: FoundationModelsToolInvoker

    public init(toolInvoker: FoundationModelsToolInvoker = FoundationModelsToolInvoker()) {
        self.toolInvoker = toolInvoker
    }

    public func queryCalendar(for request: QueryCalendarRequest) async throws -> TextGenerationResult {
        let query = request.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing query")
        }

        let localeIdentifier = request.context.localeIdentifier ?? Locale.current.identifier
        let timeZone = FoundationModelsPromptSupport.resolvedTimeZone(identifier: request.timeZoneIdentifier)
        let contextualInstructions = """
        The user's current time zone is \(timeZone.identifier).
        The user's current locale identifier is \(localeIdentifier).
        The current local date and time is \(FoundationModelsPromptSupport.isoTimestamp(request.referenceDate, timeZoneIdentifier: request.timeZoneIdentifier)).
        Use this information when interpreting relative dates like "today" or "tomorrow".
        """

        return try await toolInvoker.respond(
            to: query,
            using: CalendarTool(),
            systemPrompt: FoundationModelsPromptSupport.combinedSystemPrompt([
                request.systemPrompt,
                contextualInstructions
            ]),
            modelUseCase: request.modelUseCase,
            guardrails: request.guardrails
        )
    }
}

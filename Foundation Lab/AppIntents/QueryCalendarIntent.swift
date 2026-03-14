import AppIntents
import Foundation
import FoundationLabCore

struct QueryCalendarIntent: AppIntent {
    static let title: LocalizedStringResource = "Query Calendar"
    static let description = IntentDescription(
        "Queries your calendar using Foundation Lab's shared calendar capability."
    )
    static let openAppWhenRun = true

    @Parameter(
        title: "Request",
        requestValueDialog: IntentDialog("What do you want to do with your calendar?")
    )
    var query: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let response = try await QueryCalendarUseCase().execute(
            QueryCalendarRequest(
                query: query,
                referenceDate: .now,
                timeZoneIdentifier: TimeZone.current.identifier,
                context: CapabilityInvocationContext(
                    source: .appIntent,
                    localeIdentifier: Locale.current.identifier
                )
            )
        )

        return .result(value: response.content)
    }
}

import AppIntents
import Foundation
import FoundationLabCore

struct QueryHealthDataIntent: AppIntent {
    static let title: LocalizedStringResource = "Query Health Data"
    static let description = IntentDescription(
        "Queries your health data using Foundation Lab's shared health capability."
    )
    static let openAppWhenRun = true

    @Parameter(
        title: "Request",
        requestValueDialog: IntentDialog("What health question do you want to ask?")
    )
    var query: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let response = try await QueryHealthDataUseCase().execute(
            QueryHealthDataRequest(
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

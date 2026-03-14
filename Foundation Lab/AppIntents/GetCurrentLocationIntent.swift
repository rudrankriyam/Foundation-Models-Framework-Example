import AppIntents
import Foundation
import FoundationLabCore

struct GetCurrentLocationIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Current Location"
    static let description = IntentDescription(
        "Gets your current location using Foundation Lab's shared location capability."
    )
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let response = try await GetCurrentLocationUseCase().execute(
            GetCurrentLocationRequest(
                context: CapabilityInvocationContext(
                    source: .appIntent,
                    localeIdentifier: Locale.current.identifier
                )
            )
        )

        return .result(value: response.content)
    }
}

import AppIntents
import Foundation
import FoundationLabCore

struct AnalyzeNutritionIntent: AppIntent {
    static let title: LocalizedStringResource = "Analyze Nutrition"
    static let description = IntentDescription(
        "Analyzes meal nutrition using Foundation Lab's shared nutrition capability."
    )
    static let openAppWhenRun = false

    @Parameter(
        title: "Meal Description",
        requestValueDialog: IntentDialog("What meal should I analyze?")
    )
    var mealDescription: String

    @Parameter(title: "Response Language")
    var responseLanguage: String?

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let response = try await AnalyzeNutritionUseCase().execute(
            AnalyzeNutritionRequest(
                foodDescription: mealDescription,
                responseLanguage: responseLanguage?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                    ? responseLanguage!
                    : "English",
                context: CapabilityInvocationContext(
                    source: .appIntent,
                    localeIdentifier: Locale.current.identifier
                )
            )
        )

        return .result(value: response.analysis.insights)
    }
}

import Foundation

public struct CheckModelAvailabilityUseCase: Sendable {
    public static let descriptor = CapabilityDescriptor(
        id: "foundation-models.check-availability",
        displayName: "Check Model Availability",
        summary: "Checks whether Apple Intelligence is currently available."
    )

    private let checker: any ModelAvailabilityChecking

    public init(checker: any ModelAvailabilityChecking = FoundationModelsModelAvailabilityChecker()) {
        self.checker = checker
    }

    public func execute(
        useCase: FoundationLabModelUseCase = .general
    ) -> ModelAvailabilityResult {
        checker.currentAvailability(useCase: useCase)
    }
}

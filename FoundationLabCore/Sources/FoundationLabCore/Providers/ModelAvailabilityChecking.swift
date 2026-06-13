import Foundation

public protocol ModelAvailabilityChecking: Sendable {
    func currentAvailability() -> ModelAvailabilityResult
    func currentAvailability(useCase: FoundationLabModelUseCase) -> ModelAvailabilityResult
}

public extension ModelAvailabilityChecking {
    func currentAvailability(useCase _: FoundationLabModelUseCase) -> ModelAvailabilityResult {
        currentAvailability()
    }
}

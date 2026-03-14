import Foundation

public protocol ModelAvailabilityChecking: Sendable {
    func currentAvailability() -> ModelAvailabilityResult
}

import Foundation

public struct GenerateHealthEncouragementRequest: CapabilityRequest, Sendable, Hashable, Codable {
    public let healthScore: Int
    public let stepsProgressPercentage: Int
    public let sleepHours: Double
    public let activeEnergy: Int
    public let timeOfDay: String
    public let context: CapabilityInvocationContext

    public init(
        healthScore: Int,
        stepsProgressPercentage: Int,
        sleepHours: Double,
        activeEnergy: Int,
        timeOfDay: String,
        context: CapabilityInvocationContext
    ) {
        self.healthScore = healthScore
        self.stepsProgressPercentage = stepsProgressPercentage
        self.sleepHours = sleepHours
        self.activeEnergy = activeEnergy
        self.timeOfDay = timeOfDay
        self.context = context
    }
}

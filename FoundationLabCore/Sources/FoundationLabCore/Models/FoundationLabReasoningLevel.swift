import Foundation

public enum FoundationLabReasoningLevel: String, CaseIterable, Sendable, Hashable, Codable {
    case none
    case light
    case moderate
    case deep

    public var displayName: String {
        switch self {
        case .none:
            return "None"
        case .light:
            return "Light"
        case .moderate:
            return "Moderate"
        case .deep:
            return "Deep"
        }
    }

    public var systemImage: String {
        switch self {
        case .none:
            return "brain"
        case .light:
            return "bolt"
        case .moderate:
            return "brain"
        case .deep:
            return "brain.head.profile"
        }
    }
}

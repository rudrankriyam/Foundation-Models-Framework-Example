import Foundation

public enum AppBenchModel: String, CaseIterable, Codable, Identifiable, Sendable {
    case onDevice
    case privateCloudCompute

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .onDevice:
            "On-device"
        case .privateCloudCompute:
            "Private Cloud Compute"
        }
    }
}

public enum AppBenchSuite: String, CaseIterable, Codable, Identifiable, Sendable {
    case quick
    case full
    case performance

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .quick:
            "Practical Quick"
        case .full:
            "Practical Full"
        case .performance:
            "Synthetic Performance"
        }
    }
}

public enum AppBenchScenarioCategory: String, Codable, CaseIterable, Sendable {
    case taskParsing
    case summarization
    case classification
    case structuredRecommendation
    case groundedQuestionAnswering
    case syntheticThroughput

    public var displayName: String {
        switch self {
        case .taskParsing:
            "Task parsing"
        case .summarization:
            "Summarization"
        case .classification:
            "Classification"
        case .structuredRecommendation:
            "Structured recommendation"
        case .groundedQuestionAnswering:
            "Grounded question answering"
        case .syntheticThroughput:
            "Synthetic throughput"
        }
    }
}

public enum AppBenchOutputMode: Codable, Sendable {
    case text
    case guided(AppBenchSchema)
}

public enum AppBenchSchema: String, Codable, Sendable {
    case task
    case classification
    case workout
    case groundedAnswer
}

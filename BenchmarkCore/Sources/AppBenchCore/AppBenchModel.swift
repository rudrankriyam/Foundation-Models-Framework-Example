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
    case context

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .quick:
            "Practical Quick"
        case .full:
            "Practical Full"
        case .performance:
            "Synthetic Performance"
        case .context:
            "Context Limits"
        }
    }
}

public enum AppBenchScenarioCategory: String, Codable, CaseIterable, Sendable {
    case taskParsing
    case summarization
    case classification
    case workoutGeneration
    case groundedExplanation
    case exerciseSubstitution
    case documentQuestionAnswering
    case citationExtraction
    case creativeWriting
    case visualRecommendation
    case syntheticThroughput
    case contextLimits

    public var displayName: String {
        switch self {
        case .taskParsing:
            "Task parsing"
        case .summarization:
            "Summarization"
        case .classification:
            "Classification"
        case .workoutGeneration:
            "Workout generation"
        case .groundedExplanation:
            "Grounded explanation"
        case .exerciseSubstitution:
            "Exercise substitution"
        case .documentQuestionAnswering:
            "Document question answering"
        case .citationExtraction:
            "Citation extraction"
        case .creativeWriting:
            "Creative writing"
        case .visualRecommendation:
            "Visual recommendation"
        case .syntheticThroughput:
            "Synthetic throughput"
        case .contextLimits:
            "Context limits"
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
    case citation
}

public enum AppBenchSessionMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case cold
    case warm

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cold:
            "Cold session"
        case .warm:
            "Warm reused session"
        }
    }
}

public enum AppBenchReasoningLevel: String, CaseIterable, Codable, Identifiable, Sendable {
    case none
    case light
    case moderate
    case deep

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .none:
            "Default"
        case .light:
            "Light"
        case .moderate:
            "Moderate"
        case .deep:
            "Deep"
        }
    }
}

public enum AppBenchFallbackMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case disabled
    case onDevice

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .disabled:
            "Disabled"
        case .onDevice:
            "Fall back on-device"
        }
    }
}

public enum AppBenchConnectivity: String, CaseIterable, Codable, Identifiable, Sendable {
    case normal
    case offline

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .normal:
            "Normal"
        case .offline:
            "Offline experiment"
        }
    }
}

public enum AppBenchToolSet: String, Codable, Sendable {
    case none
    case knowledge
    case exerciseCatalog
}

public enum AppBenchVisualFixture: String, Codable, Sendable {
    case sunsetRun
}

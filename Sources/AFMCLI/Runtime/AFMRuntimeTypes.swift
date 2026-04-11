import Foundation
import ArgumentParser
import FoundationModels

protocol AFMCapabilityRequest: Sendable {}
protocol AFMCapabilityResult: Sendable {}

struct AFMCapabilityDescriptor: Sendable, Hashable {
    let id: String
    let displayName: String
    let summary: String
}

protocol AFMCapabilityUseCase: Sendable {
    associatedtype Request: AFMCapabilityRequest
    associatedtype Result: AFMCapabilityResult

    static var descriptor: AFMCapabilityDescriptor { get }

    func execute(_ request: Request) async throws -> Result
}

enum AFMRuntimeError: LocalizedError, Sendable, Equatable {
    case invalidRequest(String)
    case unavailableCapability(String)
    case providerFailure(String)
    case unsupportedEnvironment(String)
    case fileWriteFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .unavailableCapability(let message):
            return "Unavailable capability: \(message)"
        case .providerFailure(let message):
            return "Provider failure: \(message)"
        case .unsupportedEnvironment(let message):
            return "Unsupported environment: \(message)"
        case .fileWriteFailed(let message):
            return "File write failed: \(message)"
        }
    }
}

enum AFMInvocationSource: String, Sendable, Hashable, Codable {
    case cli
    case automation
    case test
    case unknown
}

struct AFMInvocationContext: Sendable, Hashable, Codable {
    let source: AFMInvocationSource
    let localeIdentifier: String?
    let correlationID: UUID

    init(
        source: AFMInvocationSource,
        localeIdentifier: String? = nil,
        correlationID: UUID = UUID()
    ) {
        self.source = source
        self.localeIdentifier = localeIdentifier
        self.correlationID = correlationID
    }
}

enum AFMModelUseCase: String, Sendable, Hashable, Codable {
    case general
}

enum AFMGuardrails: String, Sendable, Hashable, Codable, CaseIterable {
    case `default` = "default"
    case permissiveContentTransformations = "permissive-content-transformations"
}

extension AFMGuardrails: ExpressibleByArgument {
    init?(argument: String) {
        let normalized = argument.trimmingCharacters(in: .whitespacesAndNewlines)
        switch normalized {
        case "default", "DEFAULT":
            self = .default
        case "permissive-content-transformations", "permissiveContentTransformations":
            self = .permissiveContentTransformations
        default:
            switch normalized.lowercased() {
            case "default":
                self = .default
            case "permissive-content-transformations", "permissivecontenttransformations":
                self = .permissiveContentTransformations
            default:
                return nil
            }
        }
    }
}

struct AFMGenerationOptions: Sendable, Hashable, Codable {
    enum SamplingMode: Sendable, Hashable, Codable {
        case greedy
        case randomTop(Int, seed: UInt64? = nil)
        case randomProbabilityThreshold(Double, seed: UInt64? = nil)
    }

    let sampling: SamplingMode?
    let temperature: Double?
    let maximumResponseTokens: Int?

    init(
        sampling: SamplingMode? = nil,
        temperature: Double? = nil,
        maximumResponseTokens: Int? = nil
    ) {
        self.sampling = sampling
        self.temperature = temperature
        self.maximumResponseTokens = maximumResponseTokens
    }
}

struct AFMExecutionMetadata: AFMCapabilityResult, Sendable, Hashable, Codable {
    let provider: String?
    let modelIdentifier: String?
    let tokenCount: Int?

    init(
        provider: String? = nil,
        modelIdentifier: String? = nil,
        tokenCount: Int? = nil
    ) {
        self.provider = provider
        self.modelIdentifier = modelIdentifier
        self.tokenCount = tokenCount
    }
}

enum AFMAvailabilityUnavailableReason: String, Sendable, Hashable, Codable {
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    case modelNotReady
    case unknown
}

struct AFMAvailabilityResult: AFMCapabilityResult, Sendable, Hashable, Codable {
    let isAvailable: Bool
    let reason: AFMAvailabilityUnavailableReason?
    let metadata: AFMExecutionMetadata

    init(
        isAvailable: Bool,
        reason: AFMAvailabilityUnavailableReason? = nil,
        metadata: AFMExecutionMetadata = AFMExecutionMetadata()
    ) {
        self.isAvailable = isAvailable
        self.reason = reason
        self.metadata = metadata
    }
}

struct AFMSupportedLanguageDescriptor: Sendable, Hashable, Codable, Identifiable {
    let identifier: String
    let languageCode: String
    let regionCode: String?

    var id: String { identifier }

    func displayName(in locale: Locale = .current) -> String {
        let languageName = locale.localizedString(forLanguageCode: languageCode) ?? languageCode
        if let regionCode, !regionCode.isEmpty {
            return "\(languageName) (\(languageCode)-\(regionCode))"
        }
        return languageName
    }
}

struct AFMSupportedLanguagesResult: AFMCapabilityResult, Sendable, Hashable, Codable {
    let languages: [AFMSupportedLanguageDescriptor]
    let metadata: AFMExecutionMetadata
}

struct AFMTextGenerationResult: AFMCapabilityResult, Sendable, Hashable, Codable {
    let content: String
    let metadata: AFMExecutionMetadata
}

struct AFMStructuredGenerationResult<Output: Sendable>: AFMCapabilityResult, Sendable {
    let output: Output
    let metadata: AFMExecutionMetadata
}

struct AFMDynamicSchemaGenerationResult: AFMCapabilityResult, Sendable {
    let output: GeneratedContent
    let metadata: AFMExecutionMetadata
}

struct AFMConversationExchange: AFMCapabilityResult, Sendable, Hashable, Codable, Identifiable {
    let id: UUID
    let prompt: String
    let response: String
    let isError: Bool

    init(id: UUID = UUID(), prompt: String, response: String, isError: Bool) {
        self.id = id
        self.prompt = prompt
        self.response = response
        self.isError = isError
    }
}

struct AFMRunConversationResult: AFMCapabilityResult, Sendable, Hashable, Codable {
    let exchanges: [AFMConversationExchange]
    let metadata: AFMExecutionMetadata
}

struct AFMConversationConfiguration {
    var baseInstructions: String
    var summaryInstructions: String
    var summaryPromptPreamble: String
    var conversationUserLabel: String
    var conversationAssistantLabel: String
    var continuationNote: String
    var overflowResetMessage: String?
    var modelUseCase: AFMModelUseCase
    var guardrails: AFMGuardrails
    var tools: [any Tool]
    var enableSlidingWindow: Bool
    var windowThreshold: Double
    var targetWindowSize: Int
    var defaultMaxContextSize: Int

    init(
        baseInstructions: String,
        summaryInstructions: String,
        summaryPromptPreamble: String,
        conversationUserLabel: String,
        conversationAssistantLabel: String,
        continuationNote: String,
        overflowResetMessage: String? = nil,
        modelUseCase: AFMModelUseCase = .general,
        guardrails: AFMGuardrails = .default,
        tools: [any Tool] = [],
        enableSlidingWindow: Bool = false,
        windowThreshold: Double = 0.70,
        targetWindowSize: Int = 6_000,
        defaultMaxContextSize: Int = 4_096
    ) {
        self.baseInstructions = baseInstructions
        self.summaryInstructions = summaryInstructions
        self.summaryPromptPreamble = summaryPromptPreamble
        self.conversationUserLabel = conversationUserLabel
        self.conversationAssistantLabel = conversationAssistantLabel
        self.continuationNote = continuationNote
        self.overflowResetMessage = overflowResetMessage
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.tools = tools
        self.enableSlidingWindow = enableSlidingWindow
        self.windowThreshold = windowThreshold
        self.targetWindowSize = targetWindowSize
        self.defaultMaxContextSize = defaultMaxContextSize
    }
}

@Generable
struct AFMConversationSummary: Sendable {
    @Guide(description: "A concise but complete summary of the conversation so far.")
    let summary: String

    @Guide(description: "The main topics, tasks, or themes discussed.")
    let keyTopics: [String]

    @Guide(description: "User preferences or instructions that should carry forward.")
    let userPreferences: [String]
}

struct AFMTextGenerationRequest: AFMCapabilityRequest, Sendable {
    let prompt: String
    let systemPrompt: String?
    let modelUseCase: AFMModelUseCase
    let guardrails: AFMGuardrails?
    let generationOptions: AFMGenerationOptions?
    let context: AFMInvocationContext
}

struct AFMStreamingTextGenerationRequest: AFMCapabilityRequest, Sendable {
    let prompt: String
    let systemPrompt: String?
    let modelUseCase: AFMModelUseCase
    let guardrails: AFMGuardrails?
    let generationOptions: AFMGenerationOptions?
    let context: AFMInvocationContext
}

struct AFMStructuredGenerationRequest<Output: Generable & Sendable>: AFMCapabilityRequest, Sendable {
    let prompt: String
    let systemPrompt: String?
    let modelUseCase: AFMModelUseCase
    let guardrails: AFMGuardrails?
    let generationOptions: AFMGenerationOptions?
    let context: AFMInvocationContext
}

struct AFMDynamicSchemaGenerationRequest: AFMCapabilityRequest, Sendable {
    let prompt: String
    let schema: GenerationSchema
    let systemPrompt: String?
    let modelUseCase: AFMModelUseCase
    let guardrails: AFMGuardrails?
    let generationOptions: AFMGenerationOptions?
    let context: AFMInvocationContext
}

struct AFMRunConversationRequest: AFMCapabilityRequest, Sendable {
    let prompts: [String]
    let systemPrompt: String?
    let modelUseCase: AFMModelUseCase
    let guardrails: AFMGuardrails?
    let generationOptions: AFMGenerationOptions?
    let context: AFMInvocationContext
}

protocol AFMModelAvailabilityChecking: Sendable {
    func currentAvailability() -> AFMAvailabilityResult
}

protocol AFMSupportedLanguageListing: Sendable {
    func supportedLanguages(locale: Locale) -> AFMSupportedLanguagesResult
}

protocol AFMTextGenerationProviding: Sendable {
    func generateText(for request: AFMTextGenerationRequest) async throws -> AFMTextGenerationResult
}

protocol AFMStreamingTextGenerationProviding: Sendable {
    func streamText(
        for request: AFMStreamingTextGenerationRequest,
        onPartialResponse: @escaping @Sendable (String) async -> Void
    ) async throws -> AFMTextGenerationResult
}

protocol AFMStructuredGenerationProviding: Sendable {
    func generate<Output: Generable & Sendable>(
        _ type: Output.Type,
        for request: AFMStructuredGenerationRequest<Output>
    ) async throws -> AFMStructuredGenerationResult<Output>
}

protocol AFMDynamicSchemaGenerationProviding: Sendable {
    func generate(for request: AFMDynamicSchemaGenerationRequest) async throws -> AFMDynamicSchemaGenerationResult
}

protocol AFMConversationRunning: Sendable {
    func runConversation(for request: AFMRunConversationRequest) async throws -> AFMRunConversationResult
}

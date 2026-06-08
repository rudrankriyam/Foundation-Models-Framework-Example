//
//  ExampleType.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/15/25.
//

import Foundation
import FoundationModels

enum ExampleType: String, CaseIterable, Identifiable {
    case basicChat = "basic_chat"
    case journaling = "journaling"
    case creativeWriting = "creative_writing"
    case structuredData = "structured_data"
    case streamingResponse = "streaming_response"
    case modelAvailability = "model_availability"
    case generationGuides = "generation_guides"
    case generationOptions = "generation_options"
    case modelRuntime = "model_runtime"
    case contextWindowInspector = "context_window_inspector"
    case privateCloudCompute = "private_cloud_compute"
    case imageInputPlayground = "image_input_playground"
    case toolCallingModeLab = "tool_calling_mode_lab"
    case dynamicProfileBuilder = "dynamic_profile_builder"
    case reasoningLevelComparison = "reasoning_level_comparison"
    case transcriptExplorer = "transcript_explorer"
    case health = "health"
    case rag = "rag"
    case chat = "chat"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .basicChat:
            return "One-shot"
        case .journaling:
            return "Journaling"
        case .creativeWriting:
            return "Creative Writing"
        case .structuredData:
            return "Structured Data"
        case .streamingResponse:
            return "Streaming Response"
        case .modelAvailability:
            return "Model Availability"
        case .generationGuides:
            return "Generation Guides"
        case .generationOptions:
            return "Generation Options"
        case .modelRuntime:
            return "Model Runtime"
        case .contextWindowInspector:
            return "Context Window"
        case .privateCloudCompute:
            return "Private Cloud"
        case .imageInputPlayground:
            return "Image Input"
        case .toolCallingModeLab:
            return "Tool Modes"
        case .dynamicProfileBuilder:
            return "Dynamic Profile"
        case .reasoningLevelComparison:
            return "Reasoning Levels"
        case .transcriptExplorer:
            return "Transcript Explorer"
        case .health:
            return "Health Dashboard"
        case .rag:
            return "Doc Q&A"
        case .chat:
            return "Chat"
        }
    }

    var subtitle: String {
        switch self {
        case .basicChat:
            return "Single prompt-response interaction"
        case .journaling:
            return "Prompts, starters, and reflective summaries"
        case .creativeWriting:
            return "Stories, poems, and creative content"
        case .structuredData:
            return "Parse and generate structured information"
        case .streamingResponse:
            return "Real-time response streaming"
        case .modelAvailability:
            return "Check Apple Intelligence status"
        case .generationGuides:
            return "Guided generation with constraints"
        case .generationOptions:
            return "Experiment with model parameters"
        case .modelRuntime:
            return "Compare system and cloud model surfaces"
        case .contextWindowInspector:
            return "Inspect context size and token budget"
        case .privateCloudCompute:
            return "Probe PCC availability, quota, and context size"
        case .imageInputPlayground:
            return "Explore image attachments and references"
        case .toolCallingModeLab:
            return "Compare allowed, required, and disallowed tools"
        case .dynamicProfileBuilder:
            return "Compose Xcode 27 session profiles"
        case .reasoningLevelComparison:
            return "Compare light, moderate, and deep reasoning"
        case .transcriptExplorer:
            return "Browse reasoning, attachments, and custom segments"
        case .health:
            return "AI-powered health insights and tracking"
        case .rag:
            return "Ask questions with source citations"
        case .chat:
            return "Multi-turn conversation with AI assistant"
        }
    }

    var icon: String {
        switch self {
        case .basicChat:
            return "ellipsis.message"
        case .journaling:
            return "square.and.pencil"
        case .creativeWriting:
            return "pencil.and.outline"
        case .structuredData:
            return "list.bullet.rectangle"
        case .streamingResponse:
            return "wave.3.right"
        case .modelAvailability:
            return "checkmark.shield"
        case .generationGuides:
            return "slider.horizontal.3"
        case .generationOptions:
            return "tuningfork"
        case .modelRuntime:
            return "cpu"
        case .contextWindowInspector:
            return "text.page.badge.magnifyingglass"
        case .privateCloudCompute:
            return "icloud.and.arrow.up"
        case .imageInputPlayground:
            return "photo.on.rectangle.angled"
        case .toolCallingModeLab:
            return "hammer"
        case .dynamicProfileBuilder:
            return "slider.horizontal.below.rectangle"
        case .reasoningLevelComparison:
            return "brain.head.profile"
        case .transcriptExplorer:
            return "list.bullet.rectangle.portrait"
        case .health:
            return "heart.fill"
        case .rag:
            return "doc.text.magnifyingglass"
        case .chat:
            return "bubble.left.and.bubble.right.fill"
        }
    }

    /// Static property for examples displayed in the grid (excludes chat)
    static var gridExamples: [ExampleType] {
        allCases.filter { $0 != .chat }
    }

}

// MARK: - Tool Example Enum

enum ToolExample: String, CaseIterable, Hashable {
    case weather
    case web
    case contacts
    case calendar
    case reminders
    case location
    case health
    case music
    case webMetadata

    var displayName: String {
        switch self {
        case .weather: return "Weather"
        case .web: return "Web Search"
        case .contacts: return "Contacts"
        case .calendar: return "Calendar"
        case .reminders: return "Reminders"
        case .location: return "Location"
        case .health: return "Health"
        case .music: return "Music"
        case .webMetadata: return "Web Metadata"
        }
    }

    var icon: String {
        switch self {
        case .weather: return "cloud.sun"
        case .web: return "magnifyingglass"
        case .contacts: return "person.2"
        case .calendar: return "calendar"
        case .reminders: return "checklist"
        case .location: return "location"
        case .health: return "heart"
        case .music: return "music.note"
        case .webMetadata: return "link.circle"
        }
    }

    var shortDescription: String {
        switch self {
        case .weather: return "Current conditions"
        case .web: return "Search the web"
        case .contacts: return "Find contacts"
        case .calendar: return "Manage events"
        case .reminders: return "Create reminders"
        case .location: return "Get location"
        case .health: return "Health data"
        case .music: return "Search music"
        case .webMetadata: return "Extract metadata"
        }
    }
}

// MARK: - Language Example Enum

enum LanguageExample: String, CaseIterable, Identifiable {
    case languageDetection = "language_detection"
    case multilingualResponses = "multilingual_responses"
    case sessionManagement = "session_management"
    case productionExample = "production_example"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .languageDetection:
            return "Language Detection"
        case .multilingualResponses:
            return "Multilingual Play"
        case .sessionManagement:
            return "Multiple Sessions"
        case .productionExample:
            return "Insights Example"
        }
    }

    var subtitle: String {
        switch self {
        case .languageDetection:
            return "Query and display supported languages"
        case .multilingualResponses:
            return "Generate responses in different languages"
        case .sessionManagement:
            return "Persistent session patterns across languages"
        case .productionExample:
            return "Real-world multilingual implementation"
        }
    }

    var icon: String {
        switch self {
        case .languageDetection:
            return "globe.badge.chevron.backward"
        case .multilingualResponses:
            return "text.bubble"
        case .sessionManagement:
            return "arrow.triangle.2.circlepath"
        case .productionExample:
            return "app.badge"
        }
    }
}

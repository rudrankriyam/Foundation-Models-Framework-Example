//
//  ExampleType.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/15/25.
//

import Foundation
import FoundationModels
import SwiftUI

enum ExampleType: String, CaseIterable, Identifiable {
    case basicChat = "basic_chat"
    case businessIdeas = "business_ideas"
    case creativeWriting = "creative_writing"
    case structuredData = "structured_data"
    case streamingResponse = "streaming_response"
    case modelAvailability = "model_availability"
    case generationGuides = "generation_guides"
    case generationOptions = "generation_options"

    var id: String { rawValue }

    var title: String {
        switch self {
            case .basicChat:
                return "One-shot"
            case .businessIdeas:
                return "Business Ideas"
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
        }
    }

    var subtitle: String {
        switch self {
            case .basicChat:
                return "Single prompt-response interaction"
            case .businessIdeas:
                return "Generate creative business concepts"
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
        }
    }

    var icon: String {
        switch self {
            case .basicChat:
                return "bubble.left.and.bubble.right"
            case .businessIdeas:
                return "lightbulb"
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
        }
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

    /// Creates the appropriate view for this tool
    /// - Returns: A SwiftUI view for the tool
    @MainActor @ViewBuilder
    func createView() -> some View {
        switch self {
            case .reminders:
                RemindersToolView()
            case .weather:
                WeatherToolView()
            case .web:
                WebToolView()
            case .contacts:
                ContactsToolView()
            case .calendar:
                CalendarToolView()
            case .location:
                LocationToolView()
            case .health:
                HealthToolView()
            case .music:
                MusicToolView()
            case .webMetadata:
                WebMetadataToolView()
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

    /// Creates the appropriate view for this language example
    /// - Returns: A SwiftUI view for the language example
    @MainActor @ViewBuilder
    func createView() -> some View {
        switch self {
        case .languageDetection:
            LanguageDetectionView()
        case .multilingualResponses:
            MultilingualResponsesView()
        case .sessionManagement:
            SessionManagementView()
        case .productionExample:
            ProductionLanguageExampleView()
        }
    }
}

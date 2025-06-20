//
//  ExampleType.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/15/25.
//

import Foundation
import FoundationModels

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
            return "Basic Chat"
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
            return "Simple back-and-forth conversation"
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

    @MainActor
    func execute(with viewModel: ContentViewModel) async {
        switch self {
        case .basicChat:
            await viewModel.executeBasicChat()
        case .businessIdeas:
            await viewModel.executeBusinessIdea()
        case .creativeWriting:
            await viewModel.executeCreativeWriting()
        case .structuredData:
            await viewModel.executeStructuredData()
        case .streamingResponse:
            await viewModel.executeStreaming()
        case .modelAvailability:
            await viewModel.executeModelAvailability()
        case .generationGuides:
            await viewModel.executeGenerationGuides()
        case .generationOptions:
            // Navigation handled by NavigationLink in ExamplesView
            break
        }
    }
}

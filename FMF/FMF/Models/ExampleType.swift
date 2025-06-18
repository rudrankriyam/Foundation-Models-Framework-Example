//
//  ExampleType.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/15/25.
//

import Foundation

enum ExampleType: String, CaseIterable, Identifiable {
  case basicChat
  case structuredData
  case generationGuides
  case streamingResponse
  case modelAvailability
  case creativeWriting
  case businessIdeas
  
  var id: String { rawValue }
  
  var title: String {
    switch self {
    case .basicChat:
      return "Basic Chat"
    case .structuredData:
      return "Structured Data"
    case .generationGuides:
      return "Generation Guides"
    case .streamingResponse:
      return "Streaming Response"
    case .modelAvailability:
      return "Model Availability"
    case .creativeWriting:
      return "Creative Writing"
    case .businessIdeas:
      return "Business Ideas"
    }
  }
  
  var subtitle: String {
    switch self {
    case .basicChat:
      return "Simple conversation with the model"
    case .structuredData:
      return "Generate typed objects from prompts"
    case .generationGuides:
      return "Constrained and guided outputs"
    case .streamingResponse:
      return "Real-time response streaming"
    case .modelAvailability:
      return "Check system capabilities"
    case .creativeWriting:
      return "Generate story outlines and narratives"
    case .businessIdeas:
      return "Generate startup concepts and plans"
    }
  }
  
  var icon: String {
    switch self {
    case .basicChat:
      return "message"
    case .structuredData:
      return "doc.text"
    case .generationGuides:
      return "slider.horizontal.3"
    case .streamingResponse:
      return "waveform"
    case .modelAvailability:
      return "checkmark.circle"
    case .creativeWriting:
      return "pencil.and.outline"
    case .businessIdeas:
      return "lightbulb"
    }
  }
  
  func execute(with viewModel: ContentViewModel) async {
    switch self {
    case .basicChat:
      await viewModel.executeBasicChat()
    case .structuredData:
      await viewModel.executeStructuredData()
    case .generationGuides:
      await viewModel.executeGenerationGuides()
    case .streamingResponse:
      await viewModel.executeStreaming()
    case .modelAvailability:
      await viewModel.executeModelAvailability()
    case .creativeWriting:
      await viewModel.executeCreativeWriting()
    case .businessIdeas:
      await viewModel.executeBusinessIdea()
    }
  }
}
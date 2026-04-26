//
//  ExampleType+Destination.swift
//  FoundationLab
//
//  Created by Codex on 4/26/26.
//

import SwiftUI

extension ExampleType {
    @MainActor
    @ViewBuilder
    var destination: some View {
        switch self {
        case .basicChat:
            BasicChatView()
        case .structuredData:
            StructuredDataView()
        case .generationGuides:
            GenerationGuidesView()
        case .streamingResponse:
            StreamingResponseView()
        case .journaling:
            JournalingView()
        case .creativeWriting:
            CreativeWritingView()
        case .modelAvailability:
            ModelAvailabilityView()
        case .generationOptions:
            GenerationOptionsView()
        case .health:
            HealthExampleView()
        case .rag:
            RAGChatView()
        case .chat:
            ChatView(title: "Session", showsDoneButton: false, tearsDownOnDisappear: false)
        }
    }

    var preferredTab: TabSelection {
        switch self {
        case .structuredData, .generationGuides, .generationOptions:
            return .studio
        case .health, .rag:
            return .insights
        case .chat:
            return .session
        case .basicChat, .journaling, .creativeWriting, .streamingResponse, .modelAvailability:
            return .home
        }
    }

    static var homeExamples: [ExampleType] {
        [.modelAvailability, .streamingResponse, .journaling, .creativeWriting]
    }

    static var studioExamples: [ExampleType] {
        [.structuredData, .generationGuides, .generationOptions]
    }

    static var insightExamples: [ExampleType] {
        [.health, .rag]
    }
}

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
        case .modelRuntime:
            ModelRuntimeView()
        case .contextWindowInspector:
            ContextWindowInspectorView()
        case .privateCloudCompute:
            PrivateCloudComputeView()
        case .imageInputPlayground:
            ImageInputPlaygroundView()
        case .toolCallingModeLab:
            ToolCallingModeLabView()
        case .dynamicProfileBuilder:
            DynamicProfileBuilderView()
        case .reasoningLevelComparison:
            ReasoningLevelComparisonView()
        case .transcriptExplorer:
            TranscriptExplorerView()
        case .agentFlowInspector:
            AgentFlowInspectorView()
        case .historyTransformLab:
            HistoryTransformLabView()
        case .riskyToolConfirmation:
            RiskyToolConfirmationDemoView()
        case .modelRouterDashboard:
            ModelRouterDashboardView()
        case .contextBudgetVisualizer:
            ContextBudgetVisualizerView()
        case .toolCallTrajectoryViewer:
            ToolCallTrajectoryViewerView()
        case .foundationModelsSecurityPlayground:
            FoundationModelsSecurityPlaygroundView()
        case .usagePerformanceTrace:
            UsagePerformanceTraceView()
        case .spotlightRAGExplorer:
            SpotlightRAGExplorerView()
        case .providerBridgeWalkthrough:
            ProviderBridgeWalkthroughView()
        case .evaluationsLab:
            EvaluationsLabView()
        case .fmCLIPythonPlayground:
            FMCLIPythonPlaygroundView()
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
        case .structuredData, .generationGuides, .generationOptions, .modelRuntime,
             .contextWindowInspector, .privateCloudCompute, .imageInputPlayground,
             .toolCallingModeLab, .dynamicProfileBuilder, .reasoningLevelComparison,
             .transcriptExplorer, .agentFlowInspector, .historyTransformLab,
             .riskyToolConfirmation, .modelRouterDashboard, .contextBudgetVisualizer,
             .toolCallTrajectoryViewer, .foundationModelsSecurityPlayground,
             .usagePerformanceTrace, .spotlightRAGExplorer, .providerBridgeWalkthrough,
             .evaluationsLab, .fmCLIPythonPlayground:
            return .lab
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
        [
            .structuredData,
            .generationGuides,
            .generationOptions,
            .modelRuntime,
            .contextWindowInspector,
            .privateCloudCompute,
            .imageInputPlayground,
            .toolCallingModeLab,
            .dynamicProfileBuilder,
            .reasoningLevelComparison,
            .transcriptExplorer,
            .agentFlowInspector,
            .historyTransformLab,
            .riskyToolConfirmation,
            .modelRouterDashboard,
            .contextBudgetVisualizer,
            .toolCallTrajectoryViewer,
            .foundationModelsSecurityPlayground,
            .usagePerformanceTrace,
            .spotlightRAGExplorer,
            .providerBridgeWalkthrough,
            .evaluationsLab,
            .fmCLIPythonPlayground
        ]
    }

    static var insightExamples: [ExampleType] {
        [.health, .rag]
    }
}

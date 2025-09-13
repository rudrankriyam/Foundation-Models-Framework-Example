//
//  ExamplesView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/15/25.
//

import SwiftUI
import FoundationModels

struct ExamplesView: View {
    @Binding var viewModel: ContentViewModel
    @Namespace private var glassNamespace
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                exampleButtonsView
                responseView
                loadingView
            }
            .padding(.vertical)
        }
        .navigationTitle("Foundation Models")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .navigationDestination(for: ExampleType.self) { exampleType in
            switch exampleType {
            case .basicChat:
                BasicChatView()
            case .structuredData:
                StructuredDataView()
            case .generationGuides:
                GenerationGuidesView()
            case .streamingResponse:
                StreamingResponseView()
            case .businessIdeas:
                BusinessIdeasView()
            case .creativeWriting:
                CreativeWritingView()
            case .modelAvailability:
                ModelAvailabilityView()
            case .generationOptions:
                GenerationOptionsView()
            }
        }
    }
    
    // MARK: - View Components
    
    
    private var exampleButtonsView: some View {
        LazyVGrid(columns: adaptiveGridColumns, spacing: Spacing.medium) {
            ForEach(ExampleType.allCases) { exampleType in
                NavigationLink(value: exampleType) {
                    GenericCardView(
                        icon: exampleType.icon,
                        title: exampleType.title,
                        subtitle: exampleType.subtitle
                    )
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.medium)
    }
    
    private var adaptiveGridColumns: [GridItem] {
#if os(iOS)
        // iPhone: 2 columns with flexible sizing and better spacing
        return [
            GridItem(.flexible(minimum: 140), spacing: 12),
            GridItem(.flexible(minimum: 140), spacing: 12)
        ]
#elseif os(macOS)
        // Mac: Adaptive columns based on available width
        return Array(repeating: GridItem(.adaptive(minimum: 280), spacing: 12), count: 1)
#else
        // Default fallback for other platforms
        return [
            GridItem(.flexible(minimum: 140), spacing: 12),
            GridItem(.flexible(minimum: 140), spacing: 12)
        ]
#endif
    }

    @ViewBuilder
    private var responseView: some View {
        if let requestResponse = viewModel.requestResponse {
            ResponseDisplayView(
                requestResponse: requestResponse,
                onClear: viewModel.clearResults
            )
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        if viewModel.isLoading {
            HStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Generating response...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
#if os(iOS) || os(macOS)
            .glassEffect(.regular, in: .capsule)
#endif
        }
    }
}

#Preview {
    ExamplesView(viewModel: .constant(ContentViewModel()))
}

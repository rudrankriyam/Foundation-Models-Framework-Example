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
    @State private var showChatFullscreen = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                chatSection
                examplesGridView
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
            case .health:
                HealthExampleView()
            case .chat:
                EmptyView()
            }
        }
        .fullScreenCover(isPresented: $showChatFullscreen) {
            NavigationStack {
                ChatView()
            }
        }
    }

    // MARK: - View Components

    private var chatSection: some View {
        Button(action: { showChatFullscreen = true }) {
            HStack(spacing: Spacing.medium) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Chat")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Multi-turn conversation with AI assistant")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
#if os(iOS) || os(macOS)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
#endif
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Spacing.medium)
    }

    private var examplesGridView: some View {
        LazyVGrid(columns: adaptiveGridColumns, spacing: Spacing.large) {
            ForEach(ExampleType.allCases.filter { $0 != .chat }) { exampleType in
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
            GridItem(.flexible(minimum: 140), spacing: Spacing.large),
            GridItem(.flexible(minimum: 140), spacing: Spacing.large)
        ]
#elseif os(macOS)
        // Mac: Adaptive columns based on available width
        return Array(repeating: GridItem(.adaptive(minimum: 280), spacing: Spacing.large), count: 1)
#else
        // Default fallback for other platforms
        return [
            GridItem(.flexible(minimum: 140), spacing: Spacing.large),
            GridItem(.flexible(minimum: 140), spacing: Spacing.large)
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

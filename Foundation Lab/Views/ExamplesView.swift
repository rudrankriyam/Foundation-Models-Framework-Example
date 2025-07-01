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
      VStack(alignment: .leading, spacing: 20) {
#if os(iOS)
        headerView
#endif
        exampleButtonsView
        toolsSection
        responseView
        loadingView
      }
      .padding(.vertical)
    }
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
    .navigationDestination(for: ToolExample.self) { tool in
      tool.createView()
        .withToolExecutor()
    }
  }

  // MARK: - View Components

  private var headerView: some View {
    VStack(alignment: .leading, spacing: Spacing.small) {
      Text("Foundation Models")
        .font(.largeTitle)
        .fontWeight(.bold)
      Text("Explore Apple's AI capabilities")
        .font(.callout)
        .foregroundColor(.secondary)
    }
    .padding(.horizontal, Spacing.medium)
  }

  private var exampleButtonsView: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Examples")
        .font(.title2)
        .fontWeight(.semibold)
        .padding(.horizontal, Spacing.medium)
      
      LazyVGrid(columns: adaptiveGridColumns, spacing: Spacing.medium) {
        ForEach(ExampleType.allCases) { exampleType in
          NavigationLink(value: exampleType) {
            ExampleCardView(type: exampleType)
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, Spacing.medium)
    }
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

  private var gridSpacing: CGFloat {
    #if os(iOS)
    16
    #else
    12
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
  
  private var toolsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Tools")
        .font(.title2)
        .fontWeight(.semibold)
        .padding(.horizontal, Spacing.medium)
      
      #if os(iOS) || os(macOS)
      GlassEffectContainer(spacing: gridSpacing) {
        LazyVGrid(columns: adaptiveGridColumns, spacing: gridSpacing) {
          ForEach(ToolExample.allCases, id: \.self) { tool in
            NavigationLink(value: tool) {
              ExampleToolButton(
                tool: tool,
                isSelected: false,
                isRunning: false,
                namespace: glassNamespace
              )
              .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
          }
        }
      }
      .padding(.horizontal)
      #else
      LazyVGrid(columns: adaptiveGridColumns, spacing: gridSpacing) {
        ForEach(ToolExample.allCases, id: \.self) { tool in
          NavigationLink(value: tool) {
            ExampleToolButton(
              tool: tool,
              isSelected: false,
              isRunning: false,
              namespace: glassNamespace
            )
            .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
      .padding(.horizontal)
      #endif
    }
  }
}

// MARK: - Tool Button Component

struct ExampleToolButton: View {
  let tool: ToolExample
  let isSelected: Bool
  let isRunning: Bool
  let namespace: Namespace.ID

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.small) {
      Image(systemName: tool.icon)
        .font(.title2)
        .foregroundStyle(.tint)
        .frame(width: 32, height: 32)
      
      VStack(alignment: .leading, spacing: Spacing.small) {
        Text(tool.displayName)
          .font(.callout)
          .fontWeight(.medium)
          .foregroundStyle(.primary)
          .lineLimit(1)
        
        Text(tool.shortDescription)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
      }
      
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(Spacing.medium)
    .background(Color.gray.opacity(0.1))
    .cornerRadius(12)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
    )
  }
}

#Preview {
  ExamplesView(viewModel: .constant(ContentViewModel()))
}

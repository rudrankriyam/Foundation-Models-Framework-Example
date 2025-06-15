//
//  ContentView.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//

import FoundationModels
import SwiftUI

struct ContentView: View {
  @State private var viewModel = ContentViewModel()

  var body: some View {
    TabView {
      // Examples Tab
      NavigationStack {
        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            headerView
            exampleButtonsView
            responseView
            loadingView
          }
          .padding(.vertical)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
            NavigationLink(destination: SettingsView()) {
              Image(systemName: "gear")
            }
          }
        }
      }
      .tabItem {
        Image(systemName: "brain.head.profile")
        Text("Examples")
      }

      // ChatBot Tab
      ChatBotView()
        .tabItem {
          Image(systemName: "message.badge.waveform")
          Text("ChatBot")
        }
    }
  }

  // MARK: - View Components

  private var headerView: some View {
    VStack(alignment: .leading, spacing: 8) {
      Image(systemName: "brain.head.profile")
        .imageScale(.large)
        .foregroundStyle(.tint)
      Text("Foundation Models")
        .font(.largeTitle)
        .fontWeight(.bold)
      Text("On-device AI Examples")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal)
  }

  private var exampleButtonsView: some View {
    LazyVGrid(columns: adaptiveGridColumns, spacing: 12) {
      ExampleButton(
        title: "Basic Chat",
        subtitle: "Simple conversation with the model",
        icon: "message"
      ) {
        await viewModel.executeBasicChat()
      }

      ExampleButton(
        title: "Structured Data",
        subtitle: "Generate typed objects from prompts",
        icon: "doc.text"
      ) {
        await viewModel.executeStructuredData()
      }

      ExampleButton(
        title: "Generation Guides",
        subtitle: "Constrained and guided outputs",
        icon: "slider.horizontal.3"
      ) {
        await viewModel.executeGenerationGuides()
      }

      ExampleButton(
        title: "Streaming Response",
        subtitle: "Real-time response streaming",
        icon: "waveform"
      ) {
        await viewModel.executeStreaming()
      }

      ExampleButton(
        title: "Model Availability",
        subtitle: "Check system capabilities",
        icon: "checkmark.circle"
      ) {
        await viewModel.executeModelAvailability()
      }

      ExampleButton(
        title: "Weather Tool",
        subtitle: "Compare weather in different cities",
        icon: "cloud.sun"
      ) {
        await viewModel.executeWeatherToolCalling()
      }

      ExampleButton(
        title: "Web Search Tool",
        subtitle: "Search for WWDC 2025 announcements",
        icon: "magnifyingglass"
      ) {
        await viewModel.executeWebSearchToolCalling()
      }

      ExampleButton(
        title: "Creative Writing",
        subtitle: "Generate story outlines and narratives",
        icon: "pencil.and.outline"
      ) {
        await viewModel.executeCreativeWriting()
      }

      ExampleButton(
        title: "Business Ideas",
        subtitle: "Generate startup concepts and plans",
        icon: "lightbulb"
      ) {
        await viewModel.executeBusinessIdea()
      }
    }
    .padding(.horizontal)
  }
  
  private var adaptiveGridColumns: [GridItem] {
    #if os(iOS)
    // iPhone: 2 columns with flexible sizing
    return [
      GridItem(.flexible(), spacing: 8),
      GridItem(.flexible(), spacing: 8)
    ]
    #elseif os(macOS)
    // Mac: Adaptive columns based on available width
    return Array(repeating: GridItem(.adaptive(minimum: 280), spacing: 12), count: 1)
    #else
    // Default fallback for other platforms
    return [
      GridItem(.flexible(), spacing: 8),
      GridItem(.flexible(), spacing: 8)
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
    }
  }
}

#Preview {
  ContentView()
}

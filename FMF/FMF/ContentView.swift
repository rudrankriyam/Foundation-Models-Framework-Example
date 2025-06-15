//
//  ContentView.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//

import FoundationModels
import SwiftUI

enum TabSelection: String, CaseIterable {
  case examples = "Examples"
  case chatBot = "ChatBot"
  case settings = "Settings"
}

struct ContentView: View {
  @State private var viewModel = ContentViewModel()
  @State private var chatBotViewModel = ChatBotViewModel()
  @State private var messageText = ""
  @State private var selectedTab: TabSelection = .examples

  var body: some View {
    TabView(selection: $selectedTab) {
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
      }
      .tabItem {
        Image(systemName: "brain.head.profile")
        Text("Examples")
      }
      .tag(TabSelection.examples)

      // ChatBot Tab
      NavigationStack {
        ChatBotView(viewModel: $chatBotViewModel)
      }
      .tabItem {
        Image(systemName: "message.badge.waveform")
        Text("ChatBot")
      }
      .tag(TabSelection.chatBot)

      // Settings Tab
      NavigationStack {
        SettingsView()
      }
      .tabItem {
        Image(systemName: "gear")
        Text("Settings")
      }
      .tag(TabSelection.settings)
    }
    .tabBarMinimizeBehavior(.onScrollUp)
    .tabViewBottomAccessory {
      if selectedTab == .chatBot {
        ChatInputAccessoryView(
          messageText: $messageText,
          chatBotViewModel: chatBotViewModel
        )
      }
    }
  }

  // MARK: - View Components

  private var headerView: some View {
    VStack(alignment: .leading, spacing: 8) {
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
    LazyVGrid(columns: adaptiveGridColumns, spacing: gridSpacing) {
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
    }
  }
}

// MARK: - Chat Input Accessory View

struct ChatInputAccessoryView: View {
  @Binding var messageText: String
  let chatBotViewModel: ChatBotViewModel
  @Environment(\.tabViewBottomAccessoryPlacement) private var placement
  @FocusState private var isTextFieldFocused: Bool
  
  var body: some View {
    HStack(spacing: 12) {
      TextField("Type your message...", text: $messageText, axis: .vertical)
        .textFieldStyle(.roundedBorder)
        .focused($isTextFieldFocused)
        .font(.system(size: isCollapsed ? 14 : 16))
        .onSubmit {
          sendMessage()
        }
      
      Button(action: sendMessage) {
        Image(systemName: "arrow.up.circle.fill")
          .font(.system(size: isCollapsed ? 20 : 24))
          .foregroundStyle(
            messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue
          )
      }
      .disabled(
        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
        chatBotViewModel.isLoading || 
        chatBotViewModel.isSummarizing
      )
    }
    .padding(.horizontal, isCollapsed ? 8 : 16)
    .padding(.vertical, isCollapsed ? 6 : 12)
    .background(backgroundMaterial)
    .animation(.easeInOut(duration: 0.3), value: placement)
  }
  
  private var isCollapsed: Bool {
    placement == .inline
  }
  
  private var backgroundMaterial: some ShapeStyle {
    if isCollapsed {
      return AnyShapeStyle(.ultraThinMaterial)
    } else {
      return AnyShapeStyle(.regularMaterial)
    }
  }
  
  private func sendMessage() {
    let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedMessage.isEmpty else { return }
    
    messageText = ""
    isTextFieldFocused = false
    
    Task {
      await chatBotViewModel.sendMessage(trimmedMessage)
    }
  }
}

#Preview {
  ContentView()
}

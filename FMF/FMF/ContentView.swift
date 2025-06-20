//
//  ContentView.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//

import SwiftUI
import FoundationModels

struct ContentView: View {
    @State private var viewModel = ContentViewModel()
    @State private var chatBotViewModel = ChatBotViewModel()
    @State private var messageText = ""
    @State private var selectedTab: TabSelection = .examples

    var body: some View {
        TabView(selection: $selectedTab) {
            // Examples Tab
            ExamplesView(viewModel: $viewModel)
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("Examples")
                }
                .tag(TabSelection.examples)

            // ChatBot Tab
            NavigationStack {
                ChatBotView(viewModel: $chatBotViewModel)
            }
            .tabItem {
                Image(systemName: "ellipsis.message")
                Text("Chat")
            }
            .tag(TabSelection.chatBot)

            // Tools Tab
            NavigationStack {
                ToolsTabView()
            }
            .tabItem {
                Image(systemName: "function")
                Text("Tools")
            }
            .tag(TabSelection.tools)

            // Settings Tab
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "slider.horizontal.3")
                Text("Settings")
            }
            .tag(TabSelection.settings)
        }

#if os(iOS)
        .tabBarMinimizeBehavior(.onScrollUp)
        .tabViewBottomAccessory {
            if selectedTab == .chatBot {
                ChatInputAccessoryView(
                    messageText: $messageText,
                    chatBotViewModel: chatBotViewModel
                )
            }
        }
#endif
    }
}

#Preview {
    ContentView()
}

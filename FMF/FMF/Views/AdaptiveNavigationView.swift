//
//  AdaptiveNavigationView.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/22/25.
//

import SwiftUI
import FoundationModels

struct AdaptiveNavigationView: View {
    @State private var navigationState = NavigationState()
    @State private var sidebarSelection: TabSelection? = .examples
    @State private var contentViewModel = ContentViewModel()
    @State private var chatViewModel = ChatViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
#if os(iOS)
        if horizontalSizeClass == .compact {
            // iPhone or iPad in compact width (portrait on smaller iPads)
            tabBasedNavigation
        } else {
            // iPad in regular width (landscape or larger iPads)
            splitViewNavigation
        }
#else
        // macOS always uses split view
        splitViewNavigation
#endif
    }
    
    private var tabBasedNavigation: some View {
        TabView(selection: $navigationState.tabSelection) {
            Tab("Examples", systemImage: "sparkles", value: .examples) {
                NavigationStack {
                    ExamplesView(viewModel: $contentViewModel)
                }
            }
            
            Tab("Chat", systemImage: "bubble.left.and.bubble.right", value: .chat) {
                NavigationStack {
                    ChatView(viewModel: $chatViewModel)
                }
            }
            
            Tab("Tools", systemImage: "wrench.and.screwdriver", value: .tools) {
                NavigationStack {
                    ToolsView()
                }
            }
            
            Tab("Settings", systemImage: "gear", value: .settings) {
                NavigationStack {
                    SettingsView()
                }
            }
        }
#if os(iOS)
        .ignoresSafeArea(.keyboard)
#endif
        .onChange(of: navigationState.tabSelection) { _, newValue in
            sidebarSelection = newValue
        }
    }
    
    private var splitViewNavigation: some View {
        NavigationSplitView(
            columnVisibility: $navigationState.splitViewVisibility
        ) {
            SidebarView(selection: $sidebarSelection)
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: sidebarSelection) { _, newValue in
            if let newValue {
                navigationState.tabSelection = newValue
            }
        }
    }
    
    @ViewBuilder
    private var detailView: some View {
        switch sidebarSelection ?? .examples {
        case .examples:
            ExamplesView(viewModel: $contentViewModel)
                .navigationTitle("Foundation Models")
        case .chat:
            ChatView(viewModel: $chatViewModel)
                .navigationTitle("Chat")
        case .tools:
            ToolsView()
                .navigationTitle("Tools")
        case .settings:
            SettingsView()
                .navigationTitle("Settings")
        }
    }
}

#Preview {
    AdaptiveNavigationView()
}
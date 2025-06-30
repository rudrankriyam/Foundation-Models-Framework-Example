//
//  AdaptiveNavigationView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/22/25.
//

import SwiftUI
import FoundationModels

struct AdaptiveNavigationView: View {
    @State private var contentViewModel = ContentViewModel()
    @State private var chatViewModel = ChatViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let navigationCoordinator = NavigationCoordinator.shared
    
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
        TabView(selection: .init(
            get: { navigationCoordinator.tabSelection },
            set: { navigationCoordinator.tabSelection = $0 }
        )) {
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
        .onChange(of: navigationCoordinator.tabSelection) { _, newValue in
            navigationCoordinator.splitViewSelection = newValue
        }
    }
    
    private var splitViewNavigation: some View {
        NavigationSplitView(
            columnVisibility: .constant(.automatic)
        ) {
            SidebarView(selection: .init(
                get: { navigationCoordinator.splitViewSelection },
                set: { navigationCoordinator.splitViewSelection = $0 }
            ))
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: navigationCoordinator.splitViewSelection) { _, newValue in
            if let newValue {
                navigationCoordinator.tabSelection = newValue
            }
        }
    }
    
    @ViewBuilder
    private var detailView: some View {
        switch navigationCoordinator.splitViewSelection ?? .examples {
        case .examples:
            NavigationStack {
                ExamplesView(viewModel: $contentViewModel)
                    .navigationTitle("Foundation Models")
            }
        case .chat:
            NavigationStack {
                ChatView(viewModel: $chatViewModel)
                    .navigationTitle("Chat")
            }
        case .tools:
            NavigationStack {
                ToolsView()
                    .navigationTitle("Tools")
            }
        case .settings:
            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
            }
        }
    }
}

#Preview {
    AdaptiveNavigationView()
}
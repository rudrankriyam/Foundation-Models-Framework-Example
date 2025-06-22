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
            navigationState.selectedTab = newValue
        }
    }
    
    private var splitViewNavigation: some View {
        NavigationSplitView(
            columnVisibility: $navigationState.splitViewVisibility
        ) {
            SidebarView(selection: $navigationState.selectedTab)
        } detail: {
            NavigationStack {
                detailView
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: navigationState.selectedTab) { _, newValue in
            if let newValue = newValue {
                navigationState.tabSelection = newValue
            }
        }
#if os(macOS)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: toggleSidebar) {
                    Image(systemName: "sidebar.left")
                }
                .keyboardShortcut("s", modifiers: [.command, .option])
                .help("Toggle Sidebar")
            }
        }
#endif
    }
    
    @ViewBuilder
    private var detailView: some View {
        switch navigationState.selectedTab {
        case .examples:
            ExamplesView(viewModel: $contentViewModel)
        case .chat:
            ChatView(viewModel: $chatViewModel)
        case .tools:
            ToolsView()
        case .settings:
            SettingsView()
        case nil:
            ContentUnavailableView(
                "Select a Section",
                systemImage: "sidebar.left",
                description: Text("Choose a section from the sidebar to get started")
            )
        }
    }
    
#if os(macOS)
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
#endif
}

#Preview {
    AdaptiveNavigationView()
}
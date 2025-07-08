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
            ForEach(TabSelection.allCases, id: \.self) { tab in
                Tab(tab.rawValue, systemImage: tab.systemImage, value: tab) {
                    NavigationStack {
                        contentView(for: tab)
                    }
                }
            }
        }
#if os(iOS)
        .tabBarMinimizeBehavior(.onScrollDown)
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
        NavigationStack {
            contentView(for: navigationCoordinator.splitViewSelection ?? .examples)
                .navigationTitle(navigationTitle(for: navigationCoordinator.splitViewSelection ?? .examples))
        }
    }
    
    @ViewBuilder
    private func contentView(for tab: TabSelection) -> some View {
        switch tab {
        case .examples:
            ExamplesView(viewModel: $contentViewModel)
        case .chat:
            ChatView(viewModel: $chatViewModel)
        case .bodyBuddy:
            BodyBuddyMainView()
        case .psylean:
            PsyleanMainView()
        case .settings:
            SettingsView()
        }
    }
    
    private func navigationTitle(for tab: TabSelection) -> String {
        switch tab {
        case .examples:
            return "Foundation Models"
        case .chat:
            return "Chat"
        case .bodyBuddy:
            return "Physiqa"
        case .psylean:
            return "Psylean"
        case .settings:
            return "Settings"
        }
    }
}

#Preview {
    AdaptiveNavigationView()
}

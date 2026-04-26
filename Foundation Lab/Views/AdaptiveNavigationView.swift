//
//  AdaptiveNavigationView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/22/25.
//

import SwiftUI
import FoundationModels

struct AdaptiveNavigationView: View {
    @State private var languageService = LanguageService()
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var navigationCoordinator = NavigationCoordinator.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
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
        .environment(languageService)
        .environment(navigationCoordinator)
    }

    @ViewBuilder
    private var tabBasedNavigation: some View {
        @Bindable var navigationCoordinator = navigationCoordinator
        TabView(selection: .init(
            get: { navigationCoordinator.tabSelection },
            set: { navigationCoordinator.tabSelection = $0 }
        )) {
            Tab(TabSelection.home.displayName, systemImage: "house.fill", value: .home) {
                NavigationStack(path: $navigationCoordinator.homePath) {
                    HomeView()
                }
            }

            Tab(TabSelection.session.displayName, systemImage: "bubble.left.and.bubble.right.fill", value: .session) {
                NavigationStack {
                    ChatView(title: "Session", showsDoneButton: false)
                }
            }

            Tab(TabSelection.studio.displayName, systemImage: "slider.horizontal.3", value: .studio) {
                NavigationStack(path: $navigationCoordinator.studioPath) {
                    StudioView()
                }
            }

            Tab(TabSelection.insights.displayName, systemImage: "sparkle.magnifyingglass", value: .insights) {
                NavigationStack(path: $navigationCoordinator.insightsPath) {
                    InsightsView()
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

    @ViewBuilder
    private var splitViewNavigation: some View {
        @Bindable var navigationCoordinator = navigationCoordinator
        NavigationSplitView(
            columnVisibility: $columnVisibility
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
        @Bindable var navigationCoordinator = navigationCoordinator
        switch navigationCoordinator.splitViewSelection ?? .home {
        case .home:
            NavigationStack(path: $navigationCoordinator.homePath) {
                HomeView()
            }
        case .session:
            NavigationStack {
                ChatView(title: "Session", showsDoneButton: false)
            }
        case .studio:
            NavigationStack(path: $navigationCoordinator.studioPath) {
                StudioView()
            }
        case .insights:
            NavigationStack(path: $navigationCoordinator.insightsPath) {
                InsightsView()
            }
        }
    }
}

#Preview {
    AdaptiveNavigationView()
}

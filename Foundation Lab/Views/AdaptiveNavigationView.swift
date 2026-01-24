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

    private var tabBasedNavigation: some View {
        @Bindable var navigationCoordinator = navigationCoordinator
        TabView(selection: .init(
            get: { navigationCoordinator.tabSelection },
            set: { navigationCoordinator.tabSelection = $0 }
        )) {
            Tab(TabSelection.examples.displayName, systemImage: "sparkles", value: .examples) {
                NavigationStack(path: $navigationCoordinator.examplesPath) {
                    ExamplesView()
                }
            }

            Tab(TabSelection.tools.displayName, systemImage: "wrench.and.screwdriver", value: .tools) {
                NavigationStack(path: $navigationCoordinator.toolsPath) {
                    ToolsView()
                }
            }

            Tab(TabSelection.schemas.displayName, systemImage: "doc.text", value: .schemas) {
                NavigationStack(path: $navigationCoordinator.schemasPath) {
                    SchemaExamplesView()
                }
            }

            Tab(TabSelection.languages.displayName, systemImage: "globe.badge.chevron.backward", value: .languages) {
                NavigationStack(path: $navigationCoordinator.languagesPath) {
                    LanguagesIntegrationsView()
                }
            }

            Tab(TabSelection.settings.displayName, systemImage: "gear", value: .settings) {
                NavigationStack {
                    SettingsView()
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
        switch navigationCoordinator.splitViewSelection ?? .examples {
        case .examples:
            NavigationStack(path: $navigationCoordinator.examplesPath) {
                ExamplesView()
            }
        case .tools:
            NavigationStack(path: $navigationCoordinator.toolsPath) {
                ToolsView()
            }
        case .schemas:
            NavigationStack(path: $navigationCoordinator.schemasPath) {
                SchemaExamplesView()
            }
        case .languages:
            NavigationStack(path: $navigationCoordinator.languagesPath) {
                LanguagesIntegrationsView()
            }
        case .settings:
            NavigationStack {
                SettingsView()
            }
        }
    }
}

#Preview {
    AdaptiveNavigationView()
}

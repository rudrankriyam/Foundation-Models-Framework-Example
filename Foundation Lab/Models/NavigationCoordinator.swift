//
//  NavigationCoordinator.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/25/25.
//

import SwiftUI
import Observation

@Observable
@MainActor
final class NavigationCoordinator {
    static let shared = NavigationCoordinator()

    var tabSelection: TabSelection = .home
    var splitViewSelection: TabSelection? = .home
    var homePath = NavigationPath()
    var studioPath = NavigationPath()
    var insightsPath = NavigationPath()

    private init() {}

    public func navigate(to tab: TabSelection) {
        tabSelection = tab
        splitViewSelection = tab
    }

    public func navigateToExample(_ example: ExampleType) {
        switch example.preferredTab {
        case .home:
            tabSelection = .home
            splitViewSelection = .home
            homePath = NavigationPath()
            homePath.append(example)
        case .session:
            openChat()
        case .studio:
            tabSelection = .studio
            splitViewSelection = .studio
            studioPath = NavigationPath()
            studioPath.append(example)
        case .insights:
            tabSelection = .insights
            splitViewSelection = .insights
            insightsPath = NavigationPath()
            insightsPath.append(example)
        }
    }

    public func navigateToTool(_ tool: ToolExample) {
        tabSelection = .studio
        splitViewSelection = .studio
        studioPath = NavigationPath()
        studioPath.append(tool)
    }

    public func navigateToSchema(_ schema: DynamicSchemaExampleType) {
        tabSelection = .studio
        splitViewSelection = .studio
        studioPath = NavigationPath()
        studioPath.append(schema)
    }

    public func navigateToLanguage(_ language: LanguageExample) {
        tabSelection = .studio
        splitViewSelection = .studio
        studioPath = NavigationPath()
        studioPath.append(language)
    }

    public func openChat() {
        tabSelection = .session
        splitViewSelection = .session
    }
}

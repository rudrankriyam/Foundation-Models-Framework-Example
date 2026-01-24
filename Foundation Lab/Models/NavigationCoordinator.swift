//
//  NavigationCoordinator.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/25/25.
//

import SwiftUI
import Observation

@Observable
final class NavigationCoordinator {
    @MainActor static let shared = NavigationCoordinator()

    var tabSelection: TabSelection = .examples
    var splitViewSelection: TabSelection? = .examples
    var examplesPath: [ExampleType] = []
    var toolsPath: [ToolExample] = []
    var schemasPath: [DynamicSchemaExampleType] = []
    var languagesPath: [LanguageExample] = []
    var showChat: Bool = false

    private init() {}

    @MainActor
    public func navigate(to tab: TabSelection) {
        tabSelection = tab
        splitViewSelection = tab
    }

    @MainActor
    public func navigateToExample(_ example: ExampleType) {
        tabSelection = .examples
        splitViewSelection = .examples
        examplesPath = [example]
    }

    @MainActor
    public func navigateToTool(_ tool: ToolExample) {
        tabSelection = .tools
        splitViewSelection = .tools
        toolsPath = [tool]
    }

    @MainActor
    public func navigateToSchema(_ schema: DynamicSchemaExampleType) {
        tabSelection = .schemas
        splitViewSelection = .schemas
        schemasPath = [schema]
    }

    @MainActor
    public func navigateToLanguage(_ language: LanguageExample) {
        tabSelection = .languages
        splitViewSelection = .languages
        languagesPath = [language]
    }

    @MainActor
    public func openChat() {
        tabSelection = .examples
        splitViewSelection = .examples
        showChat = true
    }
}

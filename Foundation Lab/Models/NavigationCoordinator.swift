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

    var tabSelection: TabSelection = .examples
    var splitViewSelection: TabSelection? = .examples
    var examplesPath: [ExampleType] = []
    var toolsPath: [ToolExample] = []
    var schemasPath: [DynamicSchemaExampleType] = []
    var languagesPath: [LanguageExample] = []
    var showChat: Bool = false

    private init() {}

    public func navigate(to tab: TabSelection) {
        tabSelection = tab
        splitViewSelection = tab
    }

    public func navigateToExample(_ example: ExampleType) {
        tabSelection = .examples
        splitViewSelection = .examples
        showChat = false
        examplesPath = [example]
    }

    public func navigateToTool(_ tool: ToolExample) {
        tabSelection = .tools
        splitViewSelection = .tools
        showChat = false
        toolsPath = [tool]
    }

    public func navigateToSchema(_ schema: DynamicSchemaExampleType) {
        tabSelection = .schemas
        splitViewSelection = .schemas
        showChat = false
        schemasPath = [schema]
    }

    public func navigateToLanguage(_ language: LanguageExample) {
        tabSelection = .languages
        splitViewSelection = .languages
        showChat = false
        languagesPath = [language]
    }

    public func openChat() {
        tabSelection = .examples
        splitViewSelection = .examples
        showChat = true
    }
}

//
//  ToolsPage.swift
//  FoundationLabUITests
//
//  Created by Rudrank Riyam on 2/11/26.
//

import XCTest

final class ToolsPage {
    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Tool Elements

    func toolButton(identifier: String) -> XCUIElement {
        app.buttons["toolButton_\(identifier)"]
    }

    func toolNavigationLink(identifier: String) -> XCUIElement {
        app.buttons["toolButton_\(identifier)"]
    }

    // MARK: - Common Tools

    var weatherToolButton: XCUIElement {
        toolButton(identifier: "weather")
    }

    var searchToolButton: XCUIElement {
        toolButton(identifier: "web")
    }

    var locationToolButton: XCUIElement {
        toolButton(identifier: "location")
    }

    // MARK: - Actions

    func tapTool(named name: String) {
        let toolButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[cd] %@", name)).firstMatch
        toolButton.tap()
    }

    func navigateToTool(identifier: String) {
        toolNavigationLink(identifier: identifier).tap()
    }
}

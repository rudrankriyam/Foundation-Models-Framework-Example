//
//  ChatPage.swift
//  FoundationLabUITests
//
//  Created by Rudrank Riyam on 2/11/26.
//

import XCTest

final class ChatPage {
    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Elements

    var textField: XCUIElement {
        let singleLine = app.textFields["chatTextField"]
        if singleLine.exists {
            return singleLine
        }
        return app.textViews["chatTextField"]
    }

    var sendButton: XCUIElement {
        app.buttons["sendButton"]
    }

    var voiceButton: XCUIElement {
        app.buttons["voiceButton"]
    }

    var clearChatButton: XCUIElement {
        app.buttons["clearChatButton"]
    }

    var emptyStateText: XCUIElement {
        app.staticTexts["emptyStateText"]
    }

    // MARK: - Actions

    func sendMessage(_ message: String) {
        textField.tap()
        textField.typeText(message)
        sendButton.tap()
    }

    func waitForResponse(timeout: TimeInterval = 30) -> Bool {
        let predicate = NSPredicate(
            format: "label CONTAINS[cd] %@ AND NOT (label CONTAINS[cd] %@)",
            "Assistant replied",
            "typing indicator"
        )
        let responseElement = app.descendants(matching: .any).matching(predicate).firstMatch
        return responseElement.waitForExistence(timeout: timeout)
    }

    func clearChat() {
        clearChatButton.tap()
    }
}

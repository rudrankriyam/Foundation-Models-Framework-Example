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
        app.textFields["chatTextField"]
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
        // Wait for the loading to finish by checking if there's a response
        let exists = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[cd] 'How can we help'")).count > 0
        return exists
    }

    func clearChat() {
        clearChatButton.tap()
    }
}

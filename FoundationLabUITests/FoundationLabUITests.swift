//
//  FoundationLabUITests.swift
//  FoundationLabUITests
//
//  Created by Rudrank Riyam on 2/11/26.
//

import XCTest

final class FoundationLabUITests: XCTestCase {

    private var app: XCUIApplication!
    private var chatPage: ChatPage!
    private var toolsPage: ToolsPage!
    private var settingsPage: SettingsPage!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        chatPage = ChatPage(app: app)
        toolsPage = ToolsPage(app: app)
        settingsPage = SettingsPage(app: app)
    }

    override func tearDownWithError() throws {
        app = nil
        chatPage = nil
        toolsPage = nil
        settingsPage = nil
    }

    // MARK: - App Launch Tests

    func testAppLaunchesSuccessfully() throws {
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.exists)
    }

    func testAppHasWindows() throws {
        app.launch()
        XCTAssertTrue(app.windows.count > 0)
    }

    // MARK: - Navigation Tests

    func testCanNavigateToToolsTab() throws {
        app.launch()
        app.buttons["Tools"].tap()
        XCTAssertTrue(app.navigationBars["Tools"].waitForExistence(timeout: 2))
    }

    func testCanNavigateToSettingsTab() throws {
        app.launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 2))
    }

    // MARK: - Chat Tests

    func testChatInputFieldExists() throws {
        app.launch()
        XCTAssertTrue(chatPage.textField.exists)
    }

    func testSendButtonExists() throws {
        app.launch()
        XCTAssertTrue(chatPage.sendButton.exists)
    }

    func testEmptyStateMessageDisplayed() throws {
        app.launch()
        XCTAssertTrue(chatPage.emptyStateText.exists)
    }

    func testVoiceButtonExists() throws {
        app.launch()
        XCTAssertTrue(chatPage.voiceButton.exists)
    }

    // MARK: - Tools Tests

    func testToolsPageLoads() throws {
        app.launch()
        app.buttons["Tools"].tap()
        XCTAssertTrue(app.navigationBars["Tools"].exists)
    }

    func testWeatherToolButtonExists() throws {
        app.launch()
        app.buttons["Tools"].tap()
        XCTAssertTrue(toolsPage.weatherToolButton.exists)
    }

    func testSearchToolButtonExists() throws {
        app.launch()
        app.buttons["Tools"].tap()
        XCTAssertTrue(toolsPage.searchToolButton.exists)
    }

    // MARK: - Settings Tests

    func testSettingsPageLoads() throws {
        app.launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
    }

    func testBugFeatureLinkExists() throws {
        app.launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(settingsPage.bugFeatureLink.exists)
    }

    func testVersionTextExists() throws {
        app.launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(settingsPage.versionText.exists)
    }
}

//
//  SettingsPage.swift
//  FoundationLabUITests
//
//  Created by Rudrank Riyam on 2/11/26.
//

import XCTest

final class SettingsPage {
    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Elements

    var bugFeatureLink: XCUIElement {
        app.links["bugFeatureLink"]
    }

    var madeByLink: XCUIElement {
        app.links["madeByLink"]
    }

    var versionText: XCUIElement {
        app.staticTexts["Version"]
    }

    // MARK: - Actions

    func tapBugFeatureLink() {
        bugFeatureLink.tap()
    }

    func tapMadeByLink() {
        madeByLink.tap()
    }
}

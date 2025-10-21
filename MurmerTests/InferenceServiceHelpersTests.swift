//
//  InferenceServiceHelpersTests.swift
//  MurmerTests
//
//  Created by Codex on 10/21/25.
//

import XCTest
@testable import Murmer

final class InferenceServiceHelpersTests: XCTestCase {

    func testTimezoneOffsetStringMatchesSystemTimeZone() {
        let formatter = DateFormatter()
        formatter.dateFormat = "xxx" // Produces ±HH:MM
        formatter.timeZone = .current

        let expected = formatter.string(from: Date())
        let actual = InferenceService.getTimezoneOffsetString()

        XCTAssertEqual(actual, expected)
    }
}

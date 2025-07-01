import XCTest
@testable import FoundationLabsKit

final class FoundationLabsKitTests: XCTestCase {
    func testColorExtensions() throws {
        // Test that colors are accessible
        _ = Color.secondaryBackgroundColor
        _ = Color.glassTintLight
        _ = HealthColors.primary
    }
}
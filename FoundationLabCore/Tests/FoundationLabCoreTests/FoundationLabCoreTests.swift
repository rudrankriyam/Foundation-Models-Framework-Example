import XCTest
@testable import FoundationLabCore

final class FoundationLabCoreTests: XCTestCase {
    func testCapabilityDescriptorStoresStableMetadata() {
        let descriptor = CapabilityDescriptor(
            id: "examples.book-recommendation",
            displayName: "Book Recommendation",
            summary: "Generates a structured book recommendation."
        )

        XCTAssertEqual(descriptor.id, "examples.book-recommendation")
        XCTAssertEqual(descriptor.displayName, "Book Recommendation")
    }

    func testFoundationLabCoreErrorHasReadableDescription() {
        let error = FoundationLabCoreError.invalidRequest("Missing prompt")

        XCTAssertEqual(error.errorDescription, "Invalid request: Missing prompt")
    }
}

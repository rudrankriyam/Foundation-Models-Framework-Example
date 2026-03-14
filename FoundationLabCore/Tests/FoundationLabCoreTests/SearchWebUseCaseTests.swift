import XCTest
@testable import FoundationLabCore

final class SearchWebUseCaseTests: XCTestCase {
    func testUseCaseRejectsBlankQuery() async {
        let useCase = SearchWebUseCase(searcher: WebSearcherStub())

        await XCTAssertThrowsErrorAsync(
            try await useCase.execute(
                SearchWebRequest(
                    query: "   ",
                    context: CapabilityInvocationContext(source: .app)
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FoundationLabCoreError,
                .invalidRequest("Missing query")
            )
        }
    }

    func testUseCaseDelegatesToSearcher() async throws {
        let expected = TextGenerationResult(
            content: "Top result summary.",
            metadata: CapabilityExecutionMetadata(
                provider: "Stub",
                modelIdentifier: "web-stub",
                tokenCount: 31
            )
        )
        let stub = WebSearcherStub(result: expected)
        let useCase = SearchWebUseCase(searcher: stub)

        let result = try await useCase.execute(
            SearchWebRequest(
                query: " Foundation Models Framework ",
                context: CapabilityInvocationContext(
                    source: .cli,
                    localeIdentifier: "en_US"
                )
            )
        )

        XCTAssertEqual(result, expected)
        XCTAssertEqual(stub.lastRequest?.query, " Foundation Models Framework ")
        XCTAssertEqual(stub.lastRequest?.context.source, .cli)
    }
}

private final class WebSearcherStub: WebSearching, @unchecked Sendable {
    private(set) var lastRequest: SearchWebRequest?
    private let result: TextGenerationResult

    init(
        result: TextGenerationResult = TextGenerationResult(
            content: "Default search result"
        )
    ) {
        self.result = result
    }

    func searchWeb(for request: SearchWebRequest) async throws -> TextGenerationResult {
        lastRequest = request
        return result
    }
}

private extension XCTestCase {
    func XCTAssertThrowsErrorAsync<T>(
        _ expression: @autoclosure () async throws -> T,
        _ errorHandler: (Error) -> Void
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error to be thrown")
        } catch {
            errorHandler(error)
        }
    }
}

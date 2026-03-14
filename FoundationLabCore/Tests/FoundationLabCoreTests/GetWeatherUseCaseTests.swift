import XCTest
@testable import FoundationLabCore

final class GetWeatherUseCaseTests: XCTestCase {
    func testUseCaseRejectsBlankLocation() async {
        let useCase = GetWeatherUseCase(responder: WeatherResponderStub())

        await XCTAssertThrowsErrorAsync(
            try await useCase.execute(
                GetWeatherRequest(
                    location: "   ",
                    context: CapabilityInvocationContext(source: .app)
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FoundationLabCoreError,
                .invalidRequest("Missing location")
            )
        }
    }

    func testUseCaseDelegatesToResponder() async throws {
        let expected = TextGenerationResult(
            content: "Sunny and 72F in San Francisco.",
            metadata: CapabilityExecutionMetadata(
                provider: "Stub",
                modelIdentifier: "weather-stub",
                tokenCount: 24
            )
        )
        let stub = WeatherResponderStub(result: expected)
        let useCase = GetWeatherUseCase(responder: stub)

        let result = try await useCase.execute(
            GetWeatherRequest(
                location: " San Francisco ",
                context: CapabilityInvocationContext(
                    source: .app,
                    localeIdentifier: "en_US"
                )
            )
        )

        XCTAssertEqual(result, expected)
        XCTAssertEqual(stub.lastRequest?.location, " San Francisco ")
        XCTAssertEqual(stub.lastRequest?.context.localeIdentifier, "en_US")
    }
}

private final class WeatherResponderStub: WeatherResponding, @unchecked Sendable {
    private(set) var lastRequest: GetWeatherRequest?
    private let result: TextGenerationResult

    init(
        result: TextGenerationResult = TextGenerationResult(
            content: "Default weather result"
        )
    ) {
        self.result = result
    }

    func weather(for request: GetWeatherRequest) async throws -> TextGenerationResult {
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

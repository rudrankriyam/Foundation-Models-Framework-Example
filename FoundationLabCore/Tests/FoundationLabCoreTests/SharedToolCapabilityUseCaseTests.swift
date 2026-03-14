import XCTest
@testable import FoundationLabCore

final class SharedToolCapabilityUseCaseTests: XCTestCase {
    func testSearchContactsUseCaseRejectsBlankQuery() async {
        let useCase = SearchContactsUseCase(searcher: ContactsSearcherStub())

        await XCTAssertThrowsErrorAsync(
            try await useCase.execute(
                SearchContactsRequest(
                    query: "   ",
                    context: CapabilityInvocationContext(source: .app)
                )
            )
        ) { error in
            XCTAssertEqual(error as? FoundationLabCoreError, .invalidRequest("Missing query"))
        }
    }

    func testSearchContactsUseCaseDelegatesToSearcher() async throws {
        let expected = TextGenerationResult(content: "Found Alex Example")
        let stub = ContactsSearcherStub(result: expected)
        let useCase = SearchContactsUseCase(searcher: stub)

        let result = try await useCase.execute(
            SearchContactsRequest(
                query: "Alex",
                context: CapabilityInvocationContext(source: .appIntent)
            )
        )

        XCTAssertEqual(result, expected)
        XCTAssertEqual(stub.lastRequest?.query, "Alex")
    }

    func testQueryCalendarUseCaseRejectsBlankQuery() async {
        let useCase = QueryCalendarUseCase(querier: CalendarQuerierStub())

        await XCTAssertThrowsErrorAsync(
            try await useCase.execute(
                QueryCalendarRequest(
                    query: " ",
                    context: CapabilityInvocationContext(source: .app)
                )
            )
        ) { error in
            XCTAssertEqual(error as? FoundationLabCoreError, .invalidRequest("Missing query"))
        }
    }

    func testQueryCalendarUseCaseDelegatesToQuerier() async throws {
        let expected = TextGenerationResult(content: "You have a meeting at 2 PM.")
        let stub = CalendarQuerierStub(result: expected)
        let useCase = QueryCalendarUseCase(querier: stub)

        let result = try await useCase.execute(
            QueryCalendarRequest(
                query: "What do I have today?",
                context: CapabilityInvocationContext(source: .app)
            )
        )

        XCTAssertEqual(result, expected)
        XCTAssertEqual(stub.lastRequest?.query, "What do I have today?")
    }

    func testManageRemindersUseCaseRejectsBlankCustomPrompt() async {
        let useCase = ManageRemindersUseCase(manager: ReminderManagerStub())

        await XCTAssertThrowsErrorAsync(
            try await useCase.execute(
                ManageRemindersRequest(
                    mode: .customPrompt,
                    customPrompt: " ",
                    context: CapabilityInvocationContext(source: .app)
                )
            )
        ) { error in
            XCTAssertEqual(error as? FoundationLabCoreError, .invalidRequest("Missing custom prompt"))
        }
    }

    func testManageRemindersUseCaseRejectsBlankQuickCreateTitle() async {
        let useCase = ManageRemindersUseCase(manager: ReminderManagerStub())

        await XCTAssertThrowsErrorAsync(
            try await useCase.execute(
                ManageRemindersRequest(
                    mode: .quickCreate,
                    title: " ",
                    context: CapabilityInvocationContext(source: .app)
                )
            )
        ) { error in
            XCTAssertEqual(error as? FoundationLabCoreError, .invalidRequest("Missing reminder title"))
        }
    }

    func testManageRemindersUseCaseDelegatesToManager() async throws {
        let expected = TextGenerationResult(content: "Reminder created successfully.")
        let stub = ReminderManagerStub(result: expected)
        let useCase = ManageRemindersUseCase(manager: stub)

        let result = try await useCase.execute(
            ManageRemindersRequest(
                mode: .quickCreate,
                title: "Call Mom",
                dueDate: .now,
                priority: .high,
                context: CapabilityInvocationContext(source: .app)
            )
        )

        XCTAssertEqual(result, expected)
        XCTAssertEqual(stub.lastRequest?.title, "Call Mom")
        XCTAssertEqual(stub.lastRequest?.priority, .high)
    }

    func testGetCurrentLocationUseCaseDelegatesToResponder() async throws {
        let expected = TextGenerationResult(content: "You are in Cupertino, CA.")
        let stub = LocationResponderStub(result: expected)
        let useCase = GetCurrentLocationUseCase(responder: stub)

        let result = try await useCase.execute(
            GetCurrentLocationRequest(
                context: CapabilityInvocationContext(source: .app)
            )
        )

        XCTAssertEqual(result, expected)
        XCTAssertEqual(stub.lastRequest?.context.source, .app)
    }

    func testSearchMusicCatalogUseCaseRejectsBlankQuery() async {
        let useCase = SearchMusicCatalogUseCase(searcher: MusicCatalogSearcherStub())

        await XCTAssertThrowsErrorAsync(
            try await useCase.execute(
                SearchMusicCatalogRequest(
                    query: "   ",
                    context: CapabilityInvocationContext(source: .app)
                )
            )
        ) { error in
            XCTAssertEqual(error as? FoundationLabCoreError, .invalidRequest("Missing query"))
        }
    }

    func testSearchMusicCatalogUseCaseDelegatesToSearcher() async throws {
        let expected = TextGenerationResult(content: "Found songs by Taylor Swift.")
        let stub = MusicCatalogSearcherStub(result: expected)
        let useCase = SearchMusicCatalogUseCase(searcher: stub)

        let result = try await useCase.execute(
            SearchMusicCatalogRequest(
                query: "Taylor Swift",
                context: CapabilityInvocationContext(source: .app)
            )
        )

        XCTAssertEqual(result, expected)
        XCTAssertEqual(stub.lastRequest?.query, "Taylor Swift")
    }

    func testGenerateWebPageSummaryUseCaseRejectsBlankURL() async {
        let useCase = GenerateWebPageSummaryUseCase(summarizer: WebPageSummarizerStub())

        await XCTAssertThrowsErrorAsync(
            try await useCase.execute(
                GenerateWebPageSummaryRequest(
                    url: " ",
                    context: CapabilityInvocationContext(source: .cli)
                )
            )
        ) { error in
            XCTAssertEqual(error as? FoundationLabCoreError, .invalidRequest("Missing URL"))
        }
    }

    func testGenerateWebPageSummaryUseCaseRejectsInvalidScheme() async {
        let useCase = GenerateWebPageSummaryUseCase(summarizer: WebPageSummarizerStub())

        await XCTAssertThrowsErrorAsync(
            try await useCase.execute(
                GenerateWebPageSummaryRequest(
                    url: "ftp://example.com",
                    context: CapabilityInvocationContext(source: .cli)
                )
            )
        ) { error in
            XCTAssertEqual(error as? FoundationLabCoreError, .invalidRequest("URL must use http or https"))
        }
    }

    func testGenerateWebPageSummaryUseCaseDelegatesToSummarizer() async throws {
        let expected = TextGenerationResult(content: "This page describes Foundation Models.")
        let stub = WebPageSummarizerStub(result: expected)
        let useCase = GenerateWebPageSummaryUseCase(summarizer: stub)

        let result = try await useCase.execute(
            GenerateWebPageSummaryRequest(
                url: "https://developer.apple.com",
                context: CapabilityInvocationContext(source: .app)
            )
        )

        XCTAssertEqual(result, expected)
        XCTAssertEqual(stub.lastRequest?.url, "https://developer.apple.com")
    }

    func testQueryHealthDataUseCaseRejectsBlankQuery() async {
        let useCase = QueryHealthDataUseCase(querier: HealthDataQuerierStub())

        await XCTAssertThrowsErrorAsync(
            try await useCase.execute(
                QueryHealthDataRequest(
                    query: " ",
                    context: CapabilityInvocationContext(source: .app)
                )
            )
        ) { error in
            XCTAssertEqual(error as? FoundationLabCoreError, .invalidRequest("Missing query"))
        }
    }

    func testQueryHealthDataUseCaseDelegatesToQuerier() async throws {
        let expected = TextGenerationResult(content: "You walked 8,000 steps today.")
        let stub = HealthDataQuerierStub(result: expected)
        let useCase = QueryHealthDataUseCase(querier: stub)

        let result = try await useCase.execute(
            QueryHealthDataRequest(
                query: "How many steps did I take today?",
                context: CapabilityInvocationContext(source: .app)
            )
        )

        XCTAssertEqual(result, expected)
        XCTAssertEqual(stub.lastRequest?.query, "How many steps did I take today?")
    }
}

private final class ContactsSearcherStub: ContactsSearching, @unchecked Sendable {
    private(set) var lastRequest: SearchContactsRequest?
    private let result: TextGenerationResult

    init(result: TextGenerationResult = TextGenerationResult(content: "Default contact result")) {
        self.result = result
    }

    func searchContacts(for request: SearchContactsRequest) async throws -> TextGenerationResult {
        lastRequest = request
        return result
    }
}

private final class CalendarQuerierStub: CalendarQuerying, @unchecked Sendable {
    private(set) var lastRequest: QueryCalendarRequest?
    private let result: TextGenerationResult

    init(result: TextGenerationResult = TextGenerationResult(content: "Default calendar result")) {
        self.result = result
    }

    func queryCalendar(for request: QueryCalendarRequest) async throws -> TextGenerationResult {
        lastRequest = request
        return result
    }
}

private final class ReminderManagerStub: ReminderManaging, @unchecked Sendable {
    private(set) var lastRequest: ManageRemindersRequest?
    private let result: TextGenerationResult

    init(result: TextGenerationResult = TextGenerationResult(content: "Default reminder result")) {
        self.result = result
    }

    func manageReminders(for request: ManageRemindersRequest) async throws -> TextGenerationResult {
        lastRequest = request
        return result
    }
}

private final class LocationResponderStub: LocationResponding, @unchecked Sendable {
    private(set) var lastRequest: GetCurrentLocationRequest?
    private let result: TextGenerationResult

    init(result: TextGenerationResult = TextGenerationResult(content: "Default location result")) {
        self.result = result
    }

    func getCurrentLocation(for request: GetCurrentLocationRequest) async throws -> TextGenerationResult {
        lastRequest = request
        return result
    }
}

private final class MusicCatalogSearcherStub: MusicCatalogSearching, @unchecked Sendable {
    private(set) var lastRequest: SearchMusicCatalogRequest?
    private let result: TextGenerationResult

    init(result: TextGenerationResult = TextGenerationResult(content: "Default music result")) {
        self.result = result
    }

    func searchMusic(for request: SearchMusicCatalogRequest) async throws -> TextGenerationResult {
        lastRequest = request
        return result
    }
}

private final class WebPageSummarizerStub: WebPageSummarizing, @unchecked Sendable {
    private(set) var lastRequest: GenerateWebPageSummaryRequest?
    private let result: TextGenerationResult

    init(result: TextGenerationResult = TextGenerationResult(content: "Default web summary")) {
        self.result = result
    }

    func summarizePage(for request: GenerateWebPageSummaryRequest) async throws -> TextGenerationResult {
        lastRequest = request
        return result
    }
}

private final class HealthDataQuerierStub: HealthDataQuerying, @unchecked Sendable {
    private(set) var lastRequest: QueryHealthDataRequest?
    private let result: TextGenerationResult

    init(result: TextGenerationResult = TextGenerationResult(content: "Default health result")) {
        self.result = result
    }

    func queryHealthData(for request: QueryHealthDataRequest) async throws -> TextGenerationResult {
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

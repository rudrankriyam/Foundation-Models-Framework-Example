import AppBenchCore
import XCTest

final class AppBenchLiveTests: XCTestCase {
    func testPracticalTaskCaptureScenario() async throws {
        let configuration = AppBenchRunConfiguration(
            suite: .quick,
            scenarios: [AppBenchScenarioCatalog.taskCapture],
            model: .onDevice,
            warmupCount: 0,
            repetitions: 1
        )

        let result = try await AppBenchRunner(configuration: configuration).run()

        XCTAssertEqual(result.trials.count, 1)
        XCTAssertTrue(result.failures.isEmpty)
        XCTAssertGreaterThan(result.trials[0].metrics.duration, 0)
        print(AppBenchReport(result: result).markdown())
    }
}

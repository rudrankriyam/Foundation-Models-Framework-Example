#if canImport(Evaluations) && compiler(>=6.4)
    import AppBenchCore
    import XCTest

    final class AppBenchEvaluationsAdapterTests: XCTestCase {
        func testConvertsScenarioCorpusToEvaluationSamples() throws {
            guard #available(macOS 27.0, iOS 27.0, visionOS 27.0, *) else { return }
            let samples = try AppBenchEvaluationsAdapter.samples(
                for: AppBenchScenarioCatalog.taskCapture
            )

            XCTAssertEqual(samples.count, 25)
            XCTAssertEqual(samples[0].expected, "task-capture-001")
            XCTAssertNotNil(samples[0].generationSchema)
        }

        func testCreatesToolCallEvaluatorForToolWorkloadsOnly() {
            guard #available(macOS 27.0, iOS 27.0, visionOS 27.0, *) else { return }
            XCTAssertNotNil(
                AppBenchEvaluationsAdapter.toolCallEvaluator(
                    for: AppBenchScenarioCatalog.groundedExplanation
                )
            )
            XCTAssertNil(
                AppBenchEvaluationsAdapter.toolCallEvaluator(
                    for: AppBenchScenarioCatalog.journalSummary
                )
            )
        }
    }
#endif

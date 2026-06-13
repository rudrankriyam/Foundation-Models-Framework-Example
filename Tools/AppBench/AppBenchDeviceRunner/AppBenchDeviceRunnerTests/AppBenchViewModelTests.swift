@testable import AppBenchDeviceRunner
import AppBenchCore
import XCTest

@MainActor
final class AppBenchViewModelTests: XCTestCase {
    func testSuiteChangesApplySuiteSampleDefaults() {
        let viewModel = AppBenchViewModel()

        XCTAssertEqual(viewModel.makeConfiguration().sampleLimit, 1)

        viewModel.selectedSuite = .full
        XCTAssertTrue(viewModel.useAllSamples)
        XCTAssertNil(viewModel.makeConfiguration().sampleLimit)

        viewModel.useAllSamples = false
        viewModel.samplesPerScenario = 3
        XCTAssertEqual(viewModel.makeConfiguration().sampleLimit, 3)

        viewModel.selectedSuite = .quick
        XCTAssertFalse(viewModel.useAllSamples)
        XCTAssertEqual(viewModel.makeConfiguration().sampleLimit, 1)
    }
}

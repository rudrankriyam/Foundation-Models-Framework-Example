import XCTest
import BenchmarkCore
import FoundationModels

final class BenchmarkTests: XCTestCase {

    func testFoundationModelsBenchmark() async throws {
        printAsciiBanner()
        printEnvironmentInfo()

        print("\n" + String(repeating: "=", count: 80))
        print("RUNNING FOUNDATION MODELS BENCHMARK")
        print(String(repeating: "=", count: 80))
        print()

        let runner = BenchmarkRunner()
        let result = try await runner.run()

        print("\nBenchmark completed successfully!")
        print("\nEstimated Metrics:")
        print("  Duration: \(String(format: "%.2fs", result.metrics.duration))")
        if let ttft = result.metrics.timeToFirstToken {
            print("  Time to First Token: \(String(format: "%.2fs", ttft))")
        }
        print("  Prompt Tokens (est.): \(result.metrics.promptTokenEstimate)")
        print("  Response Tokens (est.): \(result.metrics.responseTokenEstimate)")
        print("  Total Tokens (est.): \(result.metrics.totalTokenEstimate)")
        print("  Tokens/sec (est.): \(String(format: "%.2f", result.metrics.tokensPerSecond ?? 0))")

        print("\nResponse preview (first 200 chars):")
        let preview = String(result.responseText.prefix(200))
        print("  \(preview)...")
        print()

        print(String(repeating: "=", count: 80))
        print("xctrace instructions:")
        print("To get ACTUAL token counts with xctrace:")
        print("   xctrace record --instrument 'Foundation Models' \\")
        print("     --output token-test.trace \\")
        print("     --launch -- ./FoundationStudioTests")
        print()
        print("   Then export:")
        print("   xctrace export \\")
        print("     --input token-test.trace \\")
        print("     --xpath '/trace-toc/run[@number=\"1\"]/data/table[@schema=\"FoundationModelsTable\"]' \\")
        print("     > token-export.xml")
        print()

        XCTAssertGreaterThan(result.metrics.promptTokenEstimate, 0)
        XCTAssertGreaterThan(result.metrics.responseTokenEstimate, 1000)
        XCTAssertGreaterThan(result.metrics.tokensPerSecond ?? 0, 10)
    }

    private func printAsciiBanner() {
        print("""
╔═══════════════════════════════════════════════════════════════════════════════════════════════╗
║                                                                                               ║
║    ███████╗ ██████╗ ██╗   ██╗███╗   ██╗██████╗  █████╗ ████████╗██╗ ██████╗ ███╗   ██╗        ║
║    ██╔════╝██╔═══██╗██║   ██║████╗  ██║██╔══██╗██╔══██╗╚══██╔══╝██║██╔═══██╗████╗  ██║        ║
║    █████╗  ██║   ██║██║   ██║██╔██╗ ██║██║  ██║███████║   ██║   ██║██║   ██║██╔██╗ ██║        ║
║    ██╔══╝  ██║   ██║██║   ██║██║╚██╗██║██║  ██║██╔══██║   ██║   ██║██║   ██║██║╚██╗██║        ║
║    ██║     ╚██████╔╝╚██████╔╝██║ ╚████║██████╔╝██║  ██║   ██║   ██║╚██████╔╝██║ ╚████║        ║
║    ╚═╝      ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝        ║
║                                                                                               ║
║                    ███████╗████████╗██╗   ██╗██████╗ ██╗ ██████╗                              ║
║                    ██╔════╝╚══██╔══╝██║   ██║██╔══██╗██║██╔═══██╗                             ║
║                    ███████╗   ██║   ██║   ██║██║  ██║██║██║   ██║                             ║
║                    ╚════██║   ██║   ██║   ██║██║  ██║██║██║   ██║                             ║
║                    ███████║   ██║   ╚██████╔╝██████╔╝██║╚██████╔╝                             ║
║                    ╚══════╝   ╚═╝    ╚═════╝ ╚═════╝ ╚═╝ ╚═════╝                              ║
║                                                                                               ║
║                         Foundation Models Benchmarking Tool                                   ║
║                                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════════════════════╝
""")
        print(String(repeating: "=", count: 97))
        print()
    }

    private func printEnvironmentInfo() {
        let environment = EnvironmentSnapshot.capture()

        print("Environment")
        print(String(repeating: "-", count: 40))
        print("Device: \(environment.deviceName)")

        // Display hardware information if available
        if let cpuModel = environment.cpuModel {
            let cores = environment.cpuCores ?? 0
            print("CPU: \(cpuModel) \(cores)-core")
        }

        if let gpuModel = environment.gpuModel {
            print("GPU: \(gpuModel)")
        }

        if let totalMemory = environment.totalMemory {
            let memoryGB = Double(totalMemory) / (1024.0 * 1024.0 * 1024.0)
            print("RAM: \(String(format: "%.0f GB", memoryGB))")
        }

        print("OS: \(environment.systemName) \(environment.systemVersion)")
        print("Locale: \(environment.localeIdentifier)")
        print()
        print(String(repeating: "=", count: 80))
        print()
    }
}


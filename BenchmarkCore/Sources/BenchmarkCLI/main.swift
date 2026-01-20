import Foundation
import BenchmarkCore
import FoundationModels

@main
struct BenchmarkCLI {
    static func main() async {
        let arguments = CommandLine.arguments

        // Check for parse-xml command
        if arguments.count > 1 && arguments[1] == "parse-xml" {
            print("XML parsing functionality temporarily disabled - rebuilding...")
            exit(1)
        }

        // Check if running with xctrace (will have "token-test" argument)
        let runWithXctrace = arguments.contains("token-test")

        if runWithXctrace {
            await runWithXctraceRecording()
        } else {
            await runNormalBenchmark()
        }
    }

    static func runNormalBenchmark() async {
        await runBenchmark(
            header: {
                printAsciiBanner()
                printEnvironmentInfo()
            },
            completionMessage: "Benchmark completed successfully!",
            includeResponsePreview: true,
            includeXctraceInstructions: true
        )
    }

    static func runWithXctraceRecording() async {
        await runBenchmark(
            header: {
                print("Running benchmark with xctrace Foundation Models instrument recording...")
                print("Make sure xctrace is recording this process!")
                print()
            },
            completionMessage: "Benchmark completed!",
            includeResponsePreview: false,
            includeXctraceInstructions: true
        )
    }

    private static func runBenchmark(
        header: () -> Void,
        completionMessage: String,
        includeResponsePreview: Bool,
        includeXctraceInstructions: Bool
    ) async {
        do {
            header()

            let runner = BenchmarkRunner()
            let result = try await runner.run()

            print("\n\(completionMessage)")
            print("\nEstimated Metrics:")
            print("  Duration: \(String(format: "%.2fs", result.metrics.duration))")
            if let ttft = result.metrics.timeToFirstToken {
                print("  Time to First Token: \(String(format: "%.2fs", ttft))")
            }
            print("  Prompt Tokens (est.): \(result.metrics.promptTokenEstimate)")
            print("  Response Tokens (est.): \(result.metrics.responseTokenEstimate)")
            print("  Total Tokens (est.): \(result.metrics.totalTokenEstimate)")
            print("  Tokens/sec (est.): \(String(format: "%.2f", result.metrics.tokensPerSecond ?? 0))")

            if includeResponsePreview {
                print("\nResponse preview (first 200 chars):")
                let preview = String(result.responseText.prefix(200))
                print("  \(preview)...")
                print()
            }

            if includeXctraceInstructions {
                print(String(repeating: "=", count: 80))
                if includeResponsePreview {
                    print("To get ACTUAL token counts with xctrace:")
                    print("   xctrace record --instrument 'Foundation Models' \\")
                    print("     --output token-test.trace \\")
                    print("     --launch -- ./BenchmarkCLI -- token-test")
                    print()
                    print("   Then export:")
                    print("   xctrace export \\")
                    print("     --input token-test.trace \\")
                    print("     --xpath '/trace-toc/run[@number=\"1\"]/data/table" +
                          "[@schema=\"FoundationModelsTable\"]' \\")
                    print("     > token-export.xml")
                } else {
                    print("To extract actual token data, export the trace:")
                    print("   xctrace export \\")
                    print("     --input token-test.trace \\")
                    print("     --xpath '/trace-toc/run[@number=\"1\"]/data/table" +
                          "[@schema=\"FoundationModelsTable\"]' \\")
                    print("     > token-export.xml")
                }
            }
        } catch {
            print("Error: \(error)")
            exit(1)
        }
    }

    private static func printAsciiBanner() {
        print("""
    ╔══════════════════════════════════════════════════════════════════════════════╗
    ║                                                                              ║
    ║         ██╗  ██╗ █████╗ ███╗   ██╗██████╗  █████╗ ██████╗  █████╗ ██████╗      ║
    ║         ██║  ██║██╔══██╗████╗  ██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔══██╗     ║
    ║         ███████║███████║██╔██╗ ██║██║  ██║███████║██║  ██║███████║██████╔╝     ║
    ║         ██╔══██║██╔══██║██║╚██╗██║██║  ██║██╔══██║██║  ██║██╔══██║██╔══██╗     ║
    ║         ██║  ██║██║  ██║██║ ╚████║██████╔╝██║  ██║██████╔╝██║  ██║██║  ██║     ║
    ║         ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝     ║
    ║                                                                              ║
    ║                    Foundation Models Benchmarking Tool                        ║
    ║                                                                              ║
    ╚══════════════════════════════════════════════════════════════════════════════╝
    """)
        print(String(repeating: "=", count: 80))
        print()
    }

    private static func printEnvironmentInfo() {
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

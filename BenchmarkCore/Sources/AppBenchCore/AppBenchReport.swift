import Foundation

public struct AppBenchReport: Sendable {
    public let result: AppBenchRunResult

    public init(result: AppBenchRunResult) {
        self.result = result
    }

    public func json(prettyPrinted: Bool = true) throws -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = prettyPrinted ? [.prettyPrinted, .sortedKeys] : []
        let data = try encoder.encode(result)
        guard let value = String(data: data, encoding: .utf8) else {
            throw CocoaError(.coderInvalidValue)
        }
        return value
    }

    public func markdown() -> String {
        var lines = [
            "# Foundation Models AppBench",
            "",
            "- Suite: \(result.suite.displayName)",
            "- Model: \(result.model.displayName)",
            "- Warmups: \(result.warmupCount)",
            "- Repetitions: \(result.repetitions)",
            "- Started: \(result.startedAt.formatted(.iso8601))",
            "- Failures: \(result.failures.count)",
            "",
            "| Scenario | Prompt pass | Constraint score | Median TTFT | Median output tok/s |",
            "| --- | ---: | ---: | ---: | ---: |"
        ]

        for summary in result.summaries {
            lines.append(
                "| \(summary.title) | \(percent(summary.promptPassRate)) | " +
                "\(percent(summary.meanConstraintScore)) | \(seconds(summary.timeToFirstToken.median)) | " +
                "\(number(summary.outputTokensPerSecond.median)) |"
            )
        }

        lines.append("")
        lines.append("## Environment")
        let environment = result.environment
        lines.append("- Device: \(environment.deviceName)")
        lines.append("- Hardware: \(environment.hardwareModel ?? "unknown")")
        lines.append("- Chip: \(environment.cpuModel ?? "unknown")")
        lines.append("- OS: \(environment.systemName) \(environment.systemVersion) (\(environment.systemBuild ?? "unknown"))")
        lines.append("- Memory: \(memory(environment.totalMemory))")
        lines.append("- Thermal state: \(environment.thermalState)")
        lines.append("- Low Power Mode: \(environment.lowPowerModeEnabled ? "on" : "off")")
        lines.append("- AppBench commit: \(environment.appBenchCommit ?? "unknown")")

        return lines.joined(separator: "\n")
    }

    private func percent(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(1)))
    }

    private func seconds(_ value: Double?) -> String {
        guard let value else { return "n/a" }
        return value.formatted(.number.precision(.fractionLength(3))) + "s"
    }

    private func number(_ value: Double?) -> String {
        guard let value else { return "n/a" }
        return value.formatted(.number.precision(.fractionLength(2)))
    }

    private func memory(_ bytes: UInt64?) -> String {
        guard let bytes else { return "unknown" }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .memory)
    }
}

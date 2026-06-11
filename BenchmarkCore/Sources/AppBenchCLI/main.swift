import AppBenchCore
import Foundation

@main
struct AppBenchCLI {
    static func main() async {
        do {
            let arguments = Array(CommandLine.arguments.dropFirst())
            if arguments.first == "list" {
                printScenarioList()
                return
            }

            let options = try CLIOptions(arguments: arguments)
            printHeader(options: options)

            let configuration = AppBenchRunConfiguration(
                suite: options.suite,
                scenarios: options.scenarioID.flatMap { id in
                    AppBenchScenarioCatalog.all.filter { $0.id == id }
                },
                model: options.model,
                warmupCount: options.warmups,
                repetitions: options.repetitions
            )
            let result = try await AppBenchRunner(configuration: configuration).run()
            let report = AppBenchReport(result: result)

            print(report.markdown())
            try write(report: report, options: options)

            if !result.failures.isEmpty {
                print("\nFailures:")
                for failure in result.failures {
                    print("- \(failure.scenarioID) run \(failure.iteration): \(failure.message)")
                }
                exit(2)
            }
        } catch {
            print("AppBench failed: \(error.localizedDescription)")
            printUsage()
            exit(1)
        }
    }

    private static func printHeader(options: CLIOptions) {
        print("Foundation Models AppBench")
        print(String(repeating: "=", count: 80))
        print("Suite: \(options.suite.displayName)")
        print("Model: \(options.model.displayName)")
        print("Warmups: \(options.warmups)")
        print("Repetitions: \(options.repetitions)")
        if let scenarioID = options.scenarioID {
            print("Scenario: \(scenarioID)")
        }
        print()
    }

    private static func printScenarioList() {
        print("Foundation Models AppBench scenarios\n")
        for scenario in AppBenchScenarioCatalog.all {
            print("\(scenario.id)")
            print("  \(scenario.title)")
            print("  \(scenario.category.displayName) • inspired by \(scenario.inspiredBy.joined(separator: ", "))")
            print()
        }
    }

    private static func write(report: AppBenchReport, options: CLIOptions) throws {
        if let jsonPath = options.jsonPath {
            try report.json().write(toFile: jsonPath, atomically: true, encoding: .utf8)
            print("\nJSON: \(jsonPath)")
        }
        if let markdownPath = options.markdownPath {
            try report.markdown().write(toFile: markdownPath, atomically: true, encoding: .utf8)
            print("Markdown: \(markdownPath)")
        }
    }

    private static func printUsage() {
        print("""

        Usage:
          ./appbench list
          ./appbench [run] [options]

        Options:
          --suite quick|full|performance
          --model on-device|pcc
          --scenario <scenario-id>
          --warmups <count>
          --repetitions <count>
          --json <path>
          --markdown <path>
        """)
    }
}

private struct CLIOptions {
    enum Error: Swift.Error, LocalizedError {
        case missingValue(String)
        case invalidValue(flag: String, value: String)
        case unknownArgument(String)
        case unknownScenario(String)

        var errorDescription: String? {
            switch self {
            case .missingValue(let flag):
                "Missing value for \(flag)."
            case .invalidValue(let flag, let value):
                "Invalid value “\(value)” for \(flag)."
            case .unknownArgument(let value):
                "Unknown argument “\(value)”."
            case .unknownScenario(let value):
                "Unknown scenario “\(value)”."
            }
        }
    }

    var suite: AppBenchSuite = .quick
    var model: AppBenchModel = .onDevice
    var scenarioID: String?
    var warmups = 1
    var repetitions = 3
    var jsonPath: String?
    var markdownPath: String?

    init(arguments: [String]) throws {
        var index = arguments.first == "run" ? 1 : 0
        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "--suite":
                let value = try Self.value(after: argument, at: &index, in: arguments)
                guard let suite = AppBenchSuite(rawValue: value) else {
                    throw Error.invalidValue(flag: argument, value: value)
                }
                self.suite = suite
            case "--model":
                let value = try Self.value(after: argument, at: &index, in: arguments)
                switch value {
                case "on-device":
                    model = .onDevice
                case "pcc":
                    model = .privateCloudCompute
                default:
                    throw Error.invalidValue(flag: argument, value: value)
                }
            case "--scenario":
                let value = try Self.value(after: argument, at: &index, in: arguments)
                guard AppBenchScenarioCatalog.all.contains(where: { $0.id == value }) else {
                    throw Error.unknownScenario(value)
                }
                scenarioID = value
            case "--warmups":
                let value = try Self.value(after: argument, at: &index, in: arguments)
                guard let count = Int(value), count >= 0 else {
                    throw Error.invalidValue(flag: argument, value: value)
                }
                warmups = count
            case "--repetitions":
                let value = try Self.value(after: argument, at: &index, in: arguments)
                guard let count = Int(value), count > 0 else {
                    throw Error.invalidValue(flag: argument, value: value)
                }
                repetitions = count
            case "--json":
                jsonPath = try Self.value(after: argument, at: &index, in: arguments)
            case "--markdown":
                markdownPath = try Self.value(after: argument, at: &index, in: arguments)
            default:
                throw Error.unknownArgument(argument)
            }
            index += 1
        }
    }

    private static func value(
        after flag: String,
        at index: inout Int,
        in arguments: [String]
    ) throws -> String {
        index += 1
        guard index < arguments.count else {
            throw Error.missingValue(flag)
        }
        return arguments[index]
    }
}

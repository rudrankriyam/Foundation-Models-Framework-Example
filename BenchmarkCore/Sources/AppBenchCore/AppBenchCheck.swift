import Foundation

public enum AppBenchJSONValue: Codable, Equatable, Sendable {
    case string(String)
    case integer(Int)
    case number(Double)
    case boolean(Bool)
}

public enum AppBenchCheck: Codable, Sendable {
    case contains(String)
    case excludes(String)
    case minimumWords(Int)
    case maximumWords(Int)
    case jsonEquals(path: String, value: AppBenchJSONValue)
    case jsonContains(path: String, values: [String])

    public var label: String {
        switch self {
        case .contains(let value):
            "Contains “\(value)”"
        case .excludes(let value):
            "Excludes “\(value)”"
        case .minimumWords(let count):
            "At least \(count) words"
        case .maximumWords(let count):
            "At most \(count) words"
        case .jsonEquals(let path, let value):
            "\(path) equals \(value.description)"
        case .jsonContains(let path, let values):
            "\(path) contains \(values.joined(separator: ", "))"
        }
    }
}

private extension AppBenchJSONValue {
    var description: String {
        switch self {
        case .string(let value):
            value
        case .integer(let value):
            String(value)
        case .number(let value):
            String(value)
        case .boolean(let value):
            String(value)
        }
    }
}

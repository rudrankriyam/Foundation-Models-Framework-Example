//
//  NestedSchemaFormatter.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import FoundationModels

/// Utility class for formatting nested schema content
struct NestedSchemaFormatter {

    static func formatNestedContent(_ content: GeneratedContent, indent: Int = 0) -> String {
        switch content.kind {
        case .structure(let properties, let orderedKeys):
            return formatStructureContent(properties: properties, orderedKeys: orderedKeys, indent: indent)
        case .array(let elements):
            return formatArrayContent(elements: elements, indent: indent)
        case .string(let str):
            return "\"\(str)\""
        case .number(let num):
            return String(num)
        case .bool(let bool):
            return String(bool)
        case .null:
            return "null"
        @unknown default:
            return "unknown"
        }
    }

    private static func formatStructureContent(properties: [String: GeneratedContent], orderedKeys: [String], indent: Int) -> String {
        let indentStr = String(repeating: "  ", count: indent)
        var result = "\n\(indentStr){"

        for key in orderedKeys {
            if let value = properties[key] {
                result += "\n\(indentStr)  \"\(key)\": "
                result += formatValueContent(value, indent: indent + 1)
                if key != orderedKeys.last {
                    result += ","
                }
            }
        }

        result += "\n\(indentStr)}"
        return result
    }

    private static func formatArrayContent(elements: [GeneratedContent], indent: Int) -> String {
        let indentStr = String(repeating: "  ", count: indent)
        var result = "["

        for (index, element) in elements.enumerated() {
            result += "\n\(indentStr)  " + formatValueContent(element, indent: indent + 1)
            if index < elements.count - 1 {
                result += ","
            }
        }

        result += "\n\(indentStr)]"
        return result
    }

    private static func formatValueContent(_ content: GeneratedContent, indent: Int) -> String {
        switch content.kind {
        case .structure(let properties, let orderedKeys):
            return formatStructureContent(properties: properties, orderedKeys: orderedKeys, indent: indent)
        case .array(let elements):
            return formatArrayContent(elements: elements, indent: indent)
        case .string(let str):
            return "\"\(str)\""
        case .number(let num):
            return String(num)
        case .bool(let bool):
            return String(bool)
        case .null:
            return "null"
        @unknown default:
            return "unknown"
        }
    }

    static func countNestingLevels(_ content: GeneratedContent, currentLevel: Int = 0) -> Int {
        switch content.kind {
        case .structure(let properties, _):
            return countStructureNesting(properties: properties, currentLevel: currentLevel)
        case .array(let elements):
            return countArrayNesting(elements: elements, currentLevel: currentLevel)
        case .string, .number, .bool, .null:
            return currentLevel
        @unknown default:
            return currentLevel
        }
    }

    private static func countStructureNesting(properties: [String: GeneratedContent], currentLevel: Int) -> Int {
        var maxLevel = currentLevel + 1

        for (_, value) in properties {
            let nestedLevel = countValueNesting(value, currentLevel: currentLevel + 1)
            maxLevel = max(maxLevel, nestedLevel)
        }

        return maxLevel
    }

    private static func countArrayNesting(elements: [GeneratedContent], currentLevel: Int) -> Int {
        var maxLevel = currentLevel + 1

        for element in elements {
            let nestedLevel = countNestingLevels(element, currentLevel: currentLevel + 1)
            maxLevel = max(maxLevel, nestedLevel)
        }

        return maxLevel
    }

    private static func countValueNesting(_ content: GeneratedContent, currentLevel: Int) -> Int {
        switch content.kind {
        case .structure(let properties, _):
            return countStructureNesting(properties: properties, currentLevel: currentLevel)
        case .array(let elements):
            return countArrayNesting(elements: elements, currentLevel: currentLevel)
        case .string, .number, .bool, .null:
            return currentLevel
        @unknown default:
            return currentLevel
        }
    }
}

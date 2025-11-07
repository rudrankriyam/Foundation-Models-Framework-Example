//
//  FormBuilderSchemaHelpers.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationModels

extension FormBuilderSchemaView {
    func addPersonalInfoFields(to properties: inout [DynamicGenerationSchema.Property], for lowercased: String) {
        if lowercased.contains("personal") || lowercased.contains("name") {
            properties.append(
                DynamicGenerationSchema.Property(
                    name: "name",
                    description: "Full name",
                    schema: .init(type: String.self)
                )
            )
        }

        if lowercased.contains("email") || lowercased.contains("contact") {
            properties.append(
                DynamicGenerationSchema.Property(
                    name: "email",
                    description: "Email address",
                    schema: .init(
                        type: String.self,
                        guides: [.pattern(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z] {2,}$/)]
                    )
                )
            )
        }

        if lowercased.contains("phone") || lowercased.contains("contact") {
            properties.append(
                DynamicGenerationSchema.Property(
                    name: "phone",
                    description: "Phone number (US format)",
                    schema: .init(
                        type: String.self,
                        guides: [.pattern(/\(\d {3}\) \d {3}-\d {4}/)]
                    ),
                    isOptional: true
                )
            )
        }
    }

    func addExperienceFields(to properties: inout [DynamicGenerationSchema.Property], for lowercased: String) {
        if lowercased.contains("experience") || lowercased.contains("job") {
            properties.append(
                DynamicGenerationSchema.Property(
                    name: "yearsOfExperience",
                    description: "Years of professional experience",
                    schema: .init(
                        type: Int.self,
                        guides: [.range(0...50)]
                    ),
                    isOptional: true
                )
            )

            properties.append(
                DynamicGenerationSchema.Property(
                    name: "currentPosition",
                    description: "Current job title",
                    schema: .init(type: String.self),
                    isOptional: true
                )
            )
        }
    }

    func addSkillsFields(to properties: inout [DynamicGenerationSchema.Property], for lowercased: String) {
        if lowercased.contains("skill") {
            properties.append(
                DynamicGenerationSchema.Property(
                    name: "skills",
                    description: "List of skills",
                    schema: .init(arrayOf: .init(type: String.self))
                )
            )
        }
    }

    func addCommonFields(to properties: inout [DynamicGenerationSchema.Property]) {
        properties.append(
            DynamicGenerationSchema.Property(
                name: "availability",
                description: "When available to start",
                schema: .init(type: String.self),
                isOptional: true
            )
        )

        properties.append(
            DynamicGenerationSchema.Property(
                name: "salaryExpectation",
                description: "Salary expectation or range",
                schema: .init(type: String.self),
                isOptional: true
            )
        )

        properties.append(
            DynamicGenerationSchema.Property(
                name: "remoteWork",
                description: "Open to remote work",
                schema: .init(type: Bool.self),
                isOptional: true
            )
        )
    }

    func createPredefinedJobApplicationSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "JobApplication",
            description: "Job application form data",
            properties: [
                createPersonalInfoProperty(),
                createExperienceProperty(),
                createPreferencesProperty()
            ]
        )
    }

    func createPersonalInfoProperty() -> DynamicGenerationSchema.Property {
        DynamicGenerationSchema.Property(
            name: "personalInfo",
            description: "Personal information",
            schema: createPersonalInfoSchema()
        )
    }

    func createPersonalInfoSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "PersonalInfo",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "fullName",
                    description: "Applicant's full name",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "email",
                    description: "Email address",
                    schema: .init(
                        type: String.self,
                        guides: [.pattern(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z] {2,}$/)]
                    )
                ),
                DynamicGenerationSchema.Property(
                    name: "phone",
                    description: "Phone number",
                    schema: .init(
                        type: String.self,
                        guides: [.pattern(/\(\d {3}\) \d {3}-\d {4}/)]
                    ),
                    isOptional: true
                )
            ]
        )
    }

    func createExperienceProperty() -> DynamicGenerationSchema.Property {
        DynamicGenerationSchema.Property(
            name: "experience",
            description: "Professional experience",
            schema: createExperienceSchema()
        )
    }

    func createExperienceSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "Experience",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "years",
                    description: "Years of experience",
                    schema: .init(
                        type: Int.self,
                        guides: [.range(0...50)]
                    )
                ),
                DynamicGenerationSchema.Property(
                    name: "currentRole",
                    description: "Current position",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "skills",
                    description: "Technical skills",
                    schema: .init(arrayOf: .init(type: String.self))
                )
            ]
        )
    }

    func createPreferencesProperty() -> DynamicGenerationSchema.Property {
        DynamicGenerationSchema.Property(
            name: "preferences",
            description: "Job preferences",
            schema: createPreferencesSchema()
        )
    }

    func createPreferencesSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
            name: "Preferences",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "startDate",
                    description: "Available to start",
                    schema: .init(type: String.self)
                ),
                DynamicGenerationSchema.Property(
                    name: "salaryRange",
                    description: "Expected salary",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                DynamicGenerationSchema.Property(
                    name: "remoteWork",
                    description: "Open to remote",
                    schema: .init(type: Bool.self)
                )
            ]
        )
    }

    func describeSchema(_ schema: DynamicGenerationSchema) -> String {
        var description = "Schema Definition:\n"
        description += "Fields:\n"

        // Note: In a real implementation, we would need access to schema internals
        // For now, we just show the basic info
        description += "  [Schema details would be displayed here]\n"

        return description
    }

    func getPattern(from schema: DynamicGenerationSchema) -> String? {
        // This is a simplified version - in real implementation would need to inspect schema internals
        return nil
    }

    func getRange(from schema: DynamicGenerationSchema) -> (Any?, Any?)? {
        // This is a simplified version - in real implementation would need to inspect schema internals
        return nil
    }

    func formatGeneratedContent(_ content: GeneratedContent) -> String {
        var result: [String: Any] = [:]

        switch content.kind {
        case .structure(let properties, let orderedKeys):
            for key in orderedKeys {
                if let value = properties[key] {
                    result[key] = convertToJSONValue(value)
                }
            }
        case .array(let elements):
            let arrayValues = elements.map { convertToJSONValue($0) }
            return formatJSONArray(arrayValues)
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

        do {
            let data = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys])
            return String(data: data, encoding: .utf8) ?? "Unable to format"
        } catch let error {
            return "Error formatting content: \(error.localizedDescription)"
        }
    }

    func convertToJSONValue(_ content: GeneratedContent) -> Any {
        switch content.kind {
        case .structure(let properties, let orderedKeys):
            var result: [String: Any] = [:]
            for key in orderedKeys {
                if let value = properties[key] {
                    result[key] = convertToJSONValue(value)
                }
            }
            return result
        case .array(let elements):
            return elements.map { convertToJSONValue($0) }
        case .string(let str):
            return str
        case .number(let num):
            return num
        case .bool(let bool):
            return bool
        case .null:
            return NSNull()
        @unknown default:
            return "unknown"
        }
    }

    func formatJSONArray(_ array: [Any]) -> String {
        do {
            let data = try JSONSerialization.data(withJSONObject: array, options: [.prettyPrinted])
            return String(data: data, encoding: .utf8) ?? "Unable to format array"
        } catch {
            return "Error formatting array: \(error.localizedDescription)"
        }
    }
}

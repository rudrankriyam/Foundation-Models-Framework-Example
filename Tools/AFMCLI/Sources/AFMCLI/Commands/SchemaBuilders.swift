import ArgumentParser
import FoundationModels

func makeBasicObjectSchema(presetID: String) throws -> GenerationSchema {
    let root: DynamicGenerationSchema
    switch presetID {
    case "person":
        root = DynamicGenerationSchema(
            name: "Person",
            properties: [
                .init(name: "name", schema: .init(type: String.self)),
                .init(name: "age", schema: .init(type: Int.self)),
                .init(name: "occupation", schema: .init(type: String.self))
            ]
        )
    case "product":
        root = DynamicGenerationSchema(
            name: "Product",
            properties: [
                .init(name: "name", schema: .init(type: String.self)),
                .init(name: "price", schema: .init(type: Double.self)),
                .init(name: "feature", schema: .init(type: String.self))
            ]
        )
    default:
        throw ValidationError("Unknown preset '\(presetID)' for basic-object")
    }
    return try GenerationSchema(root: root, dependencies: [])
}

func makeArraySchema(
    presetID: String,
    minimumItems: Int,
    maximumItems: Int
) throws -> GenerationSchema {
    guard minimumItems > 0 else {
        throw ValidationError("--min-items must be greater than 0")
    }
    guard maximumItems >= minimumItems else {
        throw ValidationError("--max-items must be greater than or equal to --min-items")
    }

    let itemName: String = switch presetID {
    case "todo": "TodoItem"
    default: throw ValidationError("Unknown preset '\(presetID)' for array-schema")
    }

    let itemSchema = DynamicGenerationSchema(
        name: itemName,
        properties: [
            .init(name: "title", schema: .init(type: String.self)),
            .init(name: "completed", schema: .init(type: Bool.self), isOptional: true)
        ]
    )
    let root = DynamicGenerationSchema(
        name: "TodoList",
        properties: [
            .init(
                name: "items",
                schema: .init(
                    arrayOf: .init(referenceTo: itemName),
                    minimumElements: minimumItems,
                    maximumElements: maximumItems
                )
            )
        ]
    )
    return try GenerationSchema(root: root, dependencies: [itemSchema])
}

func makeEnumSchema(
    presetID: String,
    customChoices: [String]
) throws -> GenerationSchema {
    let choices = customChoices.isEmpty
        ? AFMSchemaCatalog.defaultChoices(for: presetID)
        : customChoices
    let root = DynamicGenerationSchema(
        name: "Classification",
        properties: [
            .init(name: "label", schema: .init(name: "Label", anyOf: choices)),
            .init(name: "reason", schema: .init(type: String.self), isOptional: true)
        ]
    )
    return try GenerationSchema(root: root, dependencies: [])
}

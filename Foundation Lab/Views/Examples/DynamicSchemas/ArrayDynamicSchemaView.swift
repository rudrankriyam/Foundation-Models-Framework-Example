//
//  ArrayDynamicSchemaView.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import SwiftUI
import FoundationModels

struct ArrayDynamicSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var todoInput = "Today I need to: buy groceries, finish the report, call mom, exercise for 30 minutes, and prepare dinner"
    @State private var ingredientsInput = "For this recipe you'll need eggs, flour, milk, butter, and a pinch of salt"
    @State private var tagsInput = "This article covers machine learning, artificial intelligence, deep learning, neural networks, computer vision, natural language processing, and reinforcement learning"
    @State private var selectedExample = 0
    @State private var minItems = 2
    @State private var maxItems = 5
    
    private let examples = ["Todo List", "Recipe Ingredients", "Article Tags"]
    
    var body: some View {
        ExampleViewBase(
            title: "Array Schemas",
            description: "Create array schemas with minimum and maximum element constraints",
            defaultPrompt: todoInput,
            currentPrompt: .constant(currentInput),
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: { Task { await runExample() } },
            onReset: { selectedExample = 0; minItems = 2; maxItems = 5 }
        ) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Example selector
                Picker("Example", selection: $selectedExample) {
                    ForEach(0..<examples.count, id: \.self) { index in
                        Text(examples[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                
                // Constraints controls
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Array Constraints")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Min Items: \(minItems)")
                                .font(.caption)
                            Stepper("", value: $minItems, in: 0...10)
                                .labelsHidden()
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Max Items: \(maxItems)")
                                .font(.caption)
                            Stepper("", value: $maxItems, in: minItems...20)
                                .labelsHidden()
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Input
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Input Text")
                        .font(.headline)
                    
                    TextEditor(text: bindingForSelectedExample)
                        .font(.body)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Schema info
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Schema Info")
                        .font(.headline)
                    
                    Text(schemaInfo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
                
                HStack {
                    Button("Extract Array") {
                        Task {
                            await runExample()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(executor.isRunning || currentInput.isEmpty)
                    
                    if executor.isRunning {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            }
            .padding()
        }
    }
    
    private var bindingForSelectedExample: Binding<String> {
        switch selectedExample {
        case 0: return $todoInput
        case 1: return $ingredientsInput
        default: return $tagsInput
        }
    }
    
    private var currentInput: String {
        switch selectedExample {
        case 0: return todoInput
        case 1: return ingredientsInput
        default: return tagsInput
        }
    }
    
    private var schemaInfo: String {
        let itemType = selectedExample == 0 ? "TodoItem" : selectedExample == 1 ? "Ingredient" : "Tag"
        return """
        This will extract an array of \(itemType) objects.
        • Minimum items: \(minItems)
        • Maximum items: \(maxItems)
        • The model will respect these constraints when generating the array.
        """
    }
    
    private func runExample() async {
        await executor.execute {
            let schema = try createSchema(for: selectedExample)
            let session = LanguageModelSession()
            
            let prompt = """
            Extract the items from this text. Return between \(minItems) and \(maxItems) items.
            
            Text: \(currentInput)
            """
            
            let response = try await session.respond(
                to: Prompt(prompt),
                schema: schema,
                options: .init(temperature: 0.1)
            )
            
            let items = try response.content.elements()
            
            return """
            📝 Input:
            \(currentInput)
            
            📊 Extracted Items (Count: \(items.count)):
            \(formatItems(items))
            
            ✅ Constraints:
            • Minimum: \(minItems) items
            • Maximum: \(maxItems) items
            • Actual: \(items.count) items
            • Valid: \(items.count >= minItems && items.count <= maxItems ? "Yes ✓" : "No ✗")
            """
        }
    }
    
    private func createSchema(for index: Int) throws -> GenerationSchema {
        switch index {
        case 0:
            // Todo items array
            let todoItemSchema = DynamicGenerationSchema(
                name: "TodoItem",
                description: "A single todo task",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "task",
                        description: "The task description",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "priority",
                        description: "Priority level (high, medium, low)",
                        schema: .init(name: "Priority", anyOf: ["high", "medium", "low"]),
                        isOptional: true
                    )
                ]
            )
            
            let arraySchema = DynamicGenerationSchema(
                arrayOf: todoItemSchema,
                minimumElements: minItems,
                maximumElements: maxItems
            )
            
            return try GenerationSchema(root: arraySchema, dependencies: [todoItemSchema])
            
        case 1:
            // Recipe ingredients array
            let ingredientSchema = DynamicGenerationSchema(
                name: "Ingredient",
                description: "A recipe ingredient",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "name",
                        description: "Ingredient name",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "quantity",
                        description: "Amount needed",
                        schema: .init(type: String.self),
                        isOptional: true
                    )
                ]
            )
            
            let arraySchema = DynamicGenerationSchema(
                arrayOf: ingredientSchema,
                minimumElements: minItems,
                maximumElements: maxItems
            )
            
            return try GenerationSchema(root: arraySchema, dependencies: [ingredientSchema])
            
        default:
            // Simple string array for tags
            let stringSchema = DynamicGenerationSchema(type: String.self)
            let arraySchema = DynamicGenerationSchema(
                arrayOf: stringSchema,
                minimumElements: minItems,
                maximumElements: maxItems
            )
            
            return try GenerationSchema(root: arraySchema, dependencies: [])
        }
    }
    
    private func formatItems(_ items: [GeneratedContent]) -> String {
        var result = ""
        for (index, item) in items.enumerated() {
            result += "\n\(index + 1). "
            
            // Try to format as object with properties
            if let properties = try? item.properties() {
                var parts: [String] = []
                for (key, value) in properties {
                    if let stringValue = try? value.value(String.self) {
                        parts.append("\(key): \(stringValue)")
                    }
                }
                result += parts.joined(separator: ", ")
            } else if let stringValue = try? item.value(String.self) {
                // Format as simple string
                result += stringValue
            } else {
                result += "Unknown item"
            }
        }
        return result
    }
    
    private var exampleCode: String {
        """
        // Creating an array schema with constraints
        let itemSchema = DynamicGenerationSchema(
            name: "TodoItem",
            description: "A single todo task",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "task",
                    description: "The task description",
                    schema: .init(type: String.self)
                )
            ]
        )
        
        // Array with min/max constraints
        let arraySchema = DynamicGenerationSchema(
            arrayOf: itemSchema,
            minimumElements: 2,
            maximumElements: 5
        )
        
        let schema = try GenerationSchema(
            root: arraySchema,
            dependencies: [itemSchema]
        )
        
        // The model will generate between 2 and 5 items
        let response = try await session.respond(
            to: prompt,
            schema: schema
        )
        
        // Edge cases handled:
        // - Empty arrays (if minimum is 0)
        // - Maximum element enforcement
        // - Nested object arrays
        // - Simple string arrays
        """
    }
}

#Preview {
    NavigationStack {
        ArrayDynamicSchemaView()
    }
}
//
//  EnumDynamicSchemaView.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import SwiftUI
import FoundationModels

struct EnumDynamicSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var customerInput = "The customer seems very happy with our service and left a glowing review"
    @State private var taskInput = "This bug fix is urgent and needs to be completed today"
    @State private var weatherInput = "It's a beautiful sunny day with clear skies"
    @State private var selectedExample = 0
    @State private var customChoices = "excellent, good, average, poor"
    @State private var useCustomChoices = false
    
    private let examples = ["Sentiment Analysis", "Task Priority", "Weather Condition"]
    
    var body: some View {
        ExampleViewBase(
            title: "Enum Schemas",
            description: "Create schemas with predefined string choices using anyOf",
            defaultPrompt: customerInput,
            currentPrompt: .constant(currentInput),
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: { Task { await runExample() } },
            onReset: { selectedExample = 0; useCustomChoices = false }
        ) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Example selector
                Picker("Example", selection: $selectedExample) {
                    ForEach(0..<examples.count, id: \.self) { index in
                        Text(examples[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                
                // Current choices display
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Available Choices")
                        .font(.headline)
                    
                    Text(currentChoices.joined(separator: ", "))
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Custom choices option
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Toggle("Use Custom Choices", isOn: $useCustomChoices)
                        .font(.caption)
                    
                    if useCustomChoices {
                        TextField("Comma-separated choices", text: $customChoices)
                            .textFieldStyle(.roundedBorder)
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Input text
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Input Text")
                        .font(.headline)
                    
                    TextEditor(text: bindingForSelectedExample)
                        .font(.body)
                        .frame(minHeight: 60)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                HStack {
                    Button("Classify") {
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
        case 0: return $customerInput
        case 1: return $taskInput
        default: return $weatherInput
        }
    }
    
    private var currentInput: String {
        switch selectedExample {
        case 0: return customerInput
        case 1: return taskInput
        default: return weatherInput
        }
    }
    
    private var currentChoices: [String] {
        if useCustomChoices {
            return customChoices.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        
        switch selectedExample {
        case 0:
            return ["positive", "negative", "neutral", "mixed"]
        case 1:
            return ["urgent", "high", "medium", "low"]
        default:
            return ["sunny", "cloudy", "rainy", "snowy", "foggy", "stormy"]
        }
    }
    
    private func runExample() async {
        await executor.execute {
            let schema = try createSchema(for: selectedExample)
            let session = LanguageModelSession()
            
            let fieldName = selectedExample == 0 ? "sentiment" : selectedExample == 1 ? "priority" : "condition"
            let prompt = """
            Analyze the following text and classify it into one of the available categories.
            
            Text: \(currentInput)
            """
            
            let response = try await session.respond(
                to: Prompt(prompt),
                schema: schema,
                options: .init(temperature: 0.1)
            )
            
            let properties = try response.content.properties()
            let classification = try properties[fieldName]?.value(String.self) ?? "unknown"
            let confidence = try properties["confidence"]?.value(Float.self)
            let reasoning = try properties["reasoning"]?.value(String.self)
            
            return """
            📝 Input:
            \(currentInput)
            
            🏷️ Classification: \(classification)
            
            📊 Available Choices:
            \(currentChoices.map { "• \($0)" }.joined(separator: "\n"))
            
            \(confidence != nil ? "🎯 Confidence: \(String(format: "%.1f%%", (confidence ?? 0) * 100))" : "")
            
            \(reasoning != nil ? "💭 Reasoning: \(reasoning ?? "")" : "")
            
            ✅ Valid Choice: \(currentChoices.contains(classification) ? "Yes" : "No (Invalid!)")
            """
        }
    }
    
    private func createSchema(for index: Int) throws -> GenerationSchema {
        let choices = currentChoices
        let fieldName = index == 0 ? "sentiment" : index == 1 ? "priority" : "condition"
        let description = index == 0 ? "The sentiment of the text" : index == 1 ? "The priority level" : "The weather condition"
        
        // Create enum schema
        let enumSchema = DynamicGenerationSchema(
            name: "\(fieldName.capitalized)Type",
            description: description,
            anyOf: choices
        )
        
        // Create properties for the result
        let classificationProperty = DynamicGenerationSchema.Property(
            name: fieldName,
            description: description,
            schema: enumSchema
        )
        
        let confidenceProperty = DynamicGenerationSchema.Property(
            name: "confidence",
            description: "Confidence score between 0 and 1",
            schema: .init(type: Float.self),
            isOptional: true
        )
        
        let reasoningProperty = DynamicGenerationSchema.Property(
            name: "reasoning",
            description: "Brief explanation for the classification",
            schema: .init(type: String.self),
            isOptional: true
        )
        
        // Create the main schema
        let resultSchema = DynamicGenerationSchema(
            name: "ClassificationResult",
            description: "Classification result with optional confidence and reasoning",
            properties: [classificationProperty, confidenceProperty, reasoningProperty]
        )
        
        return try GenerationSchema(root: resultSchema, dependencies: [enumSchema])
    }
    
    private var exampleCode: String {
        """
        // Creating an enum schema with string choices
        let sentimentSchema = DynamicGenerationSchema(
            name: "Sentiment",
            description: "Sentiment classification",
            anyOf: ["positive", "negative", "neutral", "mixed"]
        )
        
        // Use the enum in a property
        let sentimentProperty = DynamicGenerationSchema.Property(
            name: "sentiment",
            description: "The sentiment of the text",
            schema: sentimentSchema
        )
        
        let resultSchema = DynamicGenerationSchema(
            name: "Result",
            properties: [sentimentProperty]
        )
        
        let schema = try GenerationSchema(
            root: resultSchema,
            dependencies: [sentimentSchema]
        )
        
        // The model will only choose from the provided options
        // Edge cases:
        // - Empty choices array (will throw error)
        // - Duplicate choices (handled gracefully)
        // - Case sensitivity (choices are case-sensitive)
        // - Dynamic choice generation at runtime
        """
    }
}

#Preview {
    NavigationStack {
        EnumDynamicSchemaView()
    }
}
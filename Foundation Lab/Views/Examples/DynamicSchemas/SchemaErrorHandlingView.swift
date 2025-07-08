//
//  SchemaErrorHandlingView.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import SwiftUI
import FoundationModels

struct SchemaErrorHandlingView: View {
    @State private var executor = ExampleExecutor()
    @State private var testInput = "The product costs $49.99 and comes in red, blue, or green colors. It weighs 2.5 kg."
    @State private var selectedScenario = 0
    @State private var showDetailedError = true
    
    private let scenarios = [
        "Basic Extraction",
        // "Missing Required Fields",
        // "Type Mismatch",
        // "Schema Validation Failure"
    ]
    
    var body: some View {
        ExampleViewBase(
            title: "Error Handling",
            description: "Handle schema validation errors and edge cases gracefully",
            defaultPrompt: testInput,
            currentPrompt: $testInput,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: { Task { await runExample() } },
            onReset: { 
                executor.reset()
                selectedScenario = 0
            }
        ) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Scenario selector
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Error Scenario")
                        .font(.headline)
                    
                    Picker("Scenario", selection: $selectedScenario) {
                        ForEach(0..<scenarios.count, id: \.self) { index in
                            Text(scenarios[index]).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Options
                Toggle("Show detailed error information", isOn: $showDetailedError)
                    .padding(.vertical, 8)
                
                // Scenario description
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Label("Scenario Details", systemImage: "exclamationmark.triangle")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text(scenarioDescription)
                        .font(.caption)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Results
                if !executor.results.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Extraction Result")
                            .font(.headline)
                        
                        ScrollView {
                            Text(executor.results)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(executor.errorMessage != nil ? 
                                    Color.red.opacity(0.1) : 
                                    Color.green.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 250)
                    }
                }
            }
            .padding()
        }
    }
    
    private var scenarioDescription: String {
        switch selectedScenario {
        case 0:
            return "Basic extraction with a well-formed schema. This should succeed without errors."
        // case 1:
        //     return "The schema requires fields that might not be present in the input. The system will make best effort to extract available data."
        // case 2:
        //     return "The input contains data that doesn't match the expected types. The system will attempt type conversion where possible."
        // case 3:
        //     return "Complex validation rules that might fail. The system will provide detailed error information."
        default:
            return ""
        }
    }
    
    private func runExample() async {
        let schema = createSchema(for: selectedScenario)
        
        await executor.execute(
            withPrompt: "Extract product information from: \(testInput)",
            schema: schema
        ) { result in
            let status = executor.errorMessage != nil ? "❌ Error Occurred" : "✅ Success"
            
            return """
            \(status)
            
            📋 Schema: \(scenarios[selectedScenario])
            
            📊 Result:
            \(result)
            
            💡 Error Handling Tips:
            - Use optional fields for data that might be missing
            - Provide clear descriptions to guide extraction
            - Natural language descriptions help with type conversion
            """
        }
    }
    
    private func createSchema(for scenario: Int) -> DynamicGenerationSchema {
        switch scenario {
        case 0: // Basic extraction
            return DynamicGenerationSchema(
                name: "Product",
                description: "Product information",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "name",
                        description: "Product name",
                        schema: DynamicGenerationSchema(type: String.self),
                        isOptional: true
                    ),
                    DynamicGenerationSchema.Property(
                        name: "price",
                        description: "Price in dollars",
                        schema: DynamicGenerationSchema(type: Double.self),
                        isOptional: true
                    ),
                    DynamicGenerationSchema.Property(
                        name: "colors",
                        description: "Available colors",
                        schema: DynamicGenerationSchema(
                            arrayOf: DynamicGenerationSchema(type: String.self)
                        ),
                        isOptional: true
                    ),
                    DynamicGenerationSchema.Property(
                        name: "weight",
                        description: "Weight in kilograms",
                        schema: DynamicGenerationSchema(type: Double.self),
                        isOptional: true
                    )
                ]
            )
            
        /* TODO: Implement error scenarios
        case 1: // Missing required fields
            return createStrictSchema()
        case 2: // Type mismatch
            return createTypeMismatchSchema()
        case 3: // Validation failure
            return createValidationSchema()
        */
            
        default:
            return DynamicGenerationSchema(
                name: "Default",
                properties: []
            )
        }
    }
    
    private var exampleCode: String {
        """
        // Error handling strategies
        
        // 1. Make fields optional to handle missing data
        let flexibleSchema = DynamicGenerationSchema(
            name: "Product",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "price",
                    description: "Price if available",
                    schema: DynamicGenerationSchema(type: Double.self),
                    isOptional: true
                )
            ]
        )
        
        // 2. Use clear descriptions for type guidance
        let guidedSchema = DynamicGenerationSchema.Property(
            name: "date",
            description: "Date in format YYYY-MM-DD",
            schema: DynamicGenerationSchema(type: String.self)
        )
        
        // 3. Handle errors gracefully
        do {
            let result = try await session.respond(
                to: Prompt(text),
                schema: schema
            )
        } catch {
            // Log error and try with more lenient schema
            print("Schema validation failed: \\(error)")
        }
        """
    }
}

#Preview {
    NavigationStack {
        SchemaErrorHandlingView()
    }
}
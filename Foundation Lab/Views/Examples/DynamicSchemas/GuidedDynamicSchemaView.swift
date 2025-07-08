//
//  GuidedDynamicSchemaView.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import SwiftUI
import FoundationModels

struct GuidedDynamicSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var selectedGuideType = 0
    @State private var patternInput = "Generate 5 US phone numbers with extensions"
    @State private var rangeInput = "Generate prices between $10 and $100 for electronics"
    @State private var arrayInput = "Create a shopping list with 3-5 items each having 2-4 attributes"
    @State private var validationInput = "Generate valid email addresses for 5 employees at techcorp.com"
    
    private let guideTypes = [
        "Basic Schema",
        // "Number Ranges", 
        // "Array Constraints",
        // "Complex Validation"
    ]
    
    var body: some View {
        ExampleViewBase(
            title: "Generation Guides",
            description: "Apply constraints to generated values using schema properties",
            defaultPrompt: patternInput,
            currentPrompt: .constant(currentInput),
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: { Task { await runExample() } },
            onReset: { executor.reset() }
        ) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Guide Type Selector
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Constraint Type")
                        .font(.headline)
                    
                    Picker("Guide Type", selection: $selectedGuideType) {
                        ForEach(0..<guideTypes.count, id: \.self) { index in
                            Text(guideTypes[index]).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Input field
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Generation Prompt")
                        .font(.headline)
                    
                    TextEditor(text: bindingForSelectedGuide)
                        .font(.body)
                        .frame(minHeight: 60)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Guide explanation
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Label("How it works", systemImage: "info.circle")
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    Text(guideExplanation)
                        .font(.caption)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Results
                if !executor.results.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Generated Data with Constraints")
                            .font(.headline)
                        
                        ScrollView {
                            Text(executor.results)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 250)
                    }
                }
            }
            .padding()
        }
    }
    
    private var currentInput: String {
        switch selectedGuideType {
        case 0: return patternInput
        case 1: return rangeInput
        case 2: return arrayInput
        case 3: return validationInput
        default: return ""
        }
    }
    
    private var bindingForSelectedGuide: Binding<String> {
        switch selectedGuideType {
        case 0: return $patternInput
        case 1: return $rangeInput
        case 2: return $arrayInput
        case 3: return $validationInput
        default: return .constant("")
        }
    }
    
    private var guideExplanation: String {
        switch selectedGuideType {
        case 0: return "Basic schema using natural language descriptions to guide the model"
        case 1: return "Number range constraints limit numeric values to specified minimum and maximum bounds"
        case 2: return "Array constraints control the number of items in arrays using minItems and maxItems properties"
        case 3: return "Complex validation combines multiple constraints like patterns, ranges, and custom validation rules"
        default: return ""
        }
    }
    
    private func runExample() async {
        let schema: DynamicGenerationSchema
        
        switch selectedGuideType {
        case 0: // Basic Schema
            let phoneEntrySchema = DynamicGenerationSchema(
                name: "PhoneEntry",
                description: "Phone directory entry",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "name",
                        description: "Person's name",
                        schema: DynamicGenerationSchema(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "phoneNumber",
                        description: "US phone number format: (XXX) XXX-XXXX",
                        schema: DynamicGenerationSchema(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "extension",
                        description: "Extension format: xXXX",
                        schema: DynamicGenerationSchema(type: String.self),
                        isOptional: true
                    )
                ]
            )
            
            schema = DynamicGenerationSchema(
                name: "PhoneDirectory",
                description: "Phone directory",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "entries",
                        description: "Phone directory entries",
                        schema: DynamicGenerationSchema(arrayOf: phoneEntrySchema)
                    )
                ]
            )
            
        /* TODO: Add these back when API supports them
        case 1: // Number Ranges
            let productSchema = DynamicGenerationSchema(
                name: "Product",
                description: "Product information",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "name",
                        description: "Product name",
                        schema: DynamicGenerationSchema(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "price",
                        description: "Price in USD between $10 and $100",
                        schema: DynamicGenerationSchema(type: Double.self, guides: [.minimum(10.0), .maximum(100.0)])
                    ),
                    DynamicGenerationSchema.Property(
                        name: "stock",
                        description: "Stock quantity (0-500)",
                        schema: DynamicGenerationSchema(type: Int.self, guides: [.minimum(0), .maximum(500)])
                    ),
                    DynamicGenerationSchema.Property(
                        name: "discount",
                        description: "Discount percentage (0-50%)",
                        schema: DynamicGenerationSchema(type: Double.self, guides: [.minimum(0), .maximum(50)]),
                        isOptional: true
                    )
                ]
            )
            
            schema = DynamicGenerationSchema(
                name: "ProductCatalog",
                description: "Product catalog",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "products",
                        description: "Product list",
                        schema: DynamicGenerationSchema(arrayOf: productSchema)
                    )
                ]
            )
        */
            
        default:
            return
        }
        
        await executor.execute(
            withPrompt: currentInput,
            schema: schema,
            formatResults: { output in
                if let data = output.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data),
                   let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
                   let jsonString = String(data: formatted, encoding: .utf8) {
                    
                    // Add validation summary
                    var result = "=== Generated Data ===\n" + jsonString
                    result += "\n\n=== Natural Language Guidance ==="
                    result += "\nThe model uses the descriptions to understand the desired format"
                    
                    return result
                }
                return output
            }
        )
    }
    
    private var exampleCode: String {
        """
        // Using DynamicGenerationSchema with natural language guidance
        
        // 1. Basic schema with descriptive guidance
        let phoneSchema = DynamicGenerationSchema.Property(
            name: "phoneNumber",
            description: "US phone format (XXX) XXX-XXXX",
            schema: DynamicGenerationSchema(type: String.self)
        )
        
        // 2. Array schemas
        let itemsSchema = DynamicGenerationSchema(
            arrayOf: itemSchema,
            minimumElements: 3,
            maximumElements: 5
        )
        
        // 3. Object schemas with properties
        let personSchema = DynamicGenerationSchema(
            name: "Person",
            description: "Person information",
            properties: [nameProperty, ageProperty]
        )
        
        // TODO: Advanced constraints with @Generable types
        // @Generable
        // struct Product {
        //     @Guide(.minimum(10), .maximum(100))
        //     let price: Double
        // }
        """
    }
}

#Preview {
    NavigationStack {
        GuidedDynamicSchemaView()
    }
}
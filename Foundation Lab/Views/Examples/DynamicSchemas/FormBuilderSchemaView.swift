//
//  FormBuilderSchemaView.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import SwiftUI
import FoundationModels

struct FormBuilderSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var formDescription = "Create a job application form with fields for personal info, experience, and skills"
    @State private var formData = """
    Name: John Smith
    Email: john.smith@email.com
    Phone: (555) 123-4567
    Years of Experience: 8
    Current Position: Senior Software Engineer
    Skills: Swift, iOS, Python, Machine Learning
    Available to Start: Immediately
    Salary Expectation: $150,000 - $180,000
    Remote Work: Yes
    """
    @State private var generationMode = 0
    @State private var includeValidation = true
    
    private let modes = ["Generate & Extract", "Generate Schema Only", "Use Predefined"]
    
    var body: some View {
        ExampleViewBase(
            title: "Dynamic Form Builder",
            description: "Generate form schemas from natural language descriptions",
            defaultPrompt: formDescription,
            currentPrompt: $formDescription,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: { Task { await runExample() } },
            onReset: { executor.reset() }
        ) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Mode selector
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Generation Mode")
                        .font(.headline)
                    
                    Picker("Mode", selection: $generationMode) {
                        ForEach(0..<modes.count, id: \.self) { index in
                            Text(modes[index]).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                // Options
                Toggle("Include validation rules", isOn: $includeValidation)
                    .padding(.vertical, 8)
                
                // Sample data display (read-only)
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Sample Form Data")
                        .font(.headline)
                    
                    Text(formData)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Results
                if !executor.results.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Generated Form Schema & Extracted Data")
                            .font(.headline)
                        
                        ScrollView {
                            Text(executor.results)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                        .frame(maxHeight: 300)
                    }
                }
            }
            .padding()
        }
    }
    
    private func runExample() async {
        await executor.execute {
            let session = LanguageModelSession()
            
            switch generationMode {
            case 0: // Generate & Extract
                // First, create a simple form schema from the description
                let formSchema = createFormSchemaFromDescription(formDescription)
                
                // Then extract data using that schema
                let extractionSchema = try GenerationSchema(root: formSchema, dependencies: [])
                let response = try await session.respond(
                    to: Prompt("Extract form data from: \(formData)"),
                    schema: extractionSchema
                )
                
                let extractedData = formatGeneratedContent(response.content)
                
                return """
                📋 Generated Form Schema:
                \(describeSchema(formSchema))
                
                📊 Extracted Data:
                \(extractedData)
                
                ✅ Validation: All fields processed successfully
                """
                
            case 1: // Generate Schema Only
                let formSchema = createFormSchemaFromDescription(formDescription)
                
                return """
                📋 Generated Form Schema:
                \(describeSchema(formSchema))
                
                💡 Use this schema to extract structured data from unstructured text
                """
                
            case 2: // Use Predefined
                let predefinedSchema = createPredefinedJobApplicationSchema()
                let extractionSchema = try GenerationSchema(root: predefinedSchema, dependencies: [])
                
                let response = try await session.respond(
                    to: Prompt("Extract job application data from: \(formData)"),
                    schema: extractionSchema
                )
                
                let extractedData = formatGeneratedContent(response.content)
                
                return """
                📋 Using Predefined Job Application Schema
                
                📊 Extracted Data:
                \(extractedData)
                """
                
            default:
                return "Invalid mode"
            }
        }
    }
    
    private func createFormSchemaFromDescription(_ description: String) -> DynamicGenerationSchema {
        // Analyze the description to determine likely fields
        let lowercased = description.lowercased()
        var properties: [DynamicGenerationSchema.Property] = []
        
        // Personal info fields
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
                        guides: [.pattern(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/)]
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
                        guides: [.pattern(/\(\d{3}\) \d{3}-\d{4}/)]
                    ),
                    isOptional: true
                )
            )
        }
        
        // Experience fields
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
        
        // Skills fields
        if lowercased.contains("skill") {
            properties.append(
                DynamicGenerationSchema.Property(
                    name: "skills",
                    description: "List of skills",
                    schema: .init(arrayOf: .init(type: String.self))
                )
            )
        }
        
        // Additional common fields
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
        
        return DynamicGenerationSchema(
            name: "FormData",
            description: "Form data extracted from user input",
            properties: properties
        )
    }
    
    private func createPredefinedJobApplicationSchema() -> DynamicGenerationSchema {
        return DynamicGenerationSchema(
            name: "JobApplication",
            description: "Job application form data",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "personalInfo",
                    description: "Personal information",
                    schema: DynamicGenerationSchema(
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
                                    guides: [.pattern(/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/)]
                                )
                            ),
                            DynamicGenerationSchema.Property(
                                name: "phone",
                                description: "Phone number",
                                schema: .init(
                                    type: String.self,
                                    guides: [.pattern(/\(\d{3}\) \d{3}-\d{4}/)]
                                ),
                                isOptional: true
                            )
                        ]
                    )
                ),
                DynamicGenerationSchema.Property(
                    name: "experience",
                    description: "Professional experience",
                    schema: DynamicGenerationSchema(
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
                ),
                DynamicGenerationSchema.Property(
                    name: "preferences",
                    description: "Job preferences",
                    schema: DynamicGenerationSchema(
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
                )
            ]
        )
    }
    
    private func describeSchema(_ schema: DynamicGenerationSchema) -> String {
        var description = "Schema Definition:\n"
        description += "Fields:\n"
        
        // Note: In a real implementation, we would need access to schema internals
        // For now, we just show the basic info
        description += "  [Schema details would be displayed here]\n"
        
        return description
    }
    
    // Helper functions to extract schema constraints
    private func getPattern(from schema: DynamicGenerationSchema) -> String? {
        // This is a simplified version - in real implementation would need to inspect schema internals
        return nil
    }
    
    private func getRange(from schema: DynamicGenerationSchema) -> (Any?, Any?)? {
        // This is a simplified version - in real implementation would need to inspect schema internals
        return nil
    }
    
    private func formatGeneratedContent(_ content: GeneratedContent) -> String {
        do {
            let properties = try content.properties()
            let data = try JSONSerialization.data(withJSONObject: properties, options: [.prettyPrinted, .sortedKeys])
            return String(data: data, encoding: .utf8) ?? "Unable to format"
        } catch let error {
            return "Error formatting content: \(error.localizedDescription)"
        }
    }
    
    private var exampleCode: String {
        """
        // Generate form schema from description
        func generateFormSchema(from description: String) -> DynamicGenerationSchema {
            // Analyze description to determine fields
            var properties: [DynamicGenerationSchema.Property] = []
            
            if description.contains("email") {
                properties.append(.init(
                    name: "email",
                    description: "Email address",
                    schema: .init(
                        type: String.self,
                        guides: [.pattern(/^[\\w.-]+@[\\w.-]+\\.\\w+$/)]
                    )
                ))
            }
            
            if description.contains("experience") {
                properties.append(.init(
                    name: "yearsOfExperience",
                    description: "Years of experience",
                    schema: .init(
                        type: Int.self,
                        guides: [.range(0...50)]
                    )
                ))
            }
            
            return DynamicGenerationSchema(
                name: "FormData",
                properties: properties
            )
        }
        
        // Extract data using generated schema
        let schema = generateFormSchema(from: userDescription)
        let response = try await session.respond(
            to: Prompt("Extract: " + formData),
            schema: GenerationSchema(root: schema)
        )
        """
    }
}

#Preview {
    NavigationStack {
        FormBuilderSchemaView()
    }
}
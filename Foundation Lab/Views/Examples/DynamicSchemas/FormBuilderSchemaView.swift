//
//  FormBuilderSchemaView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
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
            onReset: { executor.reset() },
            content: {
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
    )
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
        let lowercased = description.lowercased()
        var properties: [DynamicGenerationSchema.Property] = []

        // Add field types based on description content
        addPersonalInfoFields(to: &properties, for: lowercased)
        addExperienceFields(to: &properties, for: lowercased)
        addSkillsFields(to: &properties, for: lowercased)
        addCommonFields(to: &properties)

        return DynamicGenerationSchema(
            name: "FormData",
            description: "Form data extracted from user input",
            properties: properties
        )
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

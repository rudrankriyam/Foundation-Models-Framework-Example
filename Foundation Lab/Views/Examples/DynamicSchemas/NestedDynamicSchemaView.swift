//
//  NestedDynamicSchemaView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationModels

struct NestedDynamicSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var companyInput = """
    Apple Inc. is headquartered in Cupertino, California. The CEO is Tim Cook who has been leading \
    the company since 2011. Apple has several major departments including Hardware Engineering led by \
    John Ternus, Software Engineering led by Craig Federighi, and Services led by Eddy Cue. \
    The company was founded in 1976 and has over 160,000 employees worldwide.
    """

    @State private var orderInput = """
    Order #12345 was placed on January 15, 2024 by Jane Smith. She ordered 2 iPhone 15 Pro units \
    at $999 each and 1 MacBook Pro 14" for $1999. The items should be shipped to 123 Main St, \
    San Francisco, CA 94105. Payment was made with Visa ending in 4242. Express shipping was selected.
    """

    @State private var eventInput = """
    The AI Conference 2024 will be held at the Moscone Center in San Francisco from March 15-17. \
    The keynote speaker is Dr. Sarah Johnson from Stanford University who will talk about \
    "The Future of Language Models". Other sessions include "Computer Vision Advances" by Prof. Michael Chen \
    and "Ethics in AI" by Dr. Emily Rodriguez. Registration costs $599 for early bird tickets.
    """

    @State private var selectedExample = 0
    @State private var nestingDepth = 2

    private let examples = ["Company Structure", "Order Details", "Event Information"]

    var body: some View {
        ExampleViewBase(
            title: "Nested Objects",
            description: "Create complex nested object structures with multiple levels",
            defaultPrompt: companyInput,
            currentPrompt: bindingForSelectedExample,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: { Task { await runExample() } },
            onReset: { selectedExample = 0 },
            content: {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                // Example selector
                Picker("Example", selection: $selectedExample) {
                    ForEach(0..<examples.count, id: \.self) { index in
                        Text(examples[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)

                // Nesting visualization
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Schema Structure")
                        .font(.headline)

                    Text(schemaVisualization(for: selectedExample))
                        .font(.system(.caption, design: .monospaced))
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                HStack {
                    Button("Extract Nested Data") {
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

                // Results section
                if !executor.results.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Generated Data")
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
        )
    }

    private var bindingForSelectedExample: Binding<String> {
        switch selectedExample {
        case 0: return $companyInput
        case 1: return $orderInput
        default: return $eventInput
        }
    }

    private var currentInput: String {
        switch selectedExample {
        case 0: return companyInput
        case 1: return orderInput
        default: return eventInput
        }
    }

    private func runExample() async {
        await executor.execute {
            let schema = try createSchema(for: selectedExample)
            let session = LanguageModelSession()

            let prompt = """
            Extract the structured information from this text:

            \(currentInput)
            """

            let response = try await session.respond(
                to: Prompt(prompt),
                schema: schema,
                options: .init(temperature: 0.1)
            )

            return """
            📝 Input:
            \(currentInput)

            📊 Extracted Nested Structure:
            \(NestedSchemaFormatter.formatNestedContent(response.content, indent: 0))

            🔍 Nesting Levels Found: \(NestedSchemaFormatter.countNestingLevels(response.content))
            """
        }
    }

    private func createSchema(for index: Int) throws -> GenerationSchema {
        switch index {
        case 0:
            return try createCompanySchema()
        case 1:
            return try createOrderSchema()
        default:
            return try createEventSchema()
        }
    }
}

#Preview {
    NavigationStack {
        NestedDynamicSchemaView()
    }
}

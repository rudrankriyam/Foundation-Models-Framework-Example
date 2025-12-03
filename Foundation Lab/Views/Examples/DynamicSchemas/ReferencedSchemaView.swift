//
//  ReferencedSchemaView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationModels

struct ReferencedSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var blogInput = """
    The blog post "Understanding AI" was written by John Smith on March 15, 2024. \
    It received 3 comments: Alice said "Great article!", Bob commented "Very informative", \
    and Carol wrote "Thanks for sharing". The post has tags: AI, Machine Learning, and Technology.
    """

    @State private var projectInput = """
    The SwiftUI project is managed by Sarah Johnson and has 3 team members: \
    Mike Davis (iOS Developer), Emma Wilson (Designer), and Tom Brown (Backend Engineer). \
    Mike is working on the login feature, Emma is designing the dashboard, and Tom is building the API.
    """

    @State private var libraryInput = """
    The library has 3 books: "1984" by George Orwell (borrowed by John on Jan 10), \
    "To Kill a Mockingbird" by Harper Lee (borrowed by Sarah on Jan 15), and \
    "The Great Gatsby" by F. Scott Fitzgerald (available). John also borrowed "Brave New World" on Jan 20.
    """

    @State private var selectedExample = 0
    @State private var showReferences = true

    private let examples = ["Blog System", "Project Team", "Library Catalog"]

    var body: some View {
        ExampleViewBase(
            title: "Schema References",
            description: "Use schema references to avoid duplication and create reusable components",
            defaultPrompt: blogInput,
            currentPrompt: .constant(currentInput),
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: { Task { await runExample() } },
            onReset: { selectedExample = 0; showReferences = true },
            content: {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                // Example selector
                Picker("Example", selection: $selectedExample) {
                    ForEach(0..<examples.count, id: \.self) { index in
                        Text(examples[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)

                // Reference visualization
                VStack(alignment: .leading, spacing: Spacing.small) {
                    HStack {
                        Text("Schema References")
                            .font(.headline)

                        Spacer()

                        Toggle("Show", isOn: $showReferences)
                            .font(.caption)
                    }

                    if showReferences {
                        Text(referenceVisualization(for: selectedExample))
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }

                // Input text
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Input Text")
                        .font(.headline)

                    TextEditor(text: bindingForSelectedExample)
                        .font(.body)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }

                HStack {
                    Button("Extract with References") {
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
        case 0: return $blogInput
        case 1: return $projectInput
        default: return $libraryInput
        }
    }

    private var currentInput: String {
        switch selectedExample {
        case 0: return blogInput
        case 1: return projectInput
        default: return libraryInput
        }
    }

    private func runExample() async {
        await executor.execute {
            let (schema, referencedSchemas) = try createSchema(for: selectedExample)
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

            📊 Extracted Data:
            \(formatReferencedContent(response.content))

            🔗 Referenced Schemas Used:
            \(referencedSchemas.map { "• \($0)" }.joined(separator: "\n"))

            ✅ Benefits:
            • No schema duplication
            • Consistent data structure
            • Easier maintenance
            • Type safety across references
            """
        }
    }

    private func createSchema(for index: Int) throws -> (GenerationSchema, [String]) {
        switch index {
        case 0:
            return try createBlogSchema()
        case 1:
            return try createProjectSchema()
        default:
            return try createLibrarySchema()
        }
    }
}

#Preview {
    NavigationStack {
        ReferencedSchemaView()
    }
}

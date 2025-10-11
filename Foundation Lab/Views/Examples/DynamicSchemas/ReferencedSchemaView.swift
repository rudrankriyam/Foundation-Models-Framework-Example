//
//  ReferencedSchemaView.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
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
            onReset: { selectedExample = 0; showReferences = true }
        ) {
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
                        Text(referenceVisualization)
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.purple.opacity(0.1))
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

    private var referenceVisualization: String {
        switch selectedExample {
        case 0:
            return """
            📦 Person (reusable schema)
            └── Used by: BlogPost.author, Comment.author

            📦 Comment (reusable schema)
            └── Used by: BlogPost.comments[]

            🏗️ BlogPost (root schema)
            ├── author → Person (reference)
            └── comments → [Comment] (reference)
            """
        case 1:
            return """
            📦 Person (base schema)
            └── Extended by: Developer, Designer

            📦 Task (reusable schema)
            └── Used by: Project.tasks[], Person.assignedTasks[]

            🏗️ Project (root schema)
            ├── manager → Person (reference)
            ├── team → [Person] (reference)
            └── tasks → [Task] (reference)
            """
        default:
            return """
            📦 Person (reusable schema)
            └── Used by: Book.borrowedBy, Loan.borrower

            📦 Book (reusable schema)
            └── Used by: Library.books[], Loan.book

            📦 Loan (combines references)
            ├── book → Book (reference)
            └── borrower → Person (reference)
            """
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
            // Blog system with Person and Comment references
            let personSchema = DynamicGenerationSchema(
                name: "Person",
                description: "A person with a name",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "name",
                        description: "Person's full name",
                        schema: .init(type: String.self)
                    )
                ]
            )

            let commentSchema = DynamicGenerationSchema(
                name: "Comment",
                description: "A comment on a blog post",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "author",
                        description: "Comment author",
                        schema: .init(referenceTo: "Person")  // Reference to Person
                    ),
                    DynamicGenerationSchema.Property(
                        name: "content",
                        description: "Comment text",
                        schema: .init(type: String.self)
                    )
                ]
            )

            let blogPostSchema = DynamicGenerationSchema(
                name: "BlogPost",
                description: "A blog post with author and comments",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "title",
                        description: "Post title",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "author",
                        description: "Post author",
                        schema: .init(referenceTo: "Person")  // Reference to Person
                    ),
                    DynamicGenerationSchema.Property(
                        name: "date",
                        description: "Publication date",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "comments",
                        description: "List of comments",
                        schema: .init(arrayOf: .init(referenceTo: "Comment"))  // Array of Comment references
                    ),
                    DynamicGenerationSchema.Property(
                        name: "tags",
                        description: "Post tags",
                        schema: .init(arrayOf: .init(type: String.self)),
                        isOptional: true
                    )
                ]
            )

            let schema = try GenerationSchema(
                root: blogPostSchema,
                dependencies: [personSchema, commentSchema]
            )

            return (schema, ["Person", "Comment"])

        case 1:
            // Project team with role-specific person schemas
            let personSchema = DynamicGenerationSchema(
                name: "Person",
                description: "Base person schema",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "name",
                        description: "Person's name",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "role",
                        description: "Role in the project",
                        schema: .init(type: String.self),
                        isOptional: true
                    )
                ]
            )

            let taskSchema = DynamicGenerationSchema(
                name: "Task",
                description: "A project task",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "description",
                        description: "Task description",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "assignee",
                        description: "Person assigned to this task",
                        schema: .init(referenceTo: "Person"),  // Reference to Person
                        isOptional: true
                    )
                ]
            )

            let projectSchema = DynamicGenerationSchema(
                name: "Project",
                description: "Project with team and tasks",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "name",
                        description: "Project name",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "manager",
                        description: "Project manager",
                        schema: .init(referenceTo: "Person")  // Reference to Person
                    ),
                    DynamicGenerationSchema.Property(
                        name: "team",
                        description: "Team members",
                        schema: .init(arrayOf: .init(referenceTo: "Person"))  // Array of Person references
                    ),
                    DynamicGenerationSchema.Property(
                        name: "tasks",
                        description: "Project tasks",
                        schema: .init(arrayOf: .init(referenceTo: "Task")),  // Array of Task references
                        isOptional: true
                    )
                ]
            )

            let schema = try GenerationSchema(
                root: projectSchema,
                dependencies: [personSchema, taskSchema]
            )

            return (schema, ["Person", "Task"])

        default:
            // Library system with circular references
            let personSchema = DynamicGenerationSchema(
                name: "Person",
                description: "Library member",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "name",
                        description: "Member name",
                        schema: .init(type: String.self)
                    )
                ]
            )

            let bookSchema = DynamicGenerationSchema(
                name: "Book",
                description: "Library book",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "title",
                        description: "Book title",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "author",
                        description: "Book author",
                        schema: .init(type: String.self)
                    ),
                    DynamicGenerationSchema.Property(
                        name: "borrowedBy",
                        description: "Person who borrowed this book",
                        schema: .init(referenceTo: "Person"),  // Reference to Person
                        isOptional: true
                    ),
                    DynamicGenerationSchema.Property(
                        name: "borrowDate",
                        description: "Date when book was borrowed",
                        schema: .init(type: String.self),
                        isOptional: true
                    )
                ]
            )

            let librarySchema = DynamicGenerationSchema(
                name: "Library",
                description: "Library catalog",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "books",
                        description: "All books in the library",
                        schema: .init(arrayOf: .init(referenceTo: "Book"))  // Array of Book references
                    ),
                    DynamicGenerationSchema.Property(
                        name: "members",
                        description: "Library members",
                        schema: .init(arrayOf: .init(referenceTo: "Person")),  // Array of Person references
                        isOptional: true
                    )
                ]
            )

            let schema = try GenerationSchema(
                root: librarySchema,
                dependencies: [personSchema, bookSchema]
            )

            return (schema, ["Person", "Book"])
        }
    }

    private func formatReferencedContent(_ content: GeneratedContent) -> String {
        var result = ""
        var processedRefs = Set<String>()

        func formatValue(_ value: GeneratedContent, indent: Int = 0) -> String {
            let indentStr = String(repeating: "  ", count: indent)
            var output = ""

            switch value.kind {
            case .structure(let properties, let orderedKeys):
                for key in orderedKeys {
                    if let val = properties[key] {
                        output += "\n\(indentStr)\(key): "

                        switch val.kind {
                        case .structure:
                            // This is a referenced object
                            if !processedRefs.contains(key) {
                                processedRefs.insert(key)
                                output += "(ref)"
                            }
                            output += formatValue(val, indent: indent + 1)
                        case .array(let elements):
                            output += "["
                            for element in elements {
                                output += formatValue(element, indent: indent + 1)
                            }
                            output += "\n\(indentStr)]"
                        case .string(let str):
                            output += "\"\(str)\""
                        case .number(let num):
                            output += String(num)
                        case .bool(let bool):
                            output += String(bool)
                        case .null:
                            output += "null"
                        @unknown default:
                            output += "unknown"
                        }
                    }
                }
            case .string(let str):
                output += "\"\(str)\""
            case .number(let num):
                output += String(num)
            case .bool(let bool):
                output += String(bool)
            case .array(let elements):
                output += "["
                for element in elements {
                    output += formatValue(element, indent: indent + 1)
                }
                output += "\n\(indentStr)]"
            case .null:
                output += "null"
            @unknown default:
                output += "unknown"
            }

            return output
        }

        result = formatValue(content)
        return result.isEmpty ? "No data" : result
    }

    private var exampleCode: String {
        """
        // Creating schemas with references

        // Define a reusable Person schema
        let personSchema = DynamicGenerationSchema(
            name: "Person",
            description: "A person",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "name",
                    schema: .init(type: String.self)
                )
            ]
        )

        // Define a Comment schema that references Person
        let commentSchema = DynamicGenerationSchema(
            name: "Comment",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "author",
                    schema: .init(referenceTo: "Person")  // Reference!
                ),
                DynamicGenerationSchema.Property(
                    name: "content",
                    schema: .init(type: String.self)
                )
            ]
        )

        // Main schema using references
        let blogPostSchema = DynamicGenerationSchema(
            name: "BlogPost",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "author",
                    schema: .init(referenceTo: "Person")
                ),
                DynamicGenerationSchema.Property(
                    name: "comments",
                    schema: .init(arrayOf: .init(referenceTo: "Comment"))
                )
            ]
        )

        // Register all schemas in dependencies
        let schema = try GenerationSchema(
            root: blogPostSchema,
            dependencies: [personSchema, commentSchema]
        )

        // Benefits:
        // - Avoid duplication
        // - Maintain consistency
        // - Enable circular references
        // - Simplify complex schemas
        """
    }
}

#Preview {
    NavigationStack {
        ReferencedSchemaView()
    }
}

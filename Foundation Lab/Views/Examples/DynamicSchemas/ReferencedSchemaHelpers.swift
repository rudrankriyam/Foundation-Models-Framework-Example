//
//  ReferencedSchemaHelpers.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationModels

extension ReferencedSchemaView {
    private func createBlogPersonSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
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
    }

    private func createCommentSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
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
    }

    func createBlogSchema() throws -> (GenerationSchema, [String]) {
        let personSchema = createBlogPersonSchema()
        let commentSchema = createCommentSchema()

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
    }

    private func createProjectPersonSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
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
    }

    private func createTaskSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
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
    }

    func createProjectSchema() throws -> (GenerationSchema, [String]) {
        let personSchema = createProjectPersonSchema()
        let taskSchema = createTaskSchema()

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
    }

    private func createLibraryPersonSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
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
    }

    private func createBookSchema() -> DynamicGenerationSchema {
        DynamicGenerationSchema(
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
    }

    func createLibrarySchema() throws -> (GenerationSchema, [String]) {
        let personSchema = createLibraryPersonSchema()
        let bookSchema = createBookSchema()

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

    func referenceVisualization(for index: Int) -> String {
        switch index {
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

    func formatReferencedContent(_ content: GeneratedContent) -> String {
        var result = ""
        var processedRefs = Set<String>()

        result = formatValue(content, indent: 0, processedRefs: &processedRefs)
        return result.isEmpty ? "No data" : result
    }

    private func formatPrimitiveValue(_ value: GeneratedContent) -> String {
        switch value.kind {
        case .string(let str):
            return "\"\(str)\""
        case .number(let num):
            return String(num)
        case .bool(let bool):
            return String(bool)
        case .null:
            return "null"
        @unknown default:
            return "unknown"
        }
    }

    private func formatArrayValue(
        _ elements: [GeneratedContent],
        indent: Int,
        processedRefs: inout Set<String>
    ) -> String {
        let indentStr = String(repeating: "  ", count: indent)
        var output = "["
        for element in elements {
            output += formatValue(element, indent: indent + 1, processedRefs: &processedRefs)
        }
        output += "\n\(indentStr)]"
        return output
    }

    private func formatStructureProperty(
        _ val: GeneratedContent,
        key: String,
        indent: Int,
        processedRefs: inout Set<String>
    ) -> String {
        let indentStr = String(repeating: "  ", count: indent)
        var output = "\n\(indentStr)\(key): "

        switch val.kind {
        case .structure:
            // This is a referenced object
            if !processedRefs.contains(key) {
                processedRefs.insert(key)
                output += "(ref)"
            }
            output += formatValue(val, indent: indent + 1, processedRefs: &processedRefs)
        case .array(let elements):
            output += formatArrayValue(elements, indent: indent, processedRefs: &processedRefs)
        default:
            output += formatPrimitiveValue(val)
        }

        return output
    }

    func formatValue(_ value: GeneratedContent, indent: Int, processedRefs: inout Set<String>) -> String {
        var output = ""

        switch value.kind {
        case .structure(let properties, let orderedKeys):
            for key in orderedKeys {
                if let val = properties[key] {
                    output += formatStructureProperty(val, key: key, indent: indent, processedRefs: &processedRefs)
                }
            }
        case .array(let elements):
            output += formatArrayValue(elements, indent: indent, processedRefs: &processedRefs)
        default:
            output += formatPrimitiveValue(value)
        }

        return output
    }

    var exampleCode: String {
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

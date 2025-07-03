//
//  OptionalFieldsSchemaView.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import SwiftUI
import FoundationModels

struct OptionalFieldsSchemaView: View {
    @StateObject private var executor = ExampleExecutor()
    
    var body: some View {
        ExampleViewBase(
            title: "Optional vs Required Fields",
            description: "Learn how to handle optional and required fields in dynamic schemas",
            code: exampleCode,
            executor: executor
        ) {
            VStack(spacing: Spacing.medium) {
                Text("Example showing optional vs required fields")
                    .font(.headline)
                    .padding()
                
                Text("This example demonstrates:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• Required fields that must be present")
                    Text("• Optional fields that may be omitted")
                    Text("• Handling missing data gracefully")
                    Text("• Validation of required fields")
                }
                .font(.caption)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
        }
    }
    
    private var exampleCode: String {
        """
        // Creating schemas with optional fields
        let schema = DynamicGenerationSchema(
            name: "User",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "name",
                    schema: .init(type: String.self),
                    isOptional: false  // Required
                ),
                DynamicGenerationSchema.Property(
                    name: "email",
                    schema: .init(type: String.self),
                    isOptional: true   // Optional
                )
            ]
        )
        """
    }
}

#Preview {
    NavigationStack {
        OptionalFieldsSchemaView()
    }
}
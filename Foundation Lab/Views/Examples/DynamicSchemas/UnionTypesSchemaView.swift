//
//  UnionTypesSchemaView.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import SwiftUI
import FoundationModels

struct UnionTypesSchemaView: View {
    @StateObject private var executor = ExampleExecutor()
    
    var body: some View {
        ExampleViewBase(
            title: "Union Types (anyOf)",
            description: "Create schemas that can be one of several different types",
            code: exampleCode,
            executor: executor
        ) {
            VStack(spacing: Spacing.medium) {
                Text("Union Types Example")
                    .font(.headline)
                    .padding()
                
                Text("This example shows:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• anyOf with different object types")
                    Text("• Polymorphic data structures")
                    Text("• Type discrimination")
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
        // Creating union types with anyOf
        let personSchema = DynamicGenerationSchema(
            name: "Person",
            properties: [...]
        )
        
        let companySchema = DynamicGenerationSchema(
            name: "Company",
            properties: [...]
        )
        
        let contactSchema = DynamicGenerationSchema(
            name: "Contact",
            anyOf: [personSchema, companySchema]
        )
        """
    }
}

#Preview {
    NavigationStack {
        UnionTypesSchemaView()
    }
}
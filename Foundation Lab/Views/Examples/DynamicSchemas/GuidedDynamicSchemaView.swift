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
    
    var body: some View {
        ExampleViewBase(
            title: "Generation Guides",
            description: "Apply constraints to generated values using generation guides",
            defaultPrompt: "",
            currentPrompt: .constant(""),
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: {},
            onReset: {}
        ) {
            VStack(spacing: Spacing.medium) {
                Text("Generation Guides Example")
                    .font(.headline)
                    .padding()
                
                Text("Available guides:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("• String patterns with regex")
                    Text("• Number ranges and constraints")
                    Text("• Array length limits")
                    Text("• Constant values")
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
        // Using generation guides with dynamic schemas
        let schema = DynamicGenerationSchema(
            type: String.self,
            guides: [
                .pattern(/[A-Z]{2}-\\d{4}/)
            ]
        )
        """
    }
}

#Preview {
    NavigationStack {
        GuidedDynamicSchemaView()
    }
}
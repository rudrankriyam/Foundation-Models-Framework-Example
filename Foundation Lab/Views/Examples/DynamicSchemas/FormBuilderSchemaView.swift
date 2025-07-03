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
    
    var body: some View {
        ExampleViewBase(
            title: "Dynamic Form Builder",
            description: "Build forms dynamically from user input",
            defaultPrompt: "",
            currentPrompt: .constant(""),
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: {},
            onReset: {}
        ) {
            VStack(spacing: Spacing.medium) {
                Text("Dynamic Form Builder")
                    .font(.headline)
                    .padding()
                
                Text("Create custom forms at runtime")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    private var exampleCode: String {
        """
        // Dynamic form building example
        """
    }
}

#Preview {
    NavigationStack {
        FormBuilderSchemaView()
    }
}
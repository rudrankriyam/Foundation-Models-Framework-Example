//
//  SchemaErrorHandlingView.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import SwiftUI
import FoundationModels

struct SchemaErrorHandlingView: View {
    @StateObject private var executor = ExampleExecutor()
    
    var body: some View {
        ExampleViewBase(
            title: "Error Handling",
            description: "Handle schema errors gracefully",
            code: exampleCode,
            executor: executor
        ) {
            VStack(spacing: Spacing.medium) {
                Text("Error Handling Examples")
                    .font(.headline)
                    .padding()
                
                Text("Common schema errors and solutions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    private var exampleCode: String {
        """
        // Error handling example
        """
    }
}

#Preview {
    NavigationStack {
        SchemaErrorHandlingView()
    }
}
//
//  InvoiceProcessingSchemaView.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import SwiftUI
import FoundationModels

struct InvoiceProcessingSchemaView: View {
    @State private var executor = ExampleExecutor()
    
    var body: some View {
        ExampleViewBase(
            title: "Invoice Processing",
            description: "Real-world invoice data extraction",
            defaultPrompt: "",
            currentPrompt: .constant(""),
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: {},
            onReset: {}
        ) {
            VStack(spacing: Spacing.medium) {
                Text("Invoice Processing")
                    .font(.headline)
                    .padding()
                
                Text("Extract structured data from invoices")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    private var exampleCode: String {
        """
        // Invoice processing example
        """
    }
}

#Preview {
    NavigationStack {
        InvoiceProcessingSchemaView()
    }
}
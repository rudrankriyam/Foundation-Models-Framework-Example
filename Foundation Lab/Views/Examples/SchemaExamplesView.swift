//
//  SchemaExamplesView.swift
//  FoundationLab
//
//  Created by Assistant on 7/8/25.
//

import SwiftUI

struct SchemaExamplesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Description
                Text("Learn how to use DynamicGenerationSchema for structured data extraction")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
                
                // Dynamic Schemas Grid
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Dynamic Schemas")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Create flexible schemas at runtime")
                        .font(.callout)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(minimum: 150), spacing: 16),
                        GridItem(.flexible(minimum: 150), spacing: 16)
                    ], spacing: 16) {
                        ForEach(DynamicSchemaExampleType.allCases, id: \.self) { example in
                            NavigationLink(destination: destinationView(for: example)) {
                                VStack(alignment: .leading, spacing: Spacing.small) {
                                    HStack {
                                        Image(systemName: example.icon)
                                            .font(.title2)
                                            .foregroundColor(.main)
                                        Spacer()
                                        
                                        Text(example.complexity.label)
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(example.complexity.color)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(example.complexity.color.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                    
                                    Text(example.title)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.leading)
                                    
                                    Text(example.subtitle)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top)
                }
            }
            .padding()
        }
        .navigationTitle("Schema Examples")
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
    
    @ViewBuilder
    private func destinationView(for example: DynamicSchemaExampleType) -> some View {
        switch example {
        case .basicObject:
            BasicDynamicSchemaView()
        case .arraySchema:
            ArrayDynamicSchemaView()
        case .enumSchema:
            EnumDynamicSchemaView()
        case .nestedObjects:
            NestedDynamicSchemaView()
        case .schemaReferences:
            ReferencedSchemaView()
        case .optionalFields:
            OptionalFieldsSchemaView()
        case .generationGuides:
            GuidedDynamicSchemaView()
        case .unionTypes:
            UnionTypesSchemaView()
        case .formBuilder:
            FormBuilderSchemaView()
        case .errorHandling:
            SchemaErrorHandlingView()
        case .invoiceProcessing:
            InvoiceProcessingSchemaView()
        }
    }
}

#Preview {
    NavigationStack {
        SchemaExamplesView()
    }
}
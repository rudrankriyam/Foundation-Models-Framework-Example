//
//  SchemaExamplesView.swift
//  FoundationLab
//
//  Created by Assistant on 7/8/25.
//

import SwiftUI

struct SchemaExamplesView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: [
                GridItem(.flexible(minimum: 150), spacing: 16),
                GridItem(.flexible(minimum: 150), spacing: 16)
            ], spacing: 16) {
                ForEach(DynamicSchemaExampleType.allCases, id: \.self) { example in
                    NavigationLink(destination: destinationView(for: example)) {
                        GenericCardView(
                            icon: example.icon,
                            title: example.title,
                            subtitle: example.subtitle
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top)
        }
        .padding(.horizontal)
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

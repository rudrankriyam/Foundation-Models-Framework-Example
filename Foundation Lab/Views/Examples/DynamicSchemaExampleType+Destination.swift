//
//  DynamicSchemaExampleType+Destination.swift
//  FoundationLab
//
//  Created by Codex on 4/26/26.
//

import SwiftUI

extension DynamicSchemaExampleType {
    @MainActor
    @ViewBuilder
    var destination: some View {
        switch self {
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
        case .generationGuides:
            GuidedDynamicSchemaView()
        case .generablePattern:
            GenerablePatternView()
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

//
//  IntegrationsView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationModels

enum IntegrationSection: String, CaseIterable {
    case tools
    case schemas
    case languages

    var name: String {
        rawValue.capitalized
    }
}

struct IntegrationsView: View {
    @State private var selectedSection: IntegrationSection = .tools

    var body: some View {
        VStack(spacing: 0) {
            // Segmented picker at the top
            segmentedPicker

            // Content based on selection
            switch selectedSection {
            case .tools:
                ToolsView()
            case .schemas:
                SchemaExamplesView()
            case .languages:
                LanguagesIntegrationsView()
            }
        }
        .navigationTitle("Integrations")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .navigationDestination(for: ToolExample.self) { tool in
            tool.createView()
        }
        .navigationDestination(for: DynamicSchemaExampleType.self) { example in
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
        .navigationDestination(for: LanguageExample.self) { languageExample in
            languageExample.createView()
        }
    }

    private var segmentedPicker: some View {
        Picker("", selection: $selectedSection) {
            ForEach(IntegrationSection.allCases, id: \.self) { section in
                Text(section.name)
                    .tag(section)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top, Spacing.small)
        .padding(.bottom, Spacing.medium)
    }
}

#Preview {
    IntegrationsView()
}

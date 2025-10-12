//
//  IntegrationsView.swift
//  FoundationLab
//
//  Created by Assistant on 12/30/25.
//

import SwiftUI
import FoundationModels

enum IntegrationSection: String, CaseIterable {
    case tools = "Tools"
    case schemas = "Schemas"

    var displayName: String {
        return rawValue
    }
}

struct IntegrationsView: View {
    @State private var selectedSection: IntegrationSection = .tools

    var body: some View {
        VStack(spacing: 0) {
            // Segmented picker at the top
            segmentedPicker

            // Content based on selection
            TabView(selection: $selectedSection) {
                // Tools Section - reuse existing ToolsView
                ToolsView()
                    .tag(IntegrationSection.tools)

                // Schemas Section - reuse existing SchemaExamplesView
                SchemaExamplesView()
                    .tag(IntegrationSection.schemas)
            }
#if os(iOS)
            .tabViewStyle(.page(indexDisplayMode: .never))
#endif
            .animation(.easeInOut(duration: 0.3), value: selectedSection)
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
            case .optionalFields:
#if compiler(>=6.2.1)
                if #available(iOS 26.1, macOS 26.1, *) {
                    OptionalFieldsSchemaView()
                } else {
                    Text("Optional fields example requires iOS/macOS 26.1")
                }
                    #else
                    Text("Optional fields example requires iOS/macOS 26.1")
                    #endif
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

    private var segmentedPicker: some View {
        Picker("Integration Section", selection: $selectedSection) {
            ForEach(IntegrationSection.allCases, id: \.self) { section in
                Text(section.displayName)
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

//
//  SchemaExamplesView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
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
                    NavigationLink(value: example) {
                        GenericCardView(
                            icon: example.icon,
                            title: example.title,
                            subtitle: example.subtitle
                        )
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top)
        }
        .padding(.horizontal, Spacing.medium)
        .navigationTitle("Dynamic Schemas")
#if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.large)
#endif
    }
}

#Preview {
    NavigationStack {
        SchemaExamplesView()
    }
}

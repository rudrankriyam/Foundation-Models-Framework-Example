//
//  ToolsExamplesView.swift
//  FoundationLab
//
//  Created by Assistant on 7/8/25.
//

import SwiftUI

struct ToolsExamplesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Header
                VStack(alignment: .leading, spacing: Spacing.small) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                    
                    Text("Tools Examples")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Learn how to use AI tools for system integration")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom)
                
                // Tools Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(minimum: 150), spacing: 16),
                    GridItem(.flexible(minimum: 150), spacing: 16)
                ], spacing: 16) {
                    ForEach(ToolExample.allCases, id: \.self) { tool in
                        NavigationLink(destination: tool.createView()) {
                            VStack(alignment: .leading, spacing: Spacing.small) {
                                HStack {
                                    Image(systemName: tool.icon)
                                        .font(.title2)
                                        .foregroundColor(.orange)
                                    Spacer()
                                }
                                
                                Text(tool.displayName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(tool.shortDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Tools Examples")
        #if os(iOS) || os(visionOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
}

#Preview {
    NavigationStack {
        ToolsExamplesView()
    }
}

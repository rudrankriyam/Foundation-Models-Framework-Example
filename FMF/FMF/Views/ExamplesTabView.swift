//
//  ExamplesTabView.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/15/25.
//

import SwiftUI
import FoundationModels

struct ExamplesTabView: View {
  @Binding var viewModel: ContentViewModel
  
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          headerView
          exampleButtonsView
          responseView
          loadingView
        }
        .padding(.vertical)
      }
    }
  }
  
  // MARK: - View Components

  private var headerView: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Foundation Models")
        .font(.largeTitle)
        .fontWeight(.bold)
      Text("On-device AI Examples")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal)
  }

  private var exampleButtonsView: some View {
    LazyVGrid(columns: adaptiveGridColumns, spacing: gridSpacing) {
      ForEach(ExampleType.allCases) { exampleType in
        ExampleButton(
          title: exampleType.title,
          subtitle: exampleType.subtitle,
          icon: exampleType.icon
        ) {
          await exampleType.execute(with: viewModel)
        }
      }
    }
    .padding(.horizontal)
  }
  
  private var adaptiveGridColumns: [GridItem] {
    #if os(iOS)
    // iPhone: 2 columns with flexible sizing and better spacing
    return [
      GridItem(.flexible(minimum: 140), spacing: 12),
      GridItem(.flexible(minimum: 140), spacing: 12)
    ]
    #elseif os(macOS)
    // Mac: Adaptive columns based on available width
    return Array(repeating: GridItem(.adaptive(minimum: 280), spacing: 12), count: 1)
    #else
    // Default fallback for other platforms
    return [
      GridItem(.flexible(minimum: 140), spacing: 12),
      GridItem(.flexible(minimum: 140), spacing: 12)
    ]
    #endif
  }
  
  private var gridSpacing: CGFloat {
    #if os(iOS)
    16
    #else
    12
    #endif
  }

  @ViewBuilder
  private var responseView: some View {
    if let requestResponse = viewModel.requestResponse {
      ResponseDisplayView(
        requestResponse: requestResponse,
        onClear: viewModel.clearResults
      )
    }
  }

  @ViewBuilder
  private var loadingView: some View {
    if viewModel.isLoading {
      HStack {
        ProgressView()
          .scaleEffect(0.8)
        Text("Generating response...")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal)
    }
  }
}

#Preview {
  ExamplesTabView(viewModel: .constant(ContentViewModel()))
}
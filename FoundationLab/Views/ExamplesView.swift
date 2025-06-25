//
//  ExamplesView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/15/25.
//

import SwiftUI
import FoundationModels

struct ExamplesView: View {
  @Binding var viewModel: ContentViewModel
  @Namespace private var glassNamespace

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
#if os(iOS)
        headerView
#endif
        exampleButtonsView
        responseView
        loadingView
      }
      .padding(.vertical)
    }
    .navigationDestination(for: ExampleType.self) { exampleType in
        GenerationOptionsView()
    }
  }

  // MARK: - View Components

  private var headerView: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Foundation Models")
        .font(.largeTitle)
        .fontWeight(.bold)
    }
    .padding(.horizontal)
  }

  private var exampleButtonsView: some View {
    VStack(spacing: gridSpacing) {
      LazyVGrid(columns: adaptiveGridColumns, spacing: gridSpacing) {
        ForEach(ExampleType.allCases) { exampleType in
          if exampleType == .generationOptions {
            NavigationLink(value: exampleType) {
                ExampleCardView(type: exampleType)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(true), in: .rect(cornerRadius: 12))
            .glassEffectID(exampleType.id, in: glassNamespace)
          } else {
            ExampleButton(exampleType: exampleType) {
              await exampleType.execute(with: viewModel)
            }
            .glassEffect(.regular.interactive(true), in: .rect(cornerRadius: 12))
            .glassEffectID(exampleType.id, in: glassNamespace)
          }
        }
      }
      .padding(.horizontal)
    }
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
      .glassEffect(.regular, in: .capsule)
    }
  }
}

#Preview {
  ExamplesView(viewModel: .constant(ContentViewModel()))
}

//
//  ToolsView.swift
//  FoundationLab
//
//  Created by Claude on 6/18/25.
//

import FoundationModels
import SwiftUI

#if os(macOS)
  import AppKit
#endif

struct ToolsView: View {
  @State private var isRunning = false
  @State private var result: String = ""
  @State private var errorMessage: String?
  @State private var selectedTool: ToolExample?
  @Namespace private var glassNamespace

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        toolButtonsView
      }
      .padding(.vertical)
    }
    .navigationTitle("Tools")
    .navigationDestination(for: ToolExample.self) { tool in
      tool.createView()
        .withToolExecutor()
    }
  }

  private var toolButtonsView: some View {
    #if os(iOS) || os(macOS)
      GlassEffectContainer(spacing: gridSpacing) {
        LazyVGrid(columns: adaptiveGridColumns, spacing: gridSpacing) {
          ForEach(ToolExample.allCases, id: \.self) { tool in
            NavigationLink(value: tool) {
              ToolButton(
                tool: tool,
                isSelected: false,
                isRunning: false,
                namespace: glassNamespace
              )
            }
            .buttonStyle(PlainButtonStyle())
          }
        }
      }
      .padding(.horizontal)
    #else
      LazyVGrid(columns: adaptiveGridColumns, spacing: gridSpacing) {
        ForEach(ToolExample.allCases, id: \.self) { tool in
          NavigationLink(value: tool) {
            ToolButton(
              tool: tool,
              isSelected: false,
              isRunning: false,
              namespace: glassNamespace
            )
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
      .padding(.horizontal)
    #endif
  }

  private var adaptiveGridColumns: [GridItem] {
    #if os(iOS)
      // iPhone: 2 columns with flexible sizing
      return [
        GridItem(.flexible(minimum: 140), spacing: 12),
        GridItem(.flexible(minimum: 140), spacing: 12),
      ]
    #elseif os(macOS)
      // Mac: Adaptive columns based on available width
      return Array(repeating: GridItem(.adaptive(minimum: 280), spacing: 12), count: 1)
    #else
      // Default fallback
      return [
        GridItem(.flexible(minimum: 140), spacing: 12),
        GridItem(.flexible(minimum: 140), spacing: 12),
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
  private var resultView: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Result")
          .font(.headline)
        Spacer()
        Button("Clear") {
          result = ""
          errorMessage = nil
          selectedTool = nil
        }
        .font(.caption)
      }

      if let error = errorMessage {
        Text("Error: \(error)")
          .foregroundColor(.red)
          .font(.caption)
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.red.opacity(0.1))
          .cornerRadius(8)
      }

      if !result.isEmpty {
        ScrollView {
          Text(result)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondaryBackgroundColor)
            .cornerRadius(8)
        }
        .frame(maxHeight: 300)
      }
    }
    .padding(.horizontal)
  }
}

// MARK: - Tool Button Component

struct ToolButton: View {
  let tool: ToolExample
  let isSelected: Bool
  let isRunning: Bool
  let namespace: Namespace.ID

  var body: some View {
    VStack(spacing: 12) {
      ZStack {
        Image(systemName: tool.icon)
          .font(.system(size: 28))
          .foregroundColor(isSelected ? .white : .accentColor)
          .opacity(isRunning ? 0 : 1)

        if isRunning {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(0.8)
        }
      }
      .frame(width: 50, height: 50)

      VStack(spacing: 4) {
        Text(tool.displayName)
          .font(.headline)
          .foregroundColor(isSelected ? .white : .primary)
          .multilineTextAlignment(.center)

        Text(tool.shortDescription)
          .font(.caption)
          .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
          .multilineTextAlignment(.center)
          .lineLimit(2)
      }
    }
    .padding()
    .frame(maxWidth: .infinity, minHeight: 140)
    #if os(iOS) || os(macOS)
      .glassEffect(
        isSelected ? .regular.tint(.accentColor).interactive(true) : .regular.interactive(true),
        in: .rect(cornerRadius: 12)
      )
      .glassEffectID("tool-\(tool.rawValue)", in: namespace)
    #endif
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    .animation(.spring(response: 0.3, dampingFraction: 0.9), value: isRunning)
  }
}

#Preview {
  ToolsView()
}

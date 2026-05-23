//
//  ToolsView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import SwiftUI

#if os(macOS)
  import AppKit
#endif

struct ToolsView: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        toolButtonsView
      }
      .padding(.vertical)
    }
    .navigationTitle("Tools")
    .navigationDestination(for: ToolExample.self) { tool in
      tool.destination
    }
  }

  private var toolButtonsView: some View {
    LazyVGrid(columns: adaptiveGridColumns, spacing: gridSpacing) {
      ForEach(ToolExample.allCases, id: \.self) { tool in
        NavigationLink(value: tool) {
          ToolButton(
            tool: tool,
            isSelected: false,
            isRunning: false
          )
        }
        .buttonStyle(PlainButtonStyle())
      }
    }
    .padding(.horizontal)
  }

  private var adaptiveGridColumns: [GridItem] {
    #if os(iOS)
      // iPhone: 2 columns with flexible sizing
      return [
        GridItem(.flexible(minimum: 140), spacing: 12),
        GridItem(.flexible(minimum: 140), spacing: 12)
      ]
    #elseif os(macOS)
      // Mac: Adaptive columns based on available width
      return Array(repeating: GridItem(.adaptive(minimum: 280), spacing: 12), count: 1)
    #else
      // Default fallback
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

  // Removed unused resultView and related state
}

// MARK: - Tool Button Component

struct ToolButton: View {
  let tool: ToolExample
  let isSelected: Bool
  let isRunning: Bool

  var body: some View {
    VStack(spacing: 12) {
      ZStack {
        Image(systemName: tool.icon)
          .font(.title)
          .foregroundStyle(isSelected ? .white : .main)
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
    .contentShape(.rect)
    .background(isSelected ? Color.main : Color.tertiaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.large))
    .overlay {
      RoundedRectangle(cornerRadius: CornerRadius.large)
        .stroke(isSelected ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
    }
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isSelected)
    .animation(.spring(response: 0.3, dampingFraction: 0.9), value: isRunning)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(tool.displayName). \(tool.shortDescription)")
    .accessibilityAddTraits(.isButton)
  }
}

#Preview {
  ToolsView()
}

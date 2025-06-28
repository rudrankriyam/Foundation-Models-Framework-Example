//
//  ToolViewBase.swift
//  FoundationLab
//
//  Created by Claude on 1/14/25.
//

import SwiftUI

/// Base component for tool views providing consistent UI elements
struct ToolViewBase<Content: View>: View {
  let title: String
  let icon: String
  let description: String
  let isRunning: Bool
  let errorMessage: String?
  let content: Content

  init(
    title: String,
    icon: String,
    description: String,
    isRunning: Bool = false,
    errorMessage: String? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.icon = icon
    self.description = description
    self.isRunning = isRunning
    self.errorMessage = errorMessage
    self.content = content()
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        headerView
        content
      }
      .padding()
    }
    .navigationTitle(title)
  }

  private var headerView: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: icon)
          .font(.system(size: 32))
          .foregroundColor(.accentColor)

        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.title2)
            .fontWeight(.semibold)

          Text(description)
            .font(.subheadline)
            .foregroundColor(.secondary)
        }

        Spacer()

        if isRunning {
          ProgressView()
            .scaleEffect(0.8)
        }
      }

      if let error = errorMessage {
        ErrorBanner(message: error)
      }
    }
  }
}

/// Error banner component
struct ErrorBanner: View {
  let message: String

  var body: some View {
    HStack {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundColor(.red)

      Text(message)
        .font(.caption)
        .foregroundColor(.red)

      Spacer()
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(Color.red.opacity(0.1))
    .cornerRadius(8)
  }
}

/// Success banner component
struct SuccessBanner: View {
  let message: String

  var body: some View {
    HStack {
      Image(systemName: "checkmark.circle.fill")
        .foregroundColor(.green)

      Text(message)
        .font(.caption)
        .foregroundColor(.green)

      Spacer()
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(Color.green.opacity(0.1))
    .cornerRadius(8)
  }
}

/// Result display component
struct ResultDisplay: View {
    let result: String
    let isSuccess: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Result")
                    .font(.headline)

                Spacer()

                Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(isSuccess ? .green : .red)
            }

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
}

extension Color {
    static var secondaryBackgroundColor: Color {
#if os(iOS)
        Color(UIColor.secondarySystemBackground)
#elseif os(macOS)
        Color(NSColor.controlBackgroundColor)
#else
        Color.gray.opacity(0.1)
#endif
    }
}

#Preview {
  NavigationStack {
    ToolViewBase(
      title: "Sample Tool",
      icon: "gear",
      description: "This is a sample tool for demonstration",
      isRunning: false,
      errorMessage: nil
    ) {
      VStack {
        Text("Sample content")
        Button("Test Button") {}
      }
    }
  }
}

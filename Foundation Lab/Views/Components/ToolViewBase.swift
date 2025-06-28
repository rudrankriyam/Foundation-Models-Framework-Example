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
    #if os(iOS)
      .scrollDismissesKeyboard(.interactively)
    #endif
    .navigationTitle(title)
    .onTapGesture {
      // Dismiss keyboard when tapping outside text fields
      #if os(iOS)
        UIApplication.shared.sendAction(
          #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
      #endif
    }
  }

  private var headerView: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: icon)
          .font(.system(size: 32))
          .foregroundColor(.accentColor)
          .accessibilityLabel("\(title) tool")

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
            .accessibilityLabel("Processing request")
        }
      }

      if let error = errorMessage {
        ErrorBanner(message: error)
      }
    }
  }
}

/// Banner type enumeration for better type safety
enum BannerType {
  case error
  case success
  case warning
  case info

  var iconName: String {
    switch self {
    case .error: return "exclamationmark.triangle.fill"
    case .success: return "checkmark.circle.fill"
    case .warning: return "exclamationmark.triangle"
    case .info: return "info.circle.fill"
    }
  }

  var color: Color {
    switch self {
    case .error: return .red
    case .success: return .green
    case .warning: return .orange
    case .info: return .blue
    }
  }

  var accessibilityLabel: String {
    switch self {
    case .error: return "Error"
    case .success: return "Success"
    case .warning: return "Warning"
    case .info: return "Information"
    }
  }
}

/// Reusable banner component with customizable parameters
struct BannerView: View {
  let message: String
  let type: BannerType

  // Custom initializer for backwards compatibility
  init(message: String, iconName: String, color: Color) {
    self.message = message
    // Determine type based on icon name for backwards compatibility
    if iconName.contains("exclamation") && iconName.contains("triangle.fill") {
      self.type = .error
    } else if iconName.contains("checkmark") {
      self.type = .success
    } else if iconName.contains("exclamation") && iconName.contains("triangle") {
      self.type = .warning
    } else {
      self.type = .info
    }
  }

  // Preferred initializer using enum
  init(message: String, type: BannerType) {
    self.message = message
    self.type = type
  }

  var body: some View {
    HStack {
      Image(systemName: type.iconName)
        .foregroundColor(type.color)
        .accessibilityLabel(type.accessibilityLabel)

      Text(message)
        .font(.caption)
        .foregroundColor(type.color)

      Spacer()
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(type.color.opacity(0.1))
    .cornerRadius(8)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("\(type.accessibilityLabel): \(message)")
  }
}

/// Error banner component
struct ErrorBanner: View {
  let message: String

  var body: some View {
    BannerView(message: message, type: .error)
  }
}

/// Success banner component
struct SuccessBanner: View {
  let message: String

  var body: some View {
    BannerView(message: message, type: .success)
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
          .accessibilityLabel(isSuccess ? "Success" : "Error")
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

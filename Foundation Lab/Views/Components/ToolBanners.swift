//
//  ToolBanners.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import SwiftUI

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
    case .info: return .main
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

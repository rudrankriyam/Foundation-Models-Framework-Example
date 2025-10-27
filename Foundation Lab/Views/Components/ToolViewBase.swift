//
//  ToolViewBase.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
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
      VStack(alignment: .leading, spacing: Spacing.large) {
        if let error = errorMessage {
          Text(error)
            .font(.callout)
            .foregroundColor(.secondary)
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }

        content
      }
      .padding(.horizontal, Spacing.medium)
      .padding(.vertical, Spacing.large)
    }
    #if os(iOS)
    .scrollDismissesKeyboard(.interactively)
    #endif
    .navigationTitle(title)
    #if os(iOS)
    .navigationBarTitleDisplayMode(.large)
    .navigationSubtitle(description)
    #endif
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

/// Result display component
struct ResultDisplay: View {
  let result: String
  let isSuccess: Bool
  @State private var isCopied = false

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.small) {
      HStack {
        Text("RESULT")
          .font(.footnote)
          .fontWeight(.medium)
          .foregroundColor(.secondary)

        Spacer()

        Button(action: copyToClipboard) {
          Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
            .font(.callout)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, 4)
        }
        .buttonStyle(.glass)
      }

      ScrollView {
        Text(LocalizedStringKey(result))
          .font(.body)
          .textSelection(.enabled)
          .padding(Spacing.medium)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.gray.opacity(0.1))
          .cornerRadius(12)
      }
      .frame(maxHeight: 300)
    }
  }

  private func copyToClipboard() {
    #if os(iOS)
    UIPasteboard.general.string = result
    #elseif os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(result, forType: .string)
    #endif

    isCopied = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      isCopied = false
    }
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

// MARK: - Tool Executor Helper

/// A reusable helper class that eliminates code duplication across tool views
/// by providing a standardized pattern for executing tool operations
@MainActor
@Observable
final class ToolExecutor {
  var isRunning = false
  var result: String = ""
  var errorMessage: String?
  var successMessage: String?

  /// Executes a tool operation with standardized state management
  /// - Parameters:
  ///   - operation: The async operation to execute
  ///   - successMessage: Optional success message to display
  ///   - clearForm: Optional closure to clear form data on success
  func execute<T: Tool>(
    tool: T,
    prompt: String,
    successMessage: String? = nil,
    clearForm: (() -> Void)? = nil
  ) async {
    isRunning = true
    errorMessage = nil
    self.successMessage = nil
    result = ""

    do {
      let session = LanguageModelSession(tools: [tool])
      let response = try await session.respond(to: Prompt(prompt))
      result = response.content

      if let successMessage = successMessage {
        self.successMessage = successMessage
      }

      clearForm?()

    } catch {
      errorMessage = handleError(error)
      // Clear success message on error
      self.successMessage = nil
    }

    isRunning = false
  }

  /// Executes a tool operation using PromptBuilder
  /// - Parameters:
  ///   - tool: The tool to execute
  ///   - successMessage: Optional success message to display
  ///   - clearForm: Optional closure to clear form data on success
  ///   - promptBuilder: A closure that builds the prompt using @PromptBuilder
  func executeWithPromptBuilder<T: Tool>(
    tool: T,
    successMessage: String? = nil,
    clearForm: (() -> Void)? = nil,
    @PromptBuilder promptBuilder: () -> Prompt
  ) async {
    isRunning = true
    errorMessage = nil
    self.successMessage = nil
    result = ""

    do {
      let session = LanguageModelSession(tools: [tool])
      let response = try await session.respond(to: promptBuilder())
      result = response.content

      if let successMessage = successMessage {
        self.successMessage = successMessage
      }

      clearForm?()

    } catch {
      errorMessage = handleError(error)
      // Clear success message on error
      self.successMessage = nil
    }

    isRunning = false
  }

  /// Executes a tool operation with a custom session configuration
  /// - Parameters:
  ///   - sessionBuilder: Custom session builder closure
  ///   - successMessage: Optional success message to display
  ///   - clearForm: Optional closure to clear form data on success
  func executeWithCustomSession(
    sessionBuilder: () -> LanguageModelSession,
    prompt: String,
    successMessage: String? = nil,
    clearForm: (() -> Void)? = nil
  ) async {
    isRunning = true
    errorMessage = nil
    self.successMessage = nil
    result = ""

    do {
      let session = sessionBuilder()
      let response = try await session.respond(to: Prompt(prompt))
      result = response.content

      if let successMessage = successMessage {
        self.successMessage = successMessage
      }

      clearForm?()

    } catch {
      errorMessage = handleError(error)
      // Clear success message on error
      self.successMessage = nil
    }

    isRunning = false
  }

  /// Clears all state
  func clear() {
    isRunning = false
    result = ""
    errorMessage = nil
    successMessage = nil
  }

  /// Handles various error types and returns user-friendly messages
  private func handleError(_ error: Error) -> String {
    if let generationError = error as? LanguageModelSession.GenerationError {
      return FoundationModelsErrorHandler.handleGenerationError(generationError)
    } else if let toolCallError = error as? LanguageModelSession.ToolCallError {
      return FoundationModelsErrorHandler.handleToolCallError(toolCallError)
    } else if let customError = error as? FoundationModelsError {
      return customError.localizedDescription
    } else {
      return "Unexpected error: \(error.localizedDescription)"
    }
  }
}

// MARK: - Standard Tool Components

/// Standard execute button for tool views
struct ToolExecuteButton: View {
  let title: String
  let systemImage: String?
  let isRunning: Bool
  let action: () -> Void

  init(
    _ title: String,
    systemImage: String? = nil,
    isRunning: Bool = false,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.systemImage = systemImage
    self.isRunning = isRunning
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: Spacing.small) {
        if isRunning {
          ProgressView()
            .scaleEffect(0.8)
            .tint(.white)
        } else if let systemImage {
          Image(systemName: systemImage)
        }
        Text(isRunning ? "\(title)..." : title)
          .font(.callout)
          .fontWeight(.medium)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, Spacing.small)
    }
    .buttonStyle(.glassProminent)
    .disabled(isRunning)
  }
}

/// Standard input field for tool views
struct ToolInputField: View {
  let label: String
  @Binding var text: String
  let placeholder: String

  var body: some View {
    VStack(alignment: .leading, spacing: Spacing.small) {
      Text(label.uppercased())
        .font(.footnote)
        .fontWeight(.medium)
        .foregroundColor(.secondary)

      TextEditor(text: $text)
        .font(.body)
        .scrollContentBackground(.hidden)
        .padding(Spacing.medium)
        .frame(minHeight: 60, maxHeight: 120)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
  }
}

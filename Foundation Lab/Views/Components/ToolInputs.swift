//
//  ToolInputs.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import SwiftUI

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

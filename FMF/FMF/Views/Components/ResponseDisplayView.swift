//
//  ResponseDisplayView.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//

import FoundationModels
import SwiftUI

/// View component for displaying AI model responses
struct ResponseDisplayView: View {
  let response: String
  let isError: Bool
  let onClear: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      headerView
      contentView
    }
  }

  private var headerView: some View {
    HStack {
      Text("Response")
        .font(.headline)

      Spacer()

      Button("Clear", action: onClear)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal)
  }

  private var contentView: some View {
    ScrollView {
      Text(response)
        .font(.system(.body, design: .monospaced))
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundView)
        .foregroundColor(textColor)
        .textSelection(.enabled)
    }
    .padding(.horizontal)
  }

  private var backgroundView: some View {
    RoundedRectangle(cornerRadius: 8)
      .fill(backgroundColor)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(borderColor, lineWidth: 1)
      )
  }

  private var backgroundColor: Color {
    isError ? Color.red.opacity(0.1) : Color.gray.opacity(0.1)
  }

  private var borderColor: Color {
    isError ? Color.red.opacity(0.3) : Color.gray.opacity(0.2)
  }

  private var textColor: Color {
    isError ? .red : .primary
  }
}

#Preview {
  VStack(spacing: 20) {
    ResponseDisplayView(
      response:
        "This is a successful response from the AI model with some longer text to show how it wraps and displays.",
      isError: false,
      onClear: {}
    )

    ResponseDisplayView(
      response: "This is an error message that would be displayed when something goes wrong.",
      isError: true,
      onClear: {}
    )
  }
  .padding()
}

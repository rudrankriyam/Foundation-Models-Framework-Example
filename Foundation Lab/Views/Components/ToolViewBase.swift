//
//  ToolViewBase.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
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

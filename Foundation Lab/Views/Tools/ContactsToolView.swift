//
//  ContactsToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import FoundationModelsTools
import SwiftUI

struct ContactsToolView: View {
  @Environment(ToolExecutor.self) private var executor
  @State private var searchQuery: String = ""

  var body: some View {
    ToolViewBase(
      title: "Contacts",
      icon: "person.2",
      description: "Search and display contact information",
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage
    ) {
      VStack(alignment: .leading, spacing: Spacing.large) {
        if let successMessage = executor.successMessage {
          SuccessBanner(message: successMessage)
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("SEARCH CONTACTS")
            .font(.footnote)
            .fontWeight(.medium)
            .foregroundColor(.secondary)

          TextEditor(text: $searchQuery)
            .scrollContentBackground(.hidden)
            .padding(Spacing.medium)
            .frame(height: 50)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }

        Button(action: executeContactsSearch) {
          HStack(spacing: Spacing.small) {
            if executor.isRunning {
              ProgressView()
                .scaleEffect(0.8)
                .accessibilityLabel("Processing")
            } else {
              Image(systemName: "person.2")
                .accessibilityHidden(true)
            }

            Text(executor.isRunning ? "Searching..." : "Search Contacts")
              .fontWeight(.medium)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, Spacing.small)
        }
        .buttonStyle(.glassProminent)
        .disabled(executor.isRunning || searchQuery.isEmpty)
        .accessibilityLabel("Search contacts")
        .accessibilityHint(executor.isRunning ? "Processing request" : "Tap to search contacts")

        if !executor.result.isEmpty {
          ResultDisplay(result: executor.result, isSuccess: executor.errorMessage == nil)
        }
      }
    }
  }

  private func executeContactsSearch() {
    Task {
      await executor.execute(
        tool: ContactsTool(),
        prompt: "Find contacts named \(searchQuery)",
        successMessage: "Contact search completed successfully!",
        clearForm: { searchQuery = "" }
      )
    }
  }
}

#Preview {
  NavigationStack {
    ContactsToolView()
      .withToolExecutor()
  }
}

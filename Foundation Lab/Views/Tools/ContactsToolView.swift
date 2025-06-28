//
//  ContactsToolView.swift
//  FoundationLab
//
//  Created by Claude on 1/14/25.
//

import FoundationModels
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
      VStack(alignment: .leading, spacing: 16) {
        if let successMessage = executor.successMessage {
          SuccessBanner(message: successMessage)
        }

        VStack(alignment: .leading, spacing: 8) {
          Text("Search Contacts")
            .font(.subheadline)
            .fontWeight(.medium)

          TextField("Enter name to search", text: $searchQuery)
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }

        Button(action: executeContactsSearch) {
          HStack {
            if executor.isRunning {
              ProgressView()
                .scaleEffect(0.8)
                .foregroundColor(.white)
                .accessibilityLabel("Processing")
            } else {
              Image(systemName: "person.2")
                .accessibilityHidden(true)
            }

            Text("Search Contacts")
              .fontWeight(.medium)
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.accentColor)
          .foregroundColor(.white)
          .cornerRadius(12)
        }
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

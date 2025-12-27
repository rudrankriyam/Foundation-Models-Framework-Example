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
  @State private var executor = ToolExecutor()
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

        ToolInputField(
          label: "SEARCH CONTACTS",
          text: $searchQuery,
          placeholder: "Enter contact name"
        )

        ToolExecuteButton(
          "Search Contacts",
          systemImage: "person.2",
          isRunning: executor.isRunning,
          action: executeContactsSearch
        )
        .disabled(executor.isRunning || searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

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
  }
}

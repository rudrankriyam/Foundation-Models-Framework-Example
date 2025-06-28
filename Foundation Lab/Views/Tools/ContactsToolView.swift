//
//  ContactsToolView.swift
//  FoundationLab
//
//  Created by Claude on 1/14/25.
//

import FoundationModels
import SwiftUI

struct ContactsToolView: View {
  @State private var isRunning = false
  @State private var result: String = ""
  @State private var errorMessage: String?
  @State private var searchQuery: String = ""

  var body: some View {
    ToolViewBase(
      title: "Contacts",
      icon: "person.2",
      description: "Search and display contact information",
      isRunning: isRunning,
      errorMessage: errorMessage
    ) {
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Search Contacts")
            .font(.subheadline)
            .fontWeight(.medium)

          TextField("Enter name to search", text: $searchQuery)
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }

        Button(action: executeContactsSearch) {
          HStack {
            if isRunning {
              ProgressView()
                .scaleEffect(0.8)
                .foregroundColor(.white)
            } else {
              Image(systemName: "person.2")
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
        .disabled(isRunning || searchQuery.isEmpty)

        if !result.isEmpty {
          ResultDisplay(result: result, isSuccess: errorMessage == nil)
        }
      }
    }
  }

  private func executeContactsSearch() {
    Task {
      await performContactsSearch()
    }
  }

  @MainActor
  private func performContactsSearch() async {
    isRunning = true
    errorMessage = nil
    result = ""

    do {
      let session = LanguageModelSession(tools: [ContactsTool()])
      let response = try await session.respond(to: Prompt("Find contacts named \(searchQuery)"))
      result = response.content
    } catch {
      errorMessage = "Failed to search contacts: \(error.localizedDescription)"
    }

    isRunning = false
  }
}

#Preview {
  NavigationStack {
    ContactsToolView()
  }
}

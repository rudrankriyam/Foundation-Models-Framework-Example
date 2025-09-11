//
//  MusicToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import FoundationModelsTools
import SwiftUI

struct MusicToolView: View {
  @State private var isRunning = false
  @State private var result: String = ""
  @State private var errorMessage: String?
  @State private var query: String = "Search for songs by Taylor Swift"

  var body: some View {
    ToolViewBase(
      title: "Music",
      icon: "music.note",
      description: "Search and play music, manage playlists, get recommendations",
      isRunning: isRunning,
      errorMessage: errorMessage
    ) {
      VStack(alignment: .leading, spacing: Spacing.large) {
        VStack(alignment: .leading, spacing: 8) {
          Text("MUSIC QUERY")
            .font(.footnote)
            .fontWeight(.medium)
            .foregroundColor(.secondary)

          TextEditor(text: $query)
            .scrollContentBackground(.hidden)
            .padding(Spacing.medium)
            .frame(height: 50)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }

        Button(action: executeMusicQuery) {
          HStack(spacing: Spacing.small) {
            if isRunning {
              ProgressView()
                .scaleEffect(0.8)
            } else {
              Image(systemName: "music.note")
            }

            Text(isRunning ? "Searching..." : "Search Music")
              .fontWeight(.medium)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, Spacing.small)
        }
        .buttonStyle(.glassProminent)
        .disabled(isRunning || query.isEmpty)

        if !result.isEmpty {
          ResultDisplay(result: result, isSuccess: errorMessage == nil)
        }
      }
    }
  }

  private func executeMusicQuery() {
    Task {
      await performMusicQuery()
    }
  }

  @MainActor
  private func performMusicQuery() async {
    isRunning = true
    errorMessage = nil
    result = ""

    do {
      let session = LanguageModelSession(tools: [MusicTool()])
      let response = try await session.respond(to: Prompt(query))
      result = response.content
    } catch {
      errorMessage = "Failed to search music: \(error.localizedDescription)"
    }

    isRunning = false
  }
}

#Preview {
  NavigationStack {
    MusicToolView()
  }
}

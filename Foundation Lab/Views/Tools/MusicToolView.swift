//
//  MusicToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationLabCore
import SwiftUI

struct MusicToolView: View {
  @State private var executor = ToolExecutor()
  @State private var query: String = "Search for songs by Taylor Swift"

  var body: some View {
    ToolViewBase(
      title: "Music",
      icon: "music.note",
      description: "Search and play music, manage playlists, get recommendations",
      isRunning: executor.isRunning,
      errorMessage: executor.errorMessage
    ) {
      VStack(alignment: .leading, spacing: Spacing.large) {
        ToolInputField(
          label: "Music Query",
          text: $query,
          placeholder: "Search for songs, artists, or albums"
        )

        ToolExecuteButton(
          "Search Music",
          systemImage: "music.note",
          isRunning: executor.isRunning,
          action: executeMusicQuery
        )
        .disabled(executor.isRunning || query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

        if !executor.result.isEmpty {
          ResultDisplay(result: executor.result, isSuccess: executor.errorMessage == nil)
        }
      }
    }
  }

  private func executeMusicQuery() {
    Task {
      await executor.executeCapability(
        successMessage: "Music search completed successfully!"
      ) {
        try await SearchMusicCatalogUseCase().execute(
          SearchMusicCatalogRequest(
            query: query,
            context: CapabilityInvocationContext(
              source: .app,
              localeIdentifier: Locale.current.identifier
            )
          )
        )
      }
    }
  }
}

#Preview {
  NavigationStack {
    MusicToolView()
  }
}

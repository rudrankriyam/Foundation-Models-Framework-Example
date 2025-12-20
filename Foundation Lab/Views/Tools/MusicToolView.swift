//
//  MusicToolView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationModels
import FoundationModelsTools
import MusicKit
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
      await performMusicQuery()
    }
  }

  @MainActor
  private func performMusicQuery() async {
    // Show loading state during pre-execution checks
    executor.isRunning = true
    executor.errorMessage = nil
    executor.result = ""

    if let authorizationError = await musicAuthorizationIssueDescription() {
      executor.errorMessage = authorizationError
      executor.isRunning = false
      return
    }

    do {
      let subscription = try await MusicSubscription.current
      guard subscription.canPlayCatalogContent else {
        executor.errorMessage = "An active Apple Music subscription is required to search the catalog."
        executor.isRunning = false
        return
      }
    } catch {
      executor.errorMessage = "Unable to verify Apple Music subscription: \(error.localizedDescription)"
      executor.isRunning = false
      return
    }

    // executor.execute() will manage isRunning state for the tool execution
    await executor.execute(tool: MusicTool(), prompt: query)
  }

  @MainActor
  private func musicAuthorizationIssueDescription() async -> String? {
    let currentStatus = MusicAuthorization.currentStatus
    switch currentStatus {
    case .authorized:
      return nil
    case .notDetermined:
      let status = await MusicAuthorization.request()
      return status == .authorized ? nil : authorizationMessage(for: status)
    case .denied:
      return authorizationMessage(for: currentStatus)
    case .restricted:
      return authorizationMessage(for: currentStatus)
    @unknown default:
      return authorizationMessage(for: currentStatus)
    }
  }

  private func authorizationMessage(for status: MusicAuthorization.Status) -> String {
    switch status {
    case .authorized:
      return ""
    case .notDetermined:
      return "Apple Music authorization is not determined."
    case .denied:
      return "Apple Music access is denied. Please enable Music access for FoundationLab in Settings."
    case .restricted:
      return "Apple Music access is restricted on this device."
    @unknown default:
      return "Apple Music authorization is required to use this tool."
    }
  }
}

#Preview {
  NavigationStack {
    MusicToolView()
  }
}

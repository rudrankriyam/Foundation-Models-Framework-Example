//
//  MusicTool.swift
//  FMF
//
//  Created by Claude on 6/18/25.
//

import Foundation
import FoundationModels
import MusicKit

/// `MusicTool` provides access to Apple Music library and playback controls.
///
/// This tool can search music, play songs, create playlists, and get recommendations.
/// Important: This requires Apple Music access and user permission.
struct MusicTool: Tool {
  
  /// The name of the tool, used for identification.
  let name = "accessMusic"
  /// A brief description of the tool's functionality.
  let description = "Search and play music, manage playlists, get recommendations from Apple Music"
  
  /// Arguments for music operations.
  @Generable
  struct Arguments {
    /// The action to perform: "search", "play", "pause", "next", "previous", "currentSong", "playlists", "recommendations"
    @Guide(description: "The action to perform: 'search', 'play', 'pause', 'next', 'previous', 'currentSong', 'playlists', 'recommendations'")
    var action: String
    
    /// Search query for songs, artists, or albums
    @Guide(description: "Search query for songs, artists, or albums")
    var query: String?
    
    /// Type of search: "song", "artist", "album", "playlist"
    @Guide(description: "Type of search: 'song', 'artist', 'album', 'playlist'")
    var searchType: String?
    
    /// Maximum number of results (defaults to 10)
    @Guide(description: "Maximum number of results (defaults to 10)")
    var limit: Int?
    
    /// Song or album ID to play
    @Guide(description: "Song or album ID to play")
    var itemId: String?
  }
  
  func call(arguments: Arguments) async throws -> ToolOutput {
    // Check if MusicKit is authorized
    let authStatus = MusicAuthorization.currentStatus
    
    guard authStatus == .authorized else {
      if authStatus == .notDetermined {
        let status = await MusicAuthorization.request()
        if status != .authorized {
          return createErrorOutput(error: MusicError.authorizationDenied)
        }
      } else {
        return createErrorOutput(error: MusicError.authorizationDenied)
      }
    }
    
    switch arguments.action.lowercased() {
    case "search":
      return await searchMusic(query: arguments.query, type: arguments.searchType, limit: arguments.limit)
    case "play":
      return await playMusic(itemId: arguments.itemId, query: arguments.query)
    case "pause":
      return pauseMusic()
    case "next":
      return skipToNext()
    case "previous":
      return skipToPrevious()
    case "currentsong":
      return getCurrentSong()
    case "playlists":
      return await getUserPlaylists()
    case "recommendations":
      return await getRecommendations()
    default:
      return createErrorOutput(error: MusicError.invalidAction)
    }
  }
  
  private func searchMusic(query: String?, type: String?, limit: Int?) async -> ToolOutput {
    guard let query = query, !query.isEmpty else {
      return createErrorOutput(error: MusicError.missingQuery)
    }
    
    let searchLimit = limit ?? 10
    var request = MusicCatalogSearchRequest(term: query, types: [Song.self, Artist.self, Album.self])
    request.limit = searchLimit
    
    do {
      let response = try await request.response()
      var resultDescription = ""
      
      // Process songs
      if !response.songs.isEmpty {
        resultDescription += "🎵 Songs:\n"
        for (index, song) in response.songs.prefix(5).enumerated() {
          resultDescription += "\(index + 1). \"\(song.title)\" by \(song.artistName)\n"
          if let album = song.albumTitle {
            resultDescription += "   Album: \(album)\n"
          }
          resultDescription += "   ID: \(song.id)\n\n"
        }
      }
      
      // Process artists
      if !response.artists.isEmpty {
        resultDescription += "👤 Artists:\n"
        for (index, artist) in response.artists.prefix(3).enumerated() {
          resultDescription += "\(index + 1). \(artist.name)\n"
          resultDescription += "   ID: \(artist.id)\n\n"
        }
      }
      
      // Process albums
      if !response.albums.isEmpty {
        resultDescription += "💿 Albums:\n"
        for (index, album) in response.albums.prefix(3).enumerated() {
            resultDescription += "\(index + 1). \"\(album.title)\" by \(album.artistName)\n"
          if let releaseDate = album.releaseDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            resultDescription += "   Released: \(formatter.string(from: releaseDate))\n"
          }
          resultDescription += "   ID: \(album.id)\n\n"
        }
      }
      
      if resultDescription.isEmpty {
        resultDescription = "No results found for '\(query)'"
      }
      
      return ToolOutput(
        GeneratedContent(properties: [
          "status": "success",
          "query": query,
          "resultCount": response.songs.count + response.artists.count + response.albums.count,
          "results": resultDescription.trimmingCharacters(in: .whitespacesAndNewlines),
          "message": "Found music matching '\(query)'"
        ])
      )
    } catch {
      return createErrorOutput(error: error)
    }
  }
  
  private func playMusic(itemId: String?, query: String?) async -> ToolOutput {
    do {
      let player = ApplicationMusicPlayer.shared

      if let itemId = itemId {
        // Play specific item by ID
        let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: MusicItemID(itemId))
        let response = try await request.response()
        
        if let song = response.items.first {
          player.queue = [song]
          try await player.play()
          
          return ToolOutput(
            GeneratedContent(properties: [
              "status": "success",
              "action": "play",
              "nowPlaying": "\(song.title) by \(song.artistName)",
              "message": "Now playing: \(song.title)"
            ])
          )
        } else {
          return createErrorOutput(error: MusicError.itemNotFound)
        }
      } else if let query = query {
        // Search and play first result
        var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
        request.limit = 1
        let response = try await request.response()
        
        if let song = response.songs.first {
          player.queue = [song]
          try await player.play()
          
          return ToolOutput(
            GeneratedContent(properties: [
              "status": "success",
              "action": "play",
              "nowPlaying": "\(song.title) by \(song.artistName)",
              "message": "Now playing: \(song.title)"
            ])
          )
        } else {
          return createErrorOutput(error: MusicError.noResults)
        }
      } else {
        // Resume playback
        try await player.play()
        return ToolOutput(
          GeneratedContent(properties: [
            "status": "success",
            "action": "resume",
            "message": "Playback resumed"
          ])
        )
      }
    } catch {
      return createErrorOutput(error: error)
    }
  }
  
  private func pauseMusic() -> ToolOutput {
    let player = ApplicationMusicPlayer.shared
    player.pause()
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "action": "pause",
        "message": "Playback paused"
      ])
    )
  }
  
  private func skipToNext() -> ToolOutput {
    Task {
      let player = ApplicationMusicPlayer.shared
      try await player.skipToNextEntry()
    }
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "action": "next",
        "message": "Skipped to next song"
      ])
    )
  }
  
  private func skipToPrevious() -> ToolOutput {
    Task {
      let player = ApplicationMusicPlayer.shared
      try await player.skipToPreviousEntry()
    }
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "action": "previous",
        "message": "Skipped to previous song"
      ])
    )
  }
  
  private func getCurrentSong() -> ToolOutput {
    let player = ApplicationMusicPlayer.shared

    guard let nowPlaying = player.queue.currentEntry else {
      return ToolOutput(
        GeneratedContent(properties: [
          "status": "success",
          "message": "No song currently playing"
        ])
      )
    }
    
    // Check if the entry has an item (non-transient)
    if let item = nowPlaying.item {
      var properties: [String: Any] = [
        "status": "success",
        "id": item.id.rawValue,
        "playbackState": player.state.playbackStatus
      ]

        switch item {
        case .song(let song):
            properties["title"] = song.title
            properties["artist"] = song.artistName

            if let album = song.albumTitle {
                properties["album"] = album
            }

            if let duration = song.duration {
                properties["duration"] = formatDuration(duration)
            }

            properties["message"] = "Currently playing: \(song.title) by \(song.artistName)"
        default:
            properties["message"] = "Currently playing: \(item.id)"
        }


      return ToolOutput(GeneratedContent(properties: properties))
    } else if let transientItem = nowPlaying.transientItem {
      // Handle transient items
      return ToolOutput(
        GeneratedContent(properties: [
          "status": "success",
          "message": "Loading: \(transientItem.id)",
          "isTransient": true
        ])
      )
    } else {
      return ToolOutput(
        GeneratedContent(properties: [
          "status": "success",
          "message": "Unknown playback state"
        ])
      )
    }
  }
  
  private func getUserPlaylists() async -> ToolOutput {
    do {
      var request = MusicLibraryRequest<Playlist>()
      request.limit = 20
      let response = try await request.response()
      
      var playlistDescription = ""
      
      for (index, playlist) in response.items.enumerated() {
        playlistDescription += "\(index + 1). \(playlist.name)\n"
        if let description = playlist.curatorName {
          playlistDescription += "   Curator: \(description)\n"
        }
        playlistDescription += "   ID: \(playlist.id)\n\n"
      }
      
      if playlistDescription.isEmpty {
        playlistDescription = "No playlists found in your library"
      }
      
      return ToolOutput(
        GeneratedContent(properties: [
          "status": "success",
          "playlistCount": response.items.count,
          "playlists": playlistDescription.trimmingCharacters(in: .whitespacesAndNewlines),
          "message": "Found \(response.items.count) playlist(s)"
        ])
      )
    } catch {
      return createErrorOutput(error: error)
    }
  }
  
    private func getRecommendations() async -> ToolOutput {
        return ToolOutput(
            GeneratedContent(properties: [
                "status": "success",
                "message": "Music recommendations feature is currently simplified. Use search to find music."
            ])
        )
    }
  
  private func formatDuration(_ duration: TimeInterval) -> String {
    let minutes = Int(duration) / 60
    let seconds = Int(duration) % 60
    return String(format: "%d:%02d", minutes, seconds)
  }
  
  private func createErrorOutput(error: Error) -> ToolOutput {
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "error",
        "error": error.localizedDescription,
        "message": "Failed to perform music operation"
      ])
    )
  }
}

enum MusicError: Error, LocalizedError {
  case invalidAction
  case authorizationDenied
  case missingQuery
  case itemNotFound
  case noResults
  
  var errorDescription: String? {
    switch self {
    case .invalidAction:
      return "Invalid action. Use 'search', 'play', 'pause', 'next', 'previous', 'currentSong', 'playlists', or 'recommendations'."
    case .authorizationDenied:
      return "Apple Music access denied. Please grant permission in Settings."
    case .missingQuery:
      return "Search query is required."
    case .itemNotFound:
      return "The requested music item was not found."
    case .noResults:
      return "No results found for your search."
    }
  }
}

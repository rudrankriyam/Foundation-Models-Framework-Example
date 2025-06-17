//
//  PhotosTool.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/17/25.
//

import Foundation
import FoundationModels
import Photos
import PhotosUI

/// `PhotosTool` provides access to the Photos library using PhotoKit.
///
/// This tool can search photos by date, location, album, and manage photo metadata.
/// It requires appropriate permissions to access the photo library.
struct PhotosTool: Tool {
  
  /// The name of the tool, used for identification.
  let name = "managePhotos"
  /// A brief description of the tool's functionality.
  let description = "Search and manage photos by date, location, album, or content type"
  
  /// Arguments for photo operations.
  @Generable
  struct Arguments {
    /// The action to perform: "search", "getAlbums", "getInfo", "createAlbum", "addToFavorites"
    @Guide(description: "The action to perform: 'search', 'getAlbums', 'getInfo', 'createAlbum', 'addToFavorites'")
    var action: String
    
    /// Search criteria: "recent", "favorites", "screenshots", "selfies", "videos", "location"
    @Guide(description: "Search criteria: 'recent', 'favorites', 'screenshots', 'selfies', 'videos', 'location'")
    var searchType: String?
    
    /// Album name (for album operations)
    @Guide(description: "Album name (for album operations)")
    var albumName: String?
    
    /// Number of results to return (default: 10)
    @Guide(description: "Number of results to return (default: 10)")
    var limit: Int?
    
    /// Start date in ISO 8601 format (for date-based search)
    @Guide(description: "Start date in ISO 8601 format (for date-based search)")
    var startDate: String?
    
    /// End date in ISO 8601 format (for date-based search)
    @Guide(description: "End date in ISO 8601 format (for date-based search)")
    var endDate: String?
    
    /// Photo identifier (for specific photo operations)
    @Guide(description: "Photo identifier (for specific photo operations)")
    var photoId: String?
    
    /// Location name (for location-based search)
    @Guide(description: "Location name (for location-based search)")
    var location: String?
  }
  
  /// Photo data structure
  struct PhotoData: Encodable {
    let id: String
    let creationDate: String
    let modificationDate: String
    let mediaType: String
    let pixelWidth: Int
    let pixelHeight: Int
    let isFavorite: Bool
    let isHidden: Bool
    let location: LocationInfo?
    let duration: Double?
  }
  
  struct LocationInfo: Encodable {
    let latitude: Double
    let longitude: Double
  }
  
  struct AlbumData: Encodable {
    let id: String
    let title: String
    let assetCount: Int
    let type: String
  }
  
  private let dateFormatter = ISO8601DateFormatter()
  
  func call(arguments: Arguments) async throws -> ToolOutput {
    // Request authorization
    let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    guard status == .authorized else {
      return createErrorOutput(error: PhotosError.authorizationDenied)
    }
    
    switch arguments.action.lowercased() {
    case "search":
      return try await searchPhotos(arguments: arguments)
    case "getalbums":
      return getAlbums()
    case "getinfo":
      return try getPhotoInfo(arguments: arguments)
    case "createalbum":
      return try await createAlbum(arguments: arguments)
    case "addtofavorites":
      return try await addToFavorites(arguments: arguments)
    default:
      return createErrorOutput(error: PhotosError.invalidAction)
    }
  }
  
  private func searchPhotos(arguments: Arguments) async throws -> ToolOutput {
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    fetchOptions.fetchLimit = arguments.limit ?? 10
    
    var fetchResult: PHFetchResult<PHAsset>
    
    switch arguments.searchType?.lowercased() ?? "recent" {
    case "recent":
      fetchResult = PHAsset.fetchAssets(with: fetchOptions)
      
    case "favorites":
      fetchOptions.predicate = NSPredicate(format: "isFavorite == YES")
      fetchResult = PHAsset.fetchAssets(with: fetchOptions)
      
    case "screenshots":
      fetchOptions.predicate = NSPredicate(
        format: "(mediaSubtype & %d) != 0",
        PHAssetMediaSubtype.photoScreenshot.rawValue
      )
      fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
      
    case "selfies":
      if #available(iOS 10.2, *) {
        fetchOptions.predicate = NSPredicate(
          format: "(mediaSubtype & %d) != 0",
          PHAssetMediaSubtype.photoDepthEffect.rawValue
        )
      }
      fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
      
    case "videos":
      fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
      
    case "location":
      if let _ = arguments.location {
        fetchOptions.predicate = NSPredicate(format: "location != nil")
        fetchResult = PHAsset.fetchAssets(with: fetchOptions)
      } else {
        fetchResult = PHAsset.fetchAssets(with: fetchOptions)
      }
      
    case "daterange":
      if let startDateString = arguments.startDate,
         let endDateString = arguments.endDate,
         let startDate = dateFormatter.date(from: startDateString),
         let endDate = dateFormatter.date(from: endDateString) {
        fetchOptions.predicate = NSPredicate(
          format: "creationDate >= %@ AND creationDate <= %@",
          startDate as NSDate,
          endDate as NSDate
        )
        fetchResult = PHAsset.fetchAssets(with: fetchOptions)
      } else {
        fetchResult = PHAsset.fetchAssets(with: fetchOptions)
      }
      
    default:
      fetchResult = PHAsset.fetchAssets(with: fetchOptions)
    }
    
    var photos: [PhotoData] = []
    
    fetchResult.enumerateObjects { asset, _, _ in
      let photoData = PhotoData(
        id: asset.localIdentifier,
        creationDate: self.dateFormatter.string(from: asset.creationDate ?? Date()),
        modificationDate: self.dateFormatter.string(from: asset.modificationDate ?? Date()),
        mediaType: self.mediaTypeName(asset.mediaType),
        pixelWidth: asset.pixelWidth,
        pixelHeight: asset.pixelHeight,
        isFavorite: asset.isFavorite,
        isHidden: asset.isHidden,
        location: asset.location.map { LocationInfo(
          latitude: $0.coordinate.latitude,
          longitude: $0.coordinate.longitude
        )},
        duration: asset.mediaType == .video ? asset.duration : nil
      )
      photos.append(photoData)
    }
    
    return createPhotosSuccessOutput(
      message: "Found \(photos.count) photos",
      photos: photos
    )
  }
  
  private func getAlbums() -> ToolOutput {
    var albums: [AlbumData] = []
    
    // User albums
    let userAlbums = PHAssetCollection.fetchAssetCollections(
      with: .album,
      subtype: .albumRegular,
      options: nil
    )
    
    userAlbums.enumerateObjects { collection, _, _ in
      let assetCount = PHAsset.fetchAssets(in: collection, options: nil).count
      albums.append(AlbumData(
        id: collection.localIdentifier,
        title: collection.localizedTitle ?? "Untitled",
        assetCount: assetCount,
        type: "User Album"
      ))
    }
    
    // Smart albums
    let smartAlbums = PHAssetCollection.fetchAssetCollections(
      with: .smartAlbum,
      subtype: .any,
      options: nil
    )
    
    smartAlbums.enumerateObjects { collection, _, _ in
      let assetCount = PHAsset.fetchAssets(in: collection, options: nil).count
      if assetCount > 0 {
        albums.append(AlbumData(
          id: collection.localIdentifier,
          title: collection.localizedTitle ?? "Untitled",
          assetCount: assetCount,
          type: "Smart Album"
        ))
      }
    }
    
    return createAlbumsSuccessOutput(albums: albums)
  }
  
  private func getPhotoInfo(arguments: Arguments) throws -> ToolOutput {
    guard let photoId = arguments.photoId else {
      return createErrorOutput(error: PhotosError.missingPhotoId)
    }
    
    let fetchResult = PHAsset.fetchAssets(
      withLocalIdentifiers: [photoId],
      options: nil
    )
    
    guard let asset = fetchResult.firstObject else {
      return createErrorOutput(error: PhotosError.photoNotFound)
    }
    
    let photoData = PhotoData(
      id: asset.localIdentifier,
      creationDate: dateFormatter.string(from: asset.creationDate ?? Date()),
      modificationDate: dateFormatter.string(from: asset.modificationDate ?? Date()),
      mediaType: mediaTypeName(asset.mediaType),
      pixelWidth: asset.pixelWidth,
      pixelHeight: asset.pixelHeight,
      isFavorite: asset.isFavorite,
      isHidden: asset.isHidden,
      location: asset.location.map { LocationInfo(
        latitude: $0.coordinate.latitude,
        longitude: $0.coordinate.longitude
      )},
      duration: asset.mediaType == .video ? asset.duration : nil
    )
    
    return createPhotosSuccessOutput(
      message: "Photo information retrieved",
      photos: [photoData]
    )
  }
  
  private func createAlbum(arguments: Arguments) async throws -> ToolOutput {
    guard let albumName = arguments.albumName else {
      return createErrorOutput(error: PhotosError.missingAlbumName)
    }
    
    var albumPlaceholder: String?
    
    try await PHPhotoLibrary.shared().performChanges {
      let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(
        withTitle: albumName
      )
      albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection.localIdentifier
    }
    
    guard let albumId = albumPlaceholder else {
      return createErrorOutput(error: PhotosError.albumCreationFailed)
    }
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "message": "Album created successfully",
        "albumId": albumId,
        "albumName": albumName
      ])
    )
  }
  
  private func addToFavorites(arguments: Arguments) async throws -> ToolOutput {
    guard let photoId = arguments.photoId else {
      return createErrorOutput(error: PhotosError.missingPhotoId)
    }
    
    let fetchResult = PHAsset.fetchAssets(
      withLocalIdentifiers: [photoId],
      options: nil
    )
    
    guard let asset = fetchResult.firstObject else {
      return createErrorOutput(error: PhotosError.photoNotFound)
    }
    
    try await PHPhotoLibrary.shared().performChanges {
      let changeRequest = PHAssetChangeRequest(for: asset)
      changeRequest.isFavorite = true
    }
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "message": "Photo added to favorites",
        "photoId": photoId
      ])
    )
  }
  
  private func mediaTypeName(_ type: PHAssetMediaType) -> String {
    switch type {
    case .image: return "Photo"
    case .video: return "Video"
    case .audio: return "Audio"
    case .unknown: return "Unknown"
    @unknown default: return "Unknown"
    }
  }
  
  private func createPhotosSuccessOutput(message: String, photos: [PhotoData]) -> ToolOutput {
    var properties: [String: Any] = [
      "status": "success",
      "message": message,
      "count": photos.count
    ]
    
    if !photos.isEmpty {
      properties["photos"] = photos.map { photo in
        var photoDict: [String: Any] = [
          "id": photo.id,
          "creationDate": photo.creationDate,
          "modificationDate": photo.modificationDate,
          "mediaType": photo.mediaType,
          "pixelWidth": photo.pixelWidth,
          "pixelHeight": photo.pixelHeight,
          "isFavorite": photo.isFavorite,
          "isHidden": photo.isHidden
        ]
        
        if let location = photo.location {
          photoDict["location"] = [
            "latitude": location.latitude,
            "longitude": location.longitude
          ]
        }
        
        if let duration = photo.duration {
          photoDict["duration"] = duration
        }
        
        return photoDict
      }
    }
    
    return ToolOutput(GeneratedContent(properties: properties))
  }
  
  private func createAlbumsSuccessOutput(albums: [AlbumData]) -> ToolOutput {
    var properties: [String: Any] = [
      "status": "success",
      "count": albums.count
    ]
    
    properties["albums"] = albums.map { album in
      [
        "id": album.id,
        "title": album.title,
        "assetCount": album.assetCount,
        "type": album.type
      ]
    }
    
    return ToolOutput(GeneratedContent(properties: properties))
  }
  
  private func createErrorOutput(error: Error) -> ToolOutput {
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "error",
        "error": error.localizedDescription,
        "message": "Failed to perform photo operation"
      ])
    )
  }
}

enum PhotosError: Error, LocalizedError {
  case authorizationDenied
  case invalidAction
  case missingPhotoId
  case missingAlbumName
  case photoNotFound
  case albumCreationFailed
  
  var errorDescription: String? {
    switch self {
    case .authorizationDenied:
      return "Access to photos denied. Please grant permission in Settings."
    case .invalidAction:
      return "Invalid action. Use 'search', 'getAlbums', 'getInfo', 'createAlbum', or 'addToFavorites'."
    case .missingPhotoId:
      return "Photo ID is required for this operation."
    case .missingAlbumName:
      return "Album name is required for creating an album."
    case .photoNotFound:
      return "Photo not found with the provided ID."
    case .albumCreationFailed:
      return "Failed to create the album."
    }
  }
}
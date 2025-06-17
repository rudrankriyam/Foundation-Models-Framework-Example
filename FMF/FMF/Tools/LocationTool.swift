//
//  LocationTool.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/17/25.
//

import CoreLocation
import Foundation
import FoundationModels
import MapKit

/// `LocationTool` provides location-based services using CoreLocation and MapKit.
///
/// This tool can get current location, perform geocoding/reverse geocoding, and calculate distances.
/// It requires appropriate permissions to access location services.
struct LocationTool: Tool {
  
  /// The name of the tool, used for identification.
  let name = "locationServices"
  /// A brief description of the tool's functionality.
  let description = "Get current location, geocode addresses, reverse geocode coordinates, and calculate distances"
  
  /// Arguments for location operations.
  @Generable
  struct Arguments {
    /// The action to perform: "getCurrentLocation", "geocode", "reverseGeocode", "calculateDistance", "searchNearby"
    @Guide(description: "The action to perform: 'getCurrentLocation', 'geocode', 'reverseGeocode', 'calculateDistance', 'searchNearby'")
    var action: String
    
    /// Address to geocode (for geocode action)
    @Guide(description: "Address to geocode (for geocode action)")
    var address: String?
    
    /// Latitude coordinate
    @Guide(description: "Latitude coordinate")
    var latitude: Double?
    
    /// Longitude coordinate
    @Guide(description: "Longitude coordinate")
    var longitude: Double?
    
    /// Second latitude for distance calculation
    @Guide(description: "Second latitude for distance calculation")
    var toLatitude: Double?
    
    /// Second longitude for distance calculation
    @Guide(description: "Second longitude for distance calculation")
    var toLongitude: Double?
    
    /// Search query for nearby places (e.g., "coffee", "restaurant", "gas station")
    @Guide(description: "Search query for nearby places (e.g., 'coffee', 'restaurant', 'gas station')")
    var searchQuery: String?
    
    /// Search radius in meters (default: 1000)
    @Guide(description: "Search radius in meters (default: 1000)")
    var radius: Double?
  }
  
  /// Location data structure
  struct LocationData: Encodable {
    let latitude: Double
    let longitude: Double
    let address: String?
    let city: String?
    let state: String?
    let country: String?
    let postalCode: String?
    let timestamp: String?
  }
  
  /// Place data structure for nearby search
  struct PlaceData: Encodable {
    let name: String
    let address: String?
    let category: String?
    let distance: Double?
    let latitude: Double
    let longitude: Double
    let phoneNumber: String?
    let url: String?
  }
  
  private let locationManager = CLLocationManager()
  private let geocoder = CLGeocoder()
  
  func call(arguments: Arguments) async throws -> ToolOutput {
    switch arguments.action.lowercased() {
    case "getcurrentlocation":
      return await getCurrentLocation()
    case "geocode":
      return try await geocodeAddress(arguments: arguments)
    case "reversegeocode":
      return try await reverseGeocode(arguments: arguments)
    case "calculatedistance":
      return calculateDistance(arguments: arguments)
    case "searchnearby":
      return try await searchNearby(arguments: arguments)
    default:
      return createErrorOutput(error: LocationError.invalidAction)
    }
  }
  
  private func getCurrentLocation() async -> ToolOutput {
    // Check authorization status
    let authStatus = locationManager.authorizationStatus
    
    guard authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse else {
      return createErrorOutput(error: LocationError.locationPermissionDenied)
    }
    
    // For demo purposes, we'll use a simulated location
    // In a real app, you would use CLLocationManager delegate methods
    let simulatedLocation = CLLocation(
      latitude: 37.7749,
      longitude: -122.4194
    )
    
    // Reverse geocode to get address
    do {
      let placemarks = try await geocoder.reverseGeocodeLocation(simulatedLocation)
      let placemark = placemarks.first
      
      let locationData = LocationData(
        latitude: simulatedLocation.coordinate.latitude,
        longitude: simulatedLocation.coordinate.longitude,
        address: formatAddress(from: placemark),
        city: placemark?.locality,
        state: placemark?.administrativeArea,
        country: placemark?.country,
        postalCode: placemark?.postalCode,
        timestamp: ISO8601DateFormatter().string(from: simulatedLocation.timestamp)
      )
      
      return createLocationSuccessOutput(
        message: "Current location retrieved",
        locations: [locationData]
      )
    } catch {
      return createErrorOutput(error: error)
    }
  }
  
  private func geocodeAddress(arguments: Arguments) async throws -> ToolOutput {
    guard let address = arguments.address else {
      return createErrorOutput(error: LocationError.missingAddress)
    }
    
    let placemarks = try await geocoder.geocodeAddressString(address)
    
    guard let placemark = placemarks.first,
          let location = placemark.location else {
      return createErrorOutput(error: LocationError.geocodingFailed)
    }
    
    let locationData = LocationData(
      latitude: location.coordinate.latitude,
      longitude: location.coordinate.longitude,
      address: formatAddress(from: placemark),
      city: placemark.locality,
      state: placemark.administrativeArea,
      country: placemark.country,
      postalCode: placemark.postalCode,
      timestamp: nil
    )
    
    return createLocationSuccessOutput(
      message: "Address geocoded successfully",
      locations: [locationData]
    )
  }
  
  private func reverseGeocode(arguments: Arguments) async throws -> ToolOutput {
    guard let latitude = arguments.latitude,
          let longitude = arguments.longitude else {
      return createErrorOutput(error: LocationError.missingCoordinates)
    }
    
    let location = CLLocation(latitude: latitude, longitude: longitude)
    let placemarks = try await geocoder.reverseGeocodeLocation(location)
    
    guard let placemark = placemarks.first else {
      return createErrorOutput(error: LocationError.reverseGeocodingFailed)
    }
    
    let locationData = LocationData(
      latitude: latitude,
      longitude: longitude,
      address: formatAddress(from: placemark),
      city: placemark.locality,
      state: placemark.administrativeArea,
      country: placemark.country,
      postalCode: placemark.postalCode,
      timestamp: nil
    )
    
    return createLocationSuccessOutput(
      message: "Coordinates reverse geocoded successfully",
      locations: [locationData]
    )
  }
  
  private func calculateDistance(arguments: Arguments) -> ToolOutput {
    guard let fromLat = arguments.latitude,
          let fromLon = arguments.longitude,
          let toLat = arguments.toLatitude,
          let toLon = arguments.toLongitude else {
      return createErrorOutput(error: LocationError.missingCoordinates)
    }
    
    let fromLocation = CLLocation(latitude: fromLat, longitude: fromLon)
    let toLocation = CLLocation(latitude: toLat, longitude: toLon)
    
    let distanceInMeters = fromLocation.distance(from: toLocation)
    let distanceInKilometers = distanceInMeters / 1000.0
    let distanceInMiles = distanceInMeters / 1609.344
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "message": "Distance calculated successfully",
        "fromLatitude": fromLat,
        "fromLongitude": fromLon,
        "toLatitude": toLat,
        "toLongitude": toLon,
        "distanceInMeters": distanceInMeters,
        "distanceInKilometers": distanceInKilometers,
        "distanceInMiles": distanceInMiles
      ])
    )
  }
  
  private func searchNearby(arguments: Arguments) async throws -> ToolOutput {
    guard let searchQuery = arguments.searchQuery else {
      return createErrorOutput(error: LocationError.missingSearchQuery)
    }
    
    let latitude = arguments.latitude ?? 37.7749  // Default to SF if not provided
    let longitude = arguments.longitude ?? -122.4194
    let radius = arguments.radius ?? 1000  // Default 1km radius
    
    let searchRequest = MKLocalSearch.Request()
    searchRequest.naturalLanguageQuery = searchQuery
    searchRequest.region = MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
      latitudinalMeters: radius * 2,
      longitudinalMeters: radius * 2
    )
    
    let search = MKLocalSearch(request: searchRequest)
    let response = try await search.start()
    
    let centerLocation = CLLocation(latitude: latitude, longitude: longitude)
    
    let places = response.mapItems.map { mapItem in
      let placeLocation = mapItem.placemark.location!
      let distance = centerLocation.distance(from: placeLocation)
      
      return PlaceData(
        name: mapItem.name ?? "Unknown",
        address: formatAddress(from: mapItem.placemark),
        category: mapItem.pointOfInterestCategory?.rawValue,
        distance: distance,
        latitude: placeLocation.coordinate.latitude,
        longitude: placeLocation.coordinate.longitude,
        phoneNumber: mapItem.phoneNumber,
        url: mapItem.url?.absoluteString
      )
    }
    
    return createPlaceSuccessOutput(
      message: "Found \(places.count) places nearby",
      places: places
    )
  }
  
  private func formatAddress(from placemark: CLPlacemark?) -> String? {
    guard let placemark = placemark else { return nil }
    
    var addressComponents: [String] = []
    
    if let name = placemark.name {
      addressComponents.append(name)
    }
    if let thoroughfare = placemark.thoroughfare {
      addressComponents.append(thoroughfare)
    }
    if let locality = placemark.locality {
      addressComponents.append(locality)
    }
    if let administrativeArea = placemark.administrativeArea {
      addressComponents.append(administrativeArea)
    }
    if let postalCode = placemark.postalCode {
      addressComponents.append(postalCode)
    }
    if let country = placemark.country {
      addressComponents.append(country)
    }
    
    return addressComponents.joined(separator: ", ")
  }
  
  private func createLocationSuccessOutput(message: String, locations: [LocationData]) -> ToolOutput {
    var properties: [String: Any] = [
      "status": "success",
      "message": message,
      "count": locations.count
    ]
    
    if !locations.isEmpty {
      properties["locations"] = locations.map { location in
        var locationDict: [String: Any] = [
          "latitude": location.latitude,
          "longitude": location.longitude
        ]
        
        if let address = location.address {
          locationDict["address"] = address
        }
        if let city = location.city {
          locationDict["city"] = city
        }
        if let state = location.state {
          locationDict["state"] = state
        }
        if let country = location.country {
          locationDict["country"] = country
        }
        if let postalCode = location.postalCode {
          locationDict["postalCode"] = postalCode
        }
        if let timestamp = location.timestamp {
          locationDict["timestamp"] = timestamp
        }
        
        return locationDict
      }
    }
    
    return ToolOutput(GeneratedContent(properties: properties))
  }
  
  private func createPlaceSuccessOutput(message: String, places: [PlaceData]) -> ToolOutput {
    var properties: [String: Any] = [
      "status": "success",
      "message": message,
      "count": places.count
    ]
    
    if !places.isEmpty {
      properties["places"] = places.map { place in
        var placeDict: [String: Any] = [
          "name": place.name,
          "latitude": place.latitude,
          "longitude": place.longitude
        ]
        
        if let address = place.address {
          placeDict["address"] = address
        }
        if let category = place.category {
          placeDict["category"] = category
        }
        if let distance = place.distance {
          placeDict["distanceInMeters"] = distance
        }
        if let phoneNumber = place.phoneNumber {
          placeDict["phoneNumber"] = phoneNumber
        }
        if let url = place.url {
          placeDict["url"] = url
        }
        
        return placeDict
      }
    }
    
    return ToolOutput(GeneratedContent(properties: properties))
  }
  
  private func createErrorOutput(error: Error) -> ToolOutput {
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "error",
        "error": error.localizedDescription,
        "message": "Failed to perform location operation"
      ])
    )
  }
}

enum LocationError: Error, LocalizedError {
  case invalidAction
  case locationPermissionDenied
  case missingAddress
  case missingCoordinates
  case missingSearchQuery
  case geocodingFailed
  case reverseGeocodingFailed
  
  var errorDescription: String? {
    switch self {
    case .invalidAction:
      return "Invalid action. Use 'getCurrentLocation', 'geocode', 'reverseGeocode', 'calculateDistance', or 'searchNearby'."
    case .locationPermissionDenied:
      return "Location permission denied. Please grant permission in Settings."
    case .missingAddress:
      return "Address is required for geocoding."
    case .missingCoordinates:
      return "Latitude and longitude are required for this operation."
    case .missingSearchQuery:
      return "Search query is required for nearby search."
    case .geocodingFailed:
      return "Failed to geocode the address."
    case .reverseGeocodingFailed:
      return "Failed to reverse geocode the coordinates."
    }
  }
}
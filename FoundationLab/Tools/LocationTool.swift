//
//  LocationTool.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/17/25.
//

import Foundation
import FoundationModels
import CoreLocation
import MapKit

/// `LocationTool` provides location services and geocoding functionality.
///
/// This tool can get current location, geocode addresses, and calculate distances.
/// Important: This requires location services entitlement and user permission.
struct LocationTool: Tool {
  
  /// The name of the tool, used for identification.
  let name = "accessLocation"
  /// A brief description of the tool's functionality.
  let description = "Get current location, geocode addresses, search places, and calculate distances"
  
  /// Arguments for location operations.
  @Generable
  struct Arguments {
    /// The action to perform: "current", "geocode", "reverse", "search", "distance"
    @Guide(description: "The action to perform: 'current', 'geocode', 'reverse', 'search', 'distance'")
    var action: String
    
    /// Address to geocode (for geocode action)
    @Guide(description: "Address to geocode (for geocode action)")
    var address: String?
    
    /// Latitude for reverse geocoding or distance calculation
    @Guide(description: "Latitude for reverse geocoding or distance calculation")
    var latitude: Double?
    
    /// Longitude for reverse geocoding or distance calculation
    @Guide(description: "Longitude for reverse geocoding or distance calculation")
    var longitude: Double?
    
    /// Second latitude for distance calculation
    @Guide(description: "Second latitude for distance calculation")
    var latitude2: Double?
    
    /// Second longitude for distance calculation
    @Guide(description: "Second longitude for distance calculation")
    var longitude2: Double?
    
    /// Search query for places (for search action)
    @Guide(description: "Search query for places (for search action)")
    var searchQuery: String?
    
    /// Search radius in meters (defaults to 1000)
    @Guide(description: "Search radius in meters (defaults to 1000)")
    var radius: Double?
  }
  
  private let locationManager = CLLocationManager()
  
  func call(arguments: Arguments) async throws -> ToolOutput {
    switch arguments.action.lowercased() {
    case "current":
      return await getCurrentLocation()
    case "geocode":
      return await geocodeAddress(address: arguments.address)
    case "reverse":
      return await reverseGeocode(latitude: arguments.latitude, longitude: arguments.longitude)
    case "search":
      return await searchPlaces(query: arguments.searchQuery, radius: arguments.radius)
    case "distance":
      return calculateDistance(arguments: arguments)
    default:
      return createErrorOutput(error: LocationError.invalidAction)
    }
  }
  
  private func getCurrentLocation() async -> ToolOutput {
    // Check authorization status
    let authStatus = locationManager.authorizationStatus
    
    guard authStatus == .authorizedAlways else {
      if authStatus == .notDetermined {
        // Request permission and wait for response
        return await requestLocationPermission()
      }
      return createErrorOutput(error: LocationError.authorizationDenied)
    }
    
    // Get current location
    guard let location = locationManager.location else {
      return createErrorOutput(error: LocationError.locationUnavailable)
    }
    
    // Reverse geocode to get address using new MapKit API
    guard let request = MKReverseGeocodingRequest(location: location) else {
      return createErrorOutput(error: LocationError.reverseGeocodingFailed)
    }
    let mapItems = try? await request.mapItems
    let mapItem = mapItems?.first
    
    let address = formatAddress(mapItem: mapItem)
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "latitude": location.coordinate.latitude,
        "longitude": location.coordinate.longitude,
        "altitude": location.altitude,
        "accuracy": location.horizontalAccuracy,
        "address": address,
        "timestamp": formatDate(location.timestamp),
        "message": "Current location: \(address)"
      ])
    )
  }
  
  private func geocodeAddress(address: String?) async -> ToolOutput {
    guard let address = address, !address.isEmpty else {
      return createErrorOutput(error: LocationError.missingAddress)
    }
    
    do {
      guard let request = MKGeocodingRequest(addressString: address) else {
        return createErrorOutput(error: LocationError.geocodingFailed)
      }
      
      let mapItems = try await request.mapItems
      guard let mapItem = mapItems.first else {
        return createErrorOutput(error: LocationError.geocodingFailed)
      }
      
      let location = mapItem.location
      let formattedAddress = formatAddress(mapItem: mapItem)
      
      return ToolOutput(
        GeneratedContent(properties: [
          "status": "success",
          "query": address,
          "latitude": location.coordinate.latitude,
          "longitude": location.coordinate.longitude,
          "formattedAddress": formattedAddress,
          "country": "",  // These would need to be extracted from addressRepresentations
          "state": "",
          "city": "",
          "postalCode": "",
          "message": "Location found: \(formattedAddress)"
        ])
      )
    } catch {
      return createErrorOutput(error: error)
    }
  }
  
  private func reverseGeocode(latitude: Double?, longitude: Double?) async -> ToolOutput {
    guard let latitude = latitude,
          let longitude = longitude else {
      return createErrorOutput(error: LocationError.missingCoordinates)
    }
    
    let location = CLLocation(latitude: latitude, longitude: longitude)
    
    do {
      guard let request = MKReverseGeocodingRequest(location: location) else {
        return createErrorOutput(error: LocationError.reverseGeocodingFailed)
      }
      let mapItems = try await request.mapItems
      
      guard let mapItem = mapItems.first else {
        return createErrorOutput(error: LocationError.reverseGeocodingFailed)
      }
      
      let address = formatAddress(mapItem: mapItem)
      
      return ToolOutput(
        GeneratedContent(properties: [
          "status": "success",
          "latitude": latitude,
          "longitude": longitude,
          "address": address,
          "country": "",  // These would need to be extracted from addressRepresentations
          "state": "",
          "city": "",
          "street": "",
          "postalCode": "",
          "message": "Address: \(address)"
        ])
      )
    } catch {
      return createErrorOutput(error: error)
    }
  }
  
  private func searchPlaces(query: String?, radius: Double?) async -> ToolOutput {
    guard let query = query, !query.isEmpty else {
      return createErrorOutput(error: LocationError.missingSearchQuery)
    }
    
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = query
    
    // Set search region if we have current location
    if let location = locationManager.location {
      let searchRadius = radius ?? 1000 // Default 1km
      request.region = MKCoordinateRegion(
        center: location.coordinate,
        latitudinalMeters: searchRadius * 2,
        longitudinalMeters: searchRadius * 2
      )
    }
    
    let search = MKLocalSearch(request: request)
    
    do {
      let response = try await search.start()
      
      var placesDescription = ""
      
      for (index, item) in response.mapItems.prefix(10).enumerated() {
        let distance: String
        if let userLocation = locationManager.location {
          let placeLocation = CLLocation(
            latitude: item.location.coordinate.latitude,
            longitude: item.location.coordinate.longitude
          )
          let meters = userLocation.distance(from: placeLocation)
          distance = formatDistance(meters)
        } else {
          distance = "Unknown distance"
        }
        
        placesDescription += "\(index + 1). \(item.name ?? "Unknown Place")\n"
        if let address = formatMapItemAddress(item) {
          placesDescription += "   Address: \(address)\n"
        }
        placesDescription += "   Distance: \(distance)\n"
        if let phone = item.phoneNumber {
          placesDescription += "   Phone: \(phone)\n"
        }
        placesDescription += "\n"
      }
      
      if placesDescription.isEmpty {
        placesDescription = "No places found matching '\(query)'"
      }
      
      return ToolOutput(
        GeneratedContent(properties: [
          "status": "success",
          "query": query,
          "resultCount": response.mapItems.count,
          "places": placesDescription.trimmingCharacters(in: .whitespacesAndNewlines),
          "message": "Found \(response.mapItems.count) place(s)"
        ])
      )
    } catch {
      return createErrorOutput(error: error)
    }
  }
  
  private func calculateDistance(arguments: Arguments) -> ToolOutput {
    guard let lat1 = arguments.latitude,
          let lon1 = arguments.longitude,
          let lat2 = arguments.latitude2,
          let lon2 = arguments.longitude2 else {
      return createErrorOutput(error: LocationError.missingCoordinates)
    }
    
    let location1 = CLLocation(latitude: lat1, longitude: lon1)
    let location2 = CLLocation(latitude: lat2, longitude: lon2)
    
    let distance = location1.distance(from: location2)
    
    // Calculate bearing
    let bearing = calculateBearing(from: location1, to: location2)
    let direction = compassDirection(from: bearing)
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "location1_latitude": lat1,
        "location1_longitude": lon1,
        "location2_latitude": lat2,
        "location2_longitude": lon2,
        "distanceMeters": distance,
        "distanceKilometers": distance / 1000,
        "distanceMiles": distance / 1609.344,
        "formattedDistance": formatDistance(distance),
        "bearing": bearing,
        "direction": direction,
        "message": "Distance: \(formatDistance(distance)) \(direction)"
      ])
    )
  }
  
  private func formatAddress(mapItem: MKMapItem?) -> String {
    guard let mapItem = mapItem else { return "Unknown location" }
    
    // Use name if available
    if let name = mapItem.name {
      return name
    }
    
    // Fallback to coordinates
    let location = mapItem.location
    return "Lat: \(location.coordinate.latitude), Lon: \(location.coordinate.longitude)"
  }
  
  private func formatDistance(_ meters: Double) -> String {
    if meters < 1000 {
      return String(format: "%.0f meters", meters)
    } else if meters < 10000 {
      return String(format: "%.1f km", meters / 1000)
    } else {
      return String(format: "%.0f km", meters / 1000)
    }
  }
  
  private func calculateBearing(from: CLLocation, to: CLLocation) -> Double {
    let lat1 = from.coordinate.latitude.degreesToRadians
    let lon1 = from.coordinate.longitude.degreesToRadians
    let lat2 = to.coordinate.latitude.degreesToRadians
    let lon2 = to.coordinate.longitude.degreesToRadians
    
    let dLon = lon2 - lon1
    
    let y = sin(dLon) * cos(lat2)
    let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
    
    let radiansBearing = atan2(y, x)
    let degreesBearing = radiansBearing.radiansToDegrees
    
    return (degreesBearing + 360).truncatingRemainder(dividingBy: 360)
  }
  
  private func compassDirection(from bearing: Double) -> String {
    let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                     "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    let index = Int((bearing + 11.25) / 22.5) % 16
    return directions[index]
  }
  
  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .medium
    return formatter.string(from: date)
  }
  
  private func requestLocationPermission() async -> ToolOutput {
    // Create a location delegate to handle authorization changes
    let delegate = LocationDelegate()
    locationManager.delegate = delegate
    
    // Request permission
    #if os(macOS)
    // On macOS, just start monitoring which will trigger permission dialog
    locationManager.startUpdatingLocation()
    locationManager.stopUpdatingLocation()
    #else
    locationManager.requestWhenInUseAuthorization()
    #endif
    
    // Return informative message
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "permission_requested",
        "message": "Location permission requested. Please allow location access in the system alert and try again.",
        "instruction": "After granting permission, please run this tool again to get your location."
      ])
    )
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

// Helper function to format map item address
private func formatMapItemAddress(_ mapItem: MKMapItem) -> String? {
  return mapItem.name
}

extension Double {
  var degreesToRadians: Double { self * .pi / 180 }
  var radiansToDegrees: Double { self * 180 / .pi }
}

enum LocationError: Error, LocalizedError {
  case invalidAction
  case authorizationDenied
  case authorizationNotDetermined
  case locationUnavailable
  case missingAddress
  case missingCoordinates
  case missingSearchQuery
  case geocodingFailed
  case reverseGeocodingFailed
  
  var errorDescription: String? {
    switch self {
    case .invalidAction:
      return "Invalid action. Use 'current', 'geocode', 'reverse', 'search', or 'distance'."
    case .authorizationDenied:
      return "Location access denied. Please grant permission in Settings."
    case .authorizationNotDetermined:
      return "Location permission not yet determined. Please grant permission when prompted."
    case .locationUnavailable:
      return "Current location is unavailable."
    case .missingAddress:
      return "Address is required for geocoding."
    case .missingCoordinates:
      return "Latitude and longitude are required."
    case .missingSearchQuery:
      return "Search query is required."
    case .geocodingFailed:
      return "Failed to find location for the given address."
    case .reverseGeocodingFailed:
      return "Failed to find address for the given coordinates."
    }
  }
}

// Location delegate to handle authorization changes
class LocationDelegate: NSObject, CLLocationManagerDelegate {
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    // This will be called when authorization status changes
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    // Required delegate method for requestLocation()
    // We don't need to do anything here as we're just requesting permission
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    // Handle location errors
    print("Location error: \(error.localizedDescription)")
  }
}

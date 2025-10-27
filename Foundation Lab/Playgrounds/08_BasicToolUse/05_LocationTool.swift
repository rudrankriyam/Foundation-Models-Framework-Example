//
//  05_LocationTool.swift
//  Exploring Foundation Models
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationModels
import CoreLocation
import Playgrounds

struct MockLocationTool: Tool {
    let name = "getUserLocation"
    let description = "Gets the user's current location coordinates"

    @Generable
    struct Arguments {
        @Guide(description: "Whether to include city/country information")
        var includeAddress: Bool = false
    }

    @Generable
    struct LocationData {
        let latitude: Double
        let longitude: Double
        let city: String?
        let country: String?
        let timestamp: String
    }

    func call(arguments: Arguments) async throws -> LocationData {
        // In a real app, you'd use CLLocationManager
        // For demo purposes, return mock location data

        let mockLocations = [
            (latitude: 37.7749, longitude: -122.4194, city: "San Francisco", country: "US"),
            (latitude: 40.7128, longitude: -74.0060, city: "New York", country: "US"),
            (latitude: 51.5074, longitude: -0.1278, city: "London", country: "GB"),
            (latitude: 48.8566, longitude: 2.3522, city: "Paris", country: "FR")
        ]

        let randomLocation = mockLocations.randomElement()!

        return LocationData(
            latitude: randomLocation.latitude,
            longitude: randomLocation.longitude,
            city: arguments.includeAddress ? randomLocation.city : nil,
            country: arguments.includeAddress ? randomLocation.country : nil,
            timestamp: DateFormatter.todayString
        )
    }
}

#Playground {
    let locationTool = MockLocationTool()

    let arguments = MockLocationTool.Arguments(includeAddress: true)

    let result = try await locationTool.call(arguments: arguments)
    debugPrint("Location result: \(result)")
}

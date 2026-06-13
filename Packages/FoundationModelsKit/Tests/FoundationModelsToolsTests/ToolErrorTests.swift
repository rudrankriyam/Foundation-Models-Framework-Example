//
//  ToolErrorTests.swift
//  FoundationModelsToolsTests
//
//  Tests for tool-specific error types and their descriptions.
//

import Foundation
import Testing
@testable import FoundationModelsTools

@Suite("CalendarError Tests")
struct CalendarErrorTests {

  @Test("Access denied error has description")
  func accessDeniedDescription() {
    let error = CalendarError.accessDenied
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("denied"))
  }

  @Test("Invalid action error lists valid actions")
  func invalidActionListsValidActions() {
    let error = CalendarError.invalidAction
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("create"))
    #expect(error.errorDescription!.contains("query"))
    #expect(error.errorDescription!.contains("read"))
    #expect(error.errorDescription!.contains("update"))
  }

  @Test("Missing title error has description")
  func missingTitleDescription() {
    let error = CalendarError.missingTitle
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("Title"))
  }

  @Test("Invalid start date error includes format hint")
  func invalidStartDateIncludesFormat() {
    let error = CalendarError.invalidStartDate
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("YYYY-MM-DD"))
  }

  @Test("Event not found error has description")
  func eventNotFoundDescription() {
    let error = CalendarError.eventNotFound
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("not found"))
  }
}

@Suite("ContactsError Tests")
struct ContactsErrorTests {

  @Test("Access denied error has description")
  func accessDeniedDescription() {
    let error = ContactsError.accessDenied
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("denied"))
  }

  @Test("Invalid action error lists valid actions")
  func invalidActionListsValidActions() {
    let error = ContactsError.invalidAction
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("search"))
    #expect(error.errorDescription!.contains("read"))
    #expect(error.errorDescription!.contains("create"))
  }

  @Test("Missing query error has description")
  func missingQueryDescription() {
    let error = ContactsError.missingQuery
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("query"))
  }
}

@Suite("HealthError Tests")
struct HealthErrorTests {

  @Test("HealthKit not available error has description")
  func healthKitNotAvailableDescription() {
    let error = HealthError.healthKitNotAvailable
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("HealthKit"))
  }

  @Test("Invalid data type error lists valid types")
  func invalidDataTypeListsValidTypes() {
    let error = HealthError.invalidDataType
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("steps"))
    #expect(error.errorDescription!.contains("heartRate"))
    #expect(error.errorDescription!.contains("workouts"))
    #expect(error.errorDescription!.contains("sleep"))
    #expect(error.errorDescription!.contains("activeEnergy"))
    #expect(error.errorDescription!.contains("distance"))
  }

  @Test("No data error has description")
  func noDataDescription() {
    let error = HealthError.noData
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("No health data"))
  }
}

@Suite("LocationError Tests")
struct LocationErrorTests {

  @Test("Invalid action error lists valid actions")
  func invalidActionListsValidActions() {
    let error = LocationError.invalidAction
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("current"))
    #expect(error.errorDescription!.contains("geocode"))
    #expect(error.errorDescription!.contains("reverse"))
    #expect(error.errorDescription!.contains("search"))
    #expect(error.errorDescription!.contains("distance"))
  }

  @Test("Missing address error has description")
  func missingAddressDescription() {
    let error = LocationError.missingAddress
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("Address"))
  }

  @Test("Location timeout error has description")
  func locationTimeoutDescription() {
    let error = LocationError.locationTimeout
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("Timed out"))
  }
}

@Suite("MusicError Tests")
struct MusicErrorTests {

  @Test("Invalid action error lists valid actions")
  func invalidActionListsValidActions() {
    let error = MusicError.invalidAction
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("search"))
    #expect(error.errorDescription!.contains("play"))
    #expect(error.errorDescription!.contains("pause"))
    #expect(error.errorDescription!.contains("stop"))
    #expect(error.errorDescription!.contains("skip"))
    #expect(error.errorDescription!.contains("previous"))
    #expect(error.errorDescription!.contains("nowPlaying"))
  }

  @Test("Missing query error has description")
  func missingQueryDescription() {
    let error = MusicError.missingQuery
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("query"))
  }

  @Test("Item not found error has description")
  func itemNotFoundDescription() {
    let error = MusicError.itemNotFound
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("not found"))
  }
}

@Suite("RemindersError Tests")
struct RemindersErrorTests {

  @Test("Access denied error has description")
  func accessDeniedDescription() {
    let error = RemindersError.accessDenied
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("denied"))
  }

  @Test("Invalid action error lists valid actions")
  func invalidActionListsValidActions() {
    let error = RemindersError.invalidAction
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("create"))
    #expect(error.errorDescription!.contains("query"))
    #expect(error.errorDescription!.contains("complete"))
    #expect(error.errorDescription!.contains("update"))
    #expect(error.errorDescription!.contains("delete"))
  }

  @Test("Missing title error has description")
  func missingTitleDescription() {
    let error = RemindersError.missingTitle
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("Title"))
  }
}

@Suite("WeatherError Tests")
struct WeatherErrorTests {

  @Test("Location not found error has description")
  func locationNotFoundDescription() {
    let error = WeatherError.locationNotFound
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("location"))
  }

  @Test("Invalid URL error has description")
  func invalidURLDescription() {
    let error = WeatherError.invalidURL
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("URL"))
  }

  @Test("API error has description")
  func apiErrorDescription() {
    let error = WeatherError.apiError
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("API"))
  }
}

@Suite("WebMetadataError Tests")
struct WebMetadataErrorTests {

  @Test("Empty URL error has description")
  func emptyURLDescription() {
    let error = WebMetadataError.emptyURL
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("empty"))
  }

  @Test("Invalid URL error has description")
  func invalidURLDescription() {
    let error = WebMetadataError.invalidURL
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("Invalid"))
  }

  @Test("Fetch failed error includes underlying error")
  func fetchFailedIncludesUnderlyingError() {
    let underlyingError = NSError(domain: "TestDomain", code: 1, userInfo: [
      NSLocalizedDescriptionKey: "Connection failed"
    ])
    let error = WebMetadataError.fetchFailed(underlyingError)

    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("fetch"))
  }
}

@Suite("WebError Tests")
struct WebErrorTests {

  @Test("Empty query error has description")
  func emptyQueryDescription() {
    let error = WebError.emptyQuery
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("empty"))
  }

  @Test("Missing API key error has description")
  func missingAPIKeyDescription() {
    let error = WebError.missingAPIKey
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("API key"))
  }

  @Test("Network error includes underlying error")
  func networkErrorIncludesUnderlyingError() {
    let underlyingError = NSError(domain: "TestDomain", code: 1, userInfo: [
      NSLocalizedDescriptionKey: "Network unreachable"
    ])
    let error = WebError.networkError(underlyingError)

    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("Network"))
  }
}

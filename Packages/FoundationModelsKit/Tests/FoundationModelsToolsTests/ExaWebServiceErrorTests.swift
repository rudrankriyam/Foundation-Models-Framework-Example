//
//  ExaWebServiceErrorTests.swift
//  FoundationModelsToolsTests
//
//  Tests for ExaWebServiceError handling and error descriptions.
//

import Foundation
import Testing
@testable import FoundationModelsTools

@Suite("ExaWebServiceError Tests")
struct ExaWebServiceErrorTests {

  @Test("Invalid URL error has description")
  func invalidURLErrorDescription() {
    let error = ExaWebServiceError.invalidURL
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("URL"))
  }

  @Test("Missing API key error has description")
  func missingAPIKeyErrorDescription() {
    let error = ExaWebServiceError.missingAPIKey
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("API key"))
  }

  @Test("API error includes status code in description")
  func apiErrorIncludesStatusCode() {
    let error = ExaWebServiceError.apiError(statusCode: 401, responseData: nil)
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("401"))
  }

  @Test("API error includes response body when available")
  func apiErrorIncludesResponseBody() {
    let responseBody = "{\"error\": \"Invalid API key\"}"
    let responseData = responseBody.data(using: .utf8)
    let error = ExaWebServiceError.apiError(statusCode: 401, responseData: responseData)

    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("Invalid API key"))
  }

  @Test("API error handles nil response data")
  func apiErrorHandlesNilResponseData() {
    let error = ExaWebServiceError.apiError(statusCode: 500, responseData: nil)

    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("No response body"))
  }

  @Test("Encoding error includes underlying error")
  func encodingErrorIncludesUnderlyingError() {
    let underlyingError = NSError(domain: "TestDomain", code: 1, userInfo: [
      NSLocalizedDescriptionKey: "Test encoding failure"
    ])
    let error = ExaWebServiceError.encodingError(underlyingError)

    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("encode"))
  }

  @Test("Decoding error includes underlying error")
  func decodingErrorIncludesUnderlyingError() {
    let underlyingError = NSError(domain: "TestDomain", code: 2, userInfo: [
      NSLocalizedDescriptionKey: "Test decoding failure"
    ])
    let error = ExaWebServiceError.decodingError(underlyingError)

    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("decode"))
  }

  @Test("Invalid response error has description")
  func invalidResponseErrorDescription() {
    let error = ExaWebServiceError.invalidResponse
    #expect(error.errorDescription != nil)
    #expect(error.errorDescription!.contains("response"))
  }
}

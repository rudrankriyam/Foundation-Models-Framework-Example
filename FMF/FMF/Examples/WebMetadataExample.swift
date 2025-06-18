//
//  WebMetadataExample.swift
//  FMF
//
//  Created by Claude on 6/18/25.
//

import Foundation
import FoundationModels

// Example usage of WebMetadataTool
func demonstrateWebMetadataTool() async throws {
    // Create a session with the WebMetadataTool
    let session = LanguageModelSession(tools: [WebMetadataTool()])
    
    // Example 1: Generate a Twitter post
    print("🐦 Twitter Example:")
    let twitterResponse = try await session.respond(
        to: Prompt("Generate a Twitter post for https://www.apple.com/newsroom/")
    )
    print(twitterResponse.content)
    print("\n---\n")
    
    // Example 2: Generate a LinkedIn post
    print("💼 LinkedIn Example:")
    let linkedinResponse = try await session.respond(
        to: Prompt("Create a LinkedIn post for https://developer.apple.com/news/")
    )
    print(linkedinResponse.content)
    print("\n---\n")
    
    // Example 3: Generate a Facebook post
    print("📘 Facebook Example:")
    let facebookResponse = try await session.respond(
        to: Prompt("Make a Facebook post for https://www.apple.com/apple-intelligence/")
    )
    print(facebookResponse.content)
    print("\n---\n")
    
    // Example 4: General social media summary
    print("📱 General Social Media Example:")
    let generalResponse = try await session.respond(
        to: Prompt("Create a social media summary for https://www.apple.com/iphone/")
    )
    print(generalResponse.content)
}

// Advanced example with specific requirements
func advancedWebMetadataExample() async throws {
    let session = LanguageModelSession(tools: [WebMetadataTool()])
    
    // Request without hashtags
    print("📄 Summary without hashtags:")
    let noHashtagResponse = try await session.respond(
        to: Prompt("Generate a LinkedIn post for https://www.apple.com/mac/ without any hashtags")
    )
    print(noHashtagResponse.content)
}
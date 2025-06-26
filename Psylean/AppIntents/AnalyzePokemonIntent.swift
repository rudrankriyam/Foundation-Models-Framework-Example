//
//  AnalyzePokemonIntent.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import AppIntents
import SwiftUI
import FoundationModels

struct AnalyzePokemonIntent: AppIntent {
    static var title: LocalizedStringResource = "Analyze Pokemon"
    static var description = IntentDescription("Get detailed information about a Pokemon by name or description")
    static var openAppWhenRun: Bool = false
    static var isDiscoverable: Bool = true
    
    @Parameter(title: "Pokemon", description: "Enter a Pokemon name or description (e.g., 'Pikachu' or 'cute grass pokemon')")
    var pokemonQuery: String
    
    func perform() async throws -> some IntentResult & ShowsSnippetView & ProvidesDialog {
        // Validate input
        guard !pokemonQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw IntentError.emptyInput
        }
        
        // Sanitize input
        let sanitizedQuery = pokemonQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s-]", with: "", options: .regularExpression)
        
        guard sanitizedQuery.count >= 2 else {
            throw IntentError.inputTooShort
        }
        
        let analyzer = PokemonAnalyzer()
        
        // Try to fetch Pokemon info with retry logic
        var basicInfo: PokemonBasicInfo?
        var lastError: Error?
        
        for attempt in 1...3 {
            do {
                basicInfo = try await analyzer.getPokemonBasicInfoWithCache(sanitizedQuery)
                break // Success, exit retry loop
            } catch {
                lastError = error
                print("DEBUG: Attempt \(attempt) failed: \(error)")
                
                // Only retry for certain errors
                if error is LanguageModelSession.GenerationError || 
                   (error as? IntentError) == .contextWindowExceeded {
                    throw error // Don't retry these errors
                }
                
                // Wait before retrying (exponential backoff)
                if attempt < 3 {
                    try await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
                }
            }
        }
        
        guard let basicInfo = basicInfo else {
            throw lastError ?? IntentError.analysisError("Failed to fetch Pokemon data after 3 attempts")
        }
        
        let name = basicInfo.name
        let number = basicInfo.number
        let types = basicInfo.types
        
        // Debug logging
        print("DEBUG: Pokemon basic info - Name: \(name), Number: \(number), Types: \(types)")
        
        // Validate results
        guard number > 0 && number <= 1025 else { // Current max Pokedex number
            print("DEBUG: Invalid Pokemon number: \(number)")
            throw IntentError.invalidPokemonData
        }
        
        // Download image with caching and retry logic
        let imageData: Data? = await getCachedOrDownloadImage(for: number)
        
        let snippetView = PokemonSnippetView(
            name: name,
            number: number,
            types: types,
            description: basicInfo.description,
            imageData: imageData
        )
        
        return .result(dialog: IntentDialog("Found \(name)!"), view: snippetView)
    }
    
    private func getCachedOrDownloadImage(for pokemonNumber: Int) async -> Data? {
        // Check cache first
        if let cachedImage = await PokemonCache.shared.getCachedImage(for: pokemonNumber) {
            return cachedImage
        }
        
        // Download if not cached
        let imageURL = URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/\(pokemonNumber).png")!
        
        if let imageData = await downloadImageWithRetry(from: imageURL, maxRetries: 3) {
            // Cache the downloaded image
            await PokemonCache.shared.cacheImage(imageData, for: pokemonNumber)
            return imageData
        }
        
        return nil
    }
    
    private func downloadImageWithRetry(from url: URL, maxRetries: Int) async -> Data? {
        for attempt in 1...maxRetries {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                // Check if we got a valid response
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    print("DEBUG: Successfully downloaded image: \(data.count) bytes")
                    return data
                }
                
                print("DEBUG: Invalid response status for image download")
            } catch {
                print("DEBUG: Image download attempt \(attempt) failed: \(error)")
                
                // Wait before retrying (exponential backoff)
                if attempt < maxRetries {
                    try? await Task.sleep(nanoseconds: UInt64(attempt) * 500_000_000) // 0.5s, 1s, 1.5s
                }
            }
        }
        
        print("DEBUG: Failed to download image after \(maxRetries) attempts")
        return nil
    }
}

enum IntentError: LocalizedError, Equatable {
    case emptyInput
    case inputTooShort
    case noAnalysisAvailable
    case incompleteAnalysis
    case invalidPokemonData
    case contextWindowExceeded
    case analysisError(String)
    
    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Please enter a Pokemon name or description"
        case .inputTooShort:
            return "Input too short. Please enter at least 2 characters"
        case .noAnalysisAvailable:
            return "No Pokemon analysis was generated"
        case .incompleteAnalysis:
            return "Pokemon analysis is incomplete. Please try again"
        case .invalidPokemonData:
            return "Invalid Pokemon data received. Please try again"
        case .contextWindowExceeded:
            return "Request too complex. Please try a simpler query"
        case .analysisError(let message):
            return "Analysis failed: \(message)"
        }
    }
}
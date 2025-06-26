//
//  PokemonCache.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import Foundation

/// Cache manager for Pokemon data and images
actor PokemonCache {
    static let shared = PokemonCache()
    
    private var pokemonDataCache: [String: CachedPokemonData] = [:]
    private var imageCache: [Int: Data] = [:]
    
    let cacheExpirationTime: TimeInterval = 3600 // 1 hour
    private let maxCacheSize = 50 // Maximum number of Pokemon to cache
    private let maxImageCacheSize = 100 // Maximum number of images to cache
    
    private init() {}
    
    // MARK: - Pokemon Data Caching
    
    func getCachedPokemonData(for query: String) -> PokemonBasicInfo? {
        let key = query.lowercased()
        guard let cached = pokemonDataCache[key],
              !cached.isExpired else {
            return nil
        }
        
        print("DEBUG: Cache hit for Pokemon query: \(query)")
        return cached.data
    }
    
    func cachePokemonData(_ data: PokemonBasicInfo, for query: String) {
        let key = query.lowercased()
        pokemonDataCache[key] = CachedPokemonData(data: data, timestamp: Date(), expirationTime: cacheExpirationTime)
        
        // Cleanup old entries if cache is too large
        if pokemonDataCache.count > maxCacheSize {
            cleanupOldestEntries()
        }
        
        print("DEBUG: Cached Pokemon data for query: \(query)")
    }
    
    // MARK: - Image Caching
    
    func getCachedImage(for pokemonNumber: Int) -> Data? {
        guard let imageData = imageCache[pokemonNumber] else {
            return nil
        }
        
        print("DEBUG: Cache hit for Pokemon image #\(pokemonNumber)")
        return imageData
    }
    
    func cacheImage(_ data: Data, for pokemonNumber: Int) {
        imageCache[pokemonNumber] = data
        
        // Cleanup if image cache is too large
        if imageCache.count > maxImageCacheSize {
            cleanupOldestImages()
        }
        
        print("DEBUG: Cached image for Pokemon #\(pokemonNumber) (\(data.count) bytes)")
    }
    
    // MARK: - Cache Management
    
    func clearCache() {
        pokemonDataCache.removeAll()
        imageCache.removeAll()
        print("DEBUG: Cleared all cache")
    }
    
    func clearExpiredCache() {
        pokemonDataCache = pokemonDataCache.filter { !$0.value.isExpired }
        print("DEBUG: Cleared expired cache entries")
    }
    
    private func cleanupOldestEntries() {
        let sortedEntries = pokemonDataCache.sorted { $0.value.timestamp < $1.value.timestamp }
        let entriesToRemove = sortedEntries.prefix(10) // Remove 10 oldest entries
        
        for entry in entriesToRemove {
            pokemonDataCache.removeValue(forKey: entry.key)
        }
    }
    
    private func cleanupOldestImages() {
        // Remove 20 images at random (simple strategy)
        let keysToRemove = Array(imageCache.keys.shuffled().prefix(20))
        for key in keysToRemove {
            imageCache.removeValue(forKey: key)
        }
    }
}

// MARK: - Supporting Types

private struct CachedPokemonData {
    let data: PokemonBasicInfo
    let timestamp: Date
    let expirationTime: TimeInterval
    
    init(data: PokemonBasicInfo, timestamp: Date, expirationTime: TimeInterval = 3600) {
        self.data = data
        self.timestamp = timestamp
        self.expirationTime = expirationTime
    }
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > expirationTime
    }
}

// MARK: - Cache-aware extensions

extension PokemonAnalyzer {
    /// Get Pokemon basic info with caching
    func getPokemonBasicInfoWithCache(_ identifier: String) async throws -> PokemonBasicInfo {
        // Check cache first
        if let cached = await PokemonCache.shared.getCachedPokemonData(for: identifier) {
            return cached
        }
        
        // Fetch from API
        let result = try await getPokemonBasicInfo(identifier)
        
        // Cache the result
        await PokemonCache.shared.cachePokemonData(result, for: identifier)
        
        return result
    }
}
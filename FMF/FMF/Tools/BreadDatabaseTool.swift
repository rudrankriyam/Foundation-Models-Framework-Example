//
//  BreadDatabaseTool.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//

import Foundation
import FoundationModels

/// A tool that searches a local database for bread recipes
struct BreadDatabaseTool: Tool {
  let name = "searchBreadDatabase"
  let description = "Searches a local database for bread recipes."

  @Generable
  struct Arguments {
    @Guide(description: "The type of bread to search for")
    var searchTerm: String

    @Guide(description: "The number of recipes to get", .range(1...10))
    var limit: Int
  }

  struct Recipe {
    let name: String
    let description: String
    let difficulty: String
    let prepTime: String
    let bakeTime: String
    let ingredients: [String]
    let link: URL
    let tags: [String]
  }

  private let recipeDatabase: [Recipe] = [
    Recipe(
      name: "Classic Sourdough",
      description: "A tangy, crusty sourdough bread with a chewy interior and perfect crust",
      difficulty: "Intermediate",
      prepTime: "30 minutes (plus 24-48 hours fermentation)",
      bakeTime: "45 minutes",
      ingredients: ["Sourdough starter", "Bread flour", "Water", "Salt"],
      link: URL(string: "https://example.com/sourdough1")!,
      tags: ["sourdough", "artisan", "fermented"]
    ),
    Recipe(
      name: "San Francisco Sourdough",
      description: "Traditional SF-style sourdough with wild yeast starter and signature tang",
      difficulty: "Advanced",
      prepTime: "45 minutes (plus 48-72 hours fermentation)",
      bakeTime: "50 minutes",
      ingredients: ["Wild yeast starter", "High-gluten flour", "Water", "Sea salt"],
      link: URL(string: "https://example.com/sourdough2")!,
      tags: ["sourdough", "traditional", "wild yeast"]
    ),
    Recipe(
      name: "Whole Wheat Sourdough",
      description: "Healthy sourdough made with whole wheat flour and ancient grains",
      difficulty: "Intermediate",
      prepTime: "40 minutes (plus 24 hours fermentation)",
      bakeTime: "40 minutes",
      ingredients: ["Whole wheat flour", "Sourdough starter", "Water", "Salt", "Honey"],
      link: URL(string: "https://example.com/sourdough3")!,
      tags: ["sourdough", "whole wheat", "healthy"]
    ),
    Recipe(
      name: "Rye Sourdough",
      description: "Dense, flavorful sourdough with rye flour and caraway seeds",
      difficulty: "Intermediate",
      prepTime: "35 minutes (plus 36 hours fermentation)",
      bakeTime: "55 minutes",
      ingredients: ["Rye flour", "Bread flour", "Sourdough starter", "Caraway seeds", "Salt"],
      link: URL(string: "https://example.com/sourdough4")!,
      tags: ["sourdough", "rye", "european"]
    ),
    Recipe(
      name: "Japanese Milk Bread",
      description: "Soft, pillowy Japanese-style milk bread with tangzhong method",
      difficulty: "Beginner",
      prepTime: "25 minutes (plus 3 hours rising)",
      bakeTime: "30 minutes",
      ingredients: ["Bread flour", "Milk", "Sugar", "Butter", "Yeast", "Salt"],
      link: URL(string: "https://example.com/milkbread")!,
      tags: ["milk bread", "japanese", "soft", "sweet"]
    ),
    Recipe(
      name: "French Baguette",
      description: "Classic French baguette with crispy crust and airy crumb",
      difficulty: "Advanced",
      prepTime: "20 minutes (plus 18 hours fermentation)",
      bakeTime: "25 minutes",
      ingredients: ["Bread flour", "Water", "Salt", "Yeast"],
      link: URL(string: "https://example.com/baguette")!,
      tags: ["french", "baguette", "artisan", "crispy"]
    ),
    Recipe(
      name: "Focaccia",
      description: "Italian flatbread with herbs, olive oil, and sea salt",
      difficulty: "Beginner",
      prepTime: "15 minutes (plus 2 hours rising)",
      bakeTime: "20 minutes",
      ingredients: ["Bread flour", "Olive oil", "Water", "Salt", "Yeast", "Rosemary"],
      link: URL(string: "https://example.com/focaccia")!,
      tags: ["italian", "flatbread", "herbs", "olive oil"]
    ),
    Recipe(
      name: "Pumpernickel",
      description: "Dark German rye bread with molasses and coffee",
      difficulty: "Advanced",
      prepTime: "45 minutes (plus 24 hours fermentation)",
      bakeTime: "3 hours",
      ingredients: ["Dark rye flour", "Molasses", "Coffee", "Caraway seeds", "Salt"],
      link: URL(string: "https://example.com/pumpernickel")!,
      tags: ["german", "rye", "dark", "molasses"]
    ),
  ]

  func call(arguments: Arguments) async throws -> ToolOutput {
    // Simulate database query delay
    try await Task.sleep(for: .milliseconds(300))

    let searchTerm = arguments.searchTerm.lowercased().trimmingCharacters(
      in: .whitespacesAndNewlines)

    // Enhanced search: check name, description, and tags
    let filteredRecipes = recipeDatabase.filter { recipe in
      recipe.name.lowercased().contains(searchTerm)
        || recipe.description.lowercased().contains(searchTerm)
        || recipe.tags.contains { $0.lowercased().contains(searchTerm) }
    }

    // Sort by relevance (exact name matches first)
    let sortedRecipes = filteredRecipes.sorted { recipe1, recipe2 in
      let name1ContainsExact = recipe1.name.lowercased().contains(searchTerm)
      let name2ContainsExact = recipe2.name.lowercased().contains(searchTerm)

      if name1ContainsExact && !name2ContainsExact { return true }
      if !name1ContainsExact && name2ContainsExact { return false }

      return recipe1.name < recipe2.name
    }

    // Limit results
    let recipes = Array(sortedRecipes.prefix(arguments.limit))

    if recipes.isEmpty {
      return ToolOutput(
        GeneratedContent(properties: [
          "message": "No recipes found for '\(arguments.searchTerm)'",
          "suggestions": ["sourdough", "milk bread", "baguette", "focaccia"],
        ]))
    }

    let formattedRecipes = recipes.map { recipe in
      """
      **\(recipe.name)** (\(recipe.difficulty))
      \(recipe.description)
      Prep: \(recipe.prepTime) | Bake: \(recipe.bakeTime)
      Tags: \(recipe.tags.joined(separator: ", "))
      Link: \(recipe.link)
      """
    }

    return ToolOutput(
      GeneratedContent(properties: [
        "recipes": formattedRecipes,
        "total_found": filteredRecipes.count,
        "showing": recipes.count,
      ]))
  }
}

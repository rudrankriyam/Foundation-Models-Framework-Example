//
//  DataModels.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//

import Foundation
import FoundationModels

// MARK: - Book Recommendation Models

@Generable
struct BookRecommendation {
  @Guide(description: "The title of the book")
  let title: String

  @Guide(description: "The author's name")
  let author: String

  @Guide(description: "A brief description in 2-3 sentences")
  let description: String

  @Guide(description: "Genre of the book")
  let genre: Genre
}

@Generable
enum Genre {
  case fiction
  case nonFiction
  case mystery
  case romance
  case sciFi
  case fantasy
  case biography
  case history
}

// MARK: - Product Review Models

@Generable
struct ProductReview {
  @Guide(description: "Product name")
  let productName: String

  @Guide(description: "Rating from 1 to 5")
  let rating: Int

  @Guide(description: "Review text between 50-200 words")
  let reviewText: String

  @Guide(description: "Would recommend this product")
  let recommendation: String

  @Guide(description: "Key pros of the product")
  let pros: [String]

  @Guide(description: "Key cons of the product")
  let cons: [String]
}

// MARK: - Creative Writing Models

@Generable
struct StoryOutline {
  @Guide(description: "The title of the story")
  let title: String

  @Guide(description: "Main character name and brief description")
  let protagonist: String

  @Guide(description: "The central conflict or challenge")
  let conflict: String

  @Guide(description: "The setting where the story takes place")
  let setting: String

  @Guide(description: "Story genre")
  let genre: StoryGenre
  
  @Guide(description: "Major themes explored in the story")
  let themes: [String]
}

@Generable
enum StoryGenre {
  case adventure
  case mystery
  case romance
  case thriller
  case fantasy
  case sciFi
  case horror
  case comedy
}

// MARK: - Business Models

@Generable
struct BusinessIdea {
  @Guide(description: "Name of the business")
  let name: String

  @Guide(description: "Brief description of what the business does")
  let description: String

  @Guide(description: "Target market or customer base")
  let targetMarket: String

  @Guide(description: "Primary revenue model")
  let revenueModel: String

  @Guide(description: "Key advantages or unique selling points")
  let advantages: [String]

  @Guide(description: "Initial startup costs estimate")
  let estimatedStartupCost: String

  @Guide(description: "Expected timeline or phases for launch and growth")
  let timeline: String?
}

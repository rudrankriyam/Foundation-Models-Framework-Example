//
//  DefaultPrompts.swift
//  FoundationLab
//
//  Created by Claude on 1/29/25.
//

import Foundation

/// Default prompts for each example type
enum DefaultPrompts {
  
  // MARK: - Basic Examples
  
  static let basicChat = "Suggest a catchy name for a new coffee shop."
  
  static let basicChatSuggestions = [
    "Tell me a joke about programming",
    "Explain quantum computing in simple terms",
    "What are the benefits of meditation?",
    "Write a haiku about artificial intelligence",
    "Give me 5 creative pizza topping combinations"
  ]
  
  // MARK: - Structured Data
  
  static let structuredData = "Suggest a sci-fi book."
  
  static let structuredDataSuggestions = [
    "Recommend a mystery novel",
    "Suggest a fantasy book for beginners",
    "What's a good historical fiction book?",
    "Recommend a book about space exploration",
    "Suggest a classic literature book"
  ]
  
  // MARK: - Generation Guides
  
  static let generationGuides = "Write a product review for a smartphone."
  
  static let generationGuidesSuggestions = [
    "Review a laptop for students",
    "Write a review for wireless headphones",
    "Review a fitness tracker",
    "Write a review for a coffee maker",
    "Review a streaming service"
  ]
  
  // MARK: - Streaming
  
  static let streaming = "Write a haiku about the changing seasons."
  
  static let streamingSuggestions = [
    "Write a short poem about technology",
    "Create a limerick about coding",
    "Write a sonnet about nature",
    "Compose a haiku about morning coffee",
    "Write a free verse poem about dreams"
  ]
  
  // MARK: - Business Ideas
  
  static let businessIdeas = "Generate an innovative startup idea in the health tech industry."
  
  static let businessIdeasSuggestions = [
    "Create a business idea for sustainable fashion",
    "Generate a fintech startup concept",
    "Suggest an edtech business idea",
    "Create a food tech startup idea",
    "Generate a green energy business concept"
  ]
  
  // MARK: - Creative Writing
  
  static let creativeWriting = "Write a story outline about time travel."
  
  static let creativeWritingSuggestions = [
    "Create a mystery story outline",
    "Write a sci-fi story concept",
    "Outline a romantic comedy plot",
    "Create a thriller story outline",
    "Write a fantasy adventure concept"
  ]
  
  // MARK: - Model Availability
  
  static let modelAvailability = "Check if Apple Intelligence is available on this device."
  
  // MARK: - Instructions
  
  static let basicChatInstructions = "You are a helpful and creative assistant. Provide clear, concise, and engaging responses."
  
  static let creativeWritingInstructions = "You are a creative writing assistant. Help users develop compelling stories, characters, and narratives."
  
  static let businessIdeasInstructions = "You are a business strategy consultant. Generate innovative, practical, and market-viable business ideas."
  
  // Model Availability
  static let modelAvailabilitySuggestions = [
    "Check if Apple Intelligence is available",
    "Show me the current model status",
    "What AI capabilities are enabled?"
  ]
}

// MARK: - Code Examples

extension DefaultPrompts {
  static let basicChatCode = """
import FoundationModels

// Create a language model session
let session = LanguageModelSession()

// Generate a response with optional instructions
let response = try await session.generate(
    with: prompt,
    instructions: instructions,
    using: .conversational
)

print(response)
"""
  
  static let structuredDataCode = """
import FoundationModels

// Define your data structure
@Generable
struct Book {
    let title: String
    let author: String
    let genre: String
    let yearPublished: Int
    let summary: String
}

// Generate structured data
let session = LanguageModelSession()
let book = try await session.generate(
    prompt: prompt,
    as: Book.self
)

print("Title: \\(book.title)")
print("Author: \\(book.author)")
"""
  
  static let generationGuidesCode = """
import FoundationModels

@Generable
struct ProductReview {
    @Guidance("Keep under 50 words") 
    let reviewText: String
    
    @Guidance("Format as bullet points") 
    let features: [String]
    
    @Guidance("Range 1-5") 
    let rating: Int
}

let session = LanguageModelSession()
let review = try await session.generate(
    prompt: prompt,
    as: ProductReview.self
)
"""
  
  static let streamingResponseCode = """
import FoundationModels

let session = LanguageModelSession()

// Stream the response token by token
for try await token in session.generateStream(
    with: prompt,
    using: .conversational
) {
    print(token, terminator: "")
}
"""
  
  static let businessIdeasCode = """
import FoundationModels

@Generable
struct BusinessIdea {
    let name: String
    let description: String
    let targetMarket: String
    let advantages: [String]
    let challenges: [String]
    let estimatedCost: String
}

let session = LanguageModelSession()
let idea = try await session.generate(
    prompt: prompt,
    as: BusinessIdea.self
)
"""
  
  static let creativeWritingCode = """
import FoundationModels

@Generable
struct StoryOutline {
    let title: String
    let genre: String
    let protagonist: String
    let antagonist: String?
    let setting: String
    let conflict: String
    let chapters: [Chapter]
}

@Generable
struct Chapter {
    let number: Int
    let title: String
    let summary: String
}

let session = LanguageModelSession()
let story = try await session.generate(
    prompt: prompt,
    as: StoryOutline.self
)
"""
  
  static let modelAvailabilityCode = """
import FoundationModels

// Check Apple Intelligence availability
let availability = SystemLanguageModel.default.availability

switch availability {
case .available:
    print("Apple Intelligence is available!")
case .notAvailable(let reason):
    print("Not available: \\(reason)")
@unknown default:
    print("Unknown availability status")
}
"""
}
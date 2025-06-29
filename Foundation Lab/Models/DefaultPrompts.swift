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
}
//
//  DefaultPrompts.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
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
  
  static let structuredDataInstructions = "You are a helpful assistant that provides well-structured data in the requested format. Be accurate and comprehensive."
  
  static let generationGuidesInstructions = "You are a product review expert. Write detailed, balanced, and informative reviews that help consumers make informed decisions."
  
  static let streamingInstructions = "You are a creative poet and writer. Craft beautiful, meaningful verses that capture emotions and imagery."
  
  // Model Availability
  static let modelAvailabilitySuggestions = [
    "Check if Apple Intelligence is available",
    "Show me the current model status",
    "What AI capabilities are enabled?"
  ]
}

// MARK: - Dynamic Code Examples

extension DefaultPrompts {
  static func basicChatCode(prompt: String, instructions: String? = nil) -> String {
    var code = "import FoundationModels\n\n"
    
    if let instructions = instructions, !instructions.isEmpty {
      code += "// Create a session with custom instructions\n"
      code += "let session = LanguageModelSession(\n"
      code += "    instructions: Instructions(\"\(instructions)\")\n"
      code += ")\n"
    } else {
      code += "// Create a basic language model session\n"
      code += "let session = LanguageModelSession()\n"
    }
    
    code += "\n// Generate a response\n"
    code += "let response = try await session.respond(to: \"\(prompt)\")\n"
    code += "print(response.content)"
    
    return code
  }
  
  static func structuredDataCode(prompt: String, instructions: String? = nil) -> String {
    var code = "import FoundationModels\n\n"
    code += "// Uses BookRecommendation struct from DataModels.swift\n"
    code += "// Generate structured data\n"
    
    if let instructions = instructions, !instructions.isEmpty {
      code += "let session = LanguageModelSession(\n"
      code += "    instructions: Instructions(\"\(instructions)\")\n"
      code += ")\n\n"
    } else {
      code += "let session = LanguageModelSession()\n\n"
    }
    
    code += "let response = try await session.respond(\n"
    code += "    to: \"\(prompt)\",\n"
    code += "    generating: BookRecommendation.self\n"
    code += ")\n\n"
    code += "let book = response.content\n"
    code += "print(\"Title: \\(book.title)\")\n"
    code += "print(\"Author: \\(book.author)\")\n"
    code += "print(\"Genre: \\(book.genre)\")\n"
    code += "print(\"Description: \\(book.description)\")"
    
    return code
  }
  
  static func generationGuidesCode(prompt: String, instructions: String? = nil) -> String {
    var code = "import FoundationModels\n\n"
    code += "// Uses ProductReview struct from DataModels.swift\n"
    
    if let instructions = instructions, !instructions.isEmpty {
      code += "let session = LanguageModelSession(\n"
      code += "    instructions: Instructions(\"\(instructions)\")\n"
      code += ")\n\n"
    } else {
      code += "let session = LanguageModelSession()\n\n"
    }
    
    code += "let response = try await session.respond(\n"
    code += "    to: \"\(prompt)\",\n"
    code += "    generating: ProductReview.self\n"
    code += ")\n\n"
    code += "let review = response.content\n"
    code += "print(\"Product: \\(review.productName)\")\n"
    code += "print(\"Rating: \\(review.rating)/5\")\n"
    code += "print(\"Recommendation: \\(review.recommendation)\")\n"
    code += "print(\"Pros: \\(review.pros.joined(separator: \", \"))\")\n"
    code += "print(\"Cons: \\(review.cons.joined(separator: \", \"))\")"
    
    return code
  }
  
  static func streamingResponseCode(prompt: String, instructions: String? = nil) -> String {
    var code = "import FoundationModels\n\n"
    
    if let instructions = instructions, !instructions.isEmpty {
      code += "let session = LanguageModelSession(\n"
      code += "    instructions: Instructions(\"\(instructions)\")\n"
      code += ")\n\n"
    } else {
      code += "let session = LanguageModelSession()\n\n"
    }
    
    code += "// Stream the response token by token\n"
    code += "let stream = session.streamResponse(to: \"\(prompt)\")\n"
    code += "for try await partialResponse in stream {\n"
    code += "    print(partialResponse, terminator: \"\")\n"
    code += "}"
    
    return code
  }
  
  static func businessIdeasCode(prompt: String, instructions: String? = nil) -> String {
    var code = "import FoundationModels\n\n"
    code += "// Uses BusinessIdea struct from DataModels.swift\n"
    
    if let instructions = instructions, !instructions.isEmpty {
      code += "// Create session with business strategy instructions\n"
      code += "let session = LanguageModelSession(\n"
      code += "    instructions: Instructions(\"\(instructions)\")\n"
      code += ")\n\n"
    } else {
      code += "let session = LanguageModelSession()\n\n"
    }
    
    code += "let response = try await session.respond(\n"
    code += "    to: \"\(prompt)\",\n"
    code += "    generating: BusinessIdea.self\n"
    code += ")\n\n"
    code += "let idea = response.content\n"
    code += "print(\"Business: \\(idea.name)\")\n"
    code += "print(\"Revenue Model: \\(idea.revenueModel)\")\n"
    code += "print(\"Startup Cost: \\(idea.estimatedStartupCost)\")"
    
    return code
  }
  
  static func creativeWritingCode(prompt: String, instructions: String? = nil) -> String {
    var code = "import FoundationModels\n\n"
    code += "// Uses StoryOutline struct from DataModels.swift\n"
    
    if let instructions = instructions, !instructions.isEmpty {
      code += "// Create session with creative writing instructions\n"
      code += "let session = LanguageModelSession(\n"
      code += "    instructions: Instructions(\"\(instructions)\")\n"
      code += ")\n\n"
    } else {
      code += "let session = LanguageModelSession()\n\n"
    }
    
    code += "let response = try await session.respond(\n"
    code += "    to: \"\(prompt)\",\n"
    code += "    generating: StoryOutline.self\n"
    code += ")\n\n"
    code += "let story = response.content\n"
    code += "print(\"Title: \\(story.title)\")\n"
    code += "print(\"Genre: \\(story.genre)\")\n"
    code += "print(\"Themes: \\(story.themes.joined(separator: \", \"))\")"
    
    return code
  }
  
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
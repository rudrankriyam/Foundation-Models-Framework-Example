//
//  TextTool.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/17/25.
//

import Foundation
import FoundationModels

/// `TextTool` provides text manipulation and analysis functionality.
///
/// This tool can perform various text operations including formatting, analysis, and transformations.
struct TextTool: Tool {
  
  /// The name of the tool, used for identification.
  let name = "processText"
  /// A brief description of the tool's functionality.
  let description = "Manipulate, analyze, and transform text content"
  
  /// Arguments for text operations.
  @Generable
  struct Arguments {
    /// The operation to perform: "analyze", "transform", "format"
    @Guide(description: "The operation to perform: 'analyze', 'transform', 'format'")
    var operation: String
    
    /// The text to process
    @Guide(description: "The text to process")
    var text: String
    
    /// Type of transformation: "uppercase", "lowercase", "capitalize", "reverse", "removeSpaces"
    @Guide(description: "Type of transformation: 'uppercase', 'lowercase', 'capitalize', 'reverse', 'removeSpaces'")
    var transformType: String?
    
    /// Format type: "trim", "wrap", "truncate"
    @Guide(description: "Format type: 'trim', 'wrap', 'truncate'")
    var formatType: String?
    
    /// Maximum length for truncation or line width for wrapping
    @Guide(description: "Maximum length for truncation or line width for wrapping")
    var maxLength: Int?
  }
  
  func call(arguments: Arguments) async throws -> ToolOutput {
    let text = arguments.text
    
    switch arguments.operation.lowercased() {
    case "analyze":
      return analyzeText(text: text)
    case "transform":
      return transformText(text: text, transformType: arguments.transformType)
    case "format":
      return formatText(text: text, formatType: arguments.formatType, maxLength: arguments.maxLength)
    default:
      return createErrorOutput(error: TextError.invalidOperation)
    }
  }
  
  private func analyzeText(text: String) -> ToolOutput {
    let words = text.split(separator: " ").count
    let characters = text.count
    let charactersNoSpaces = text.replacingOccurrences(of: " ", with: "").count
    let lines = text.split(separator: "\n").count
    
    // Count sentences (simple approach)
    let sentenceEnders = CharacterSet(charactersIn: ".!?")
    let sentences = text.components(separatedBy: sentenceEnders)
      .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
      .count
    
    // Find most common words
    let wordArray = text.lowercased()
      .components(separatedBy: .alphanumerics.inverted)
      .filter { !$0.isEmpty }
    
    var wordFrequency: [String: Int] = [:]
    for word in wordArray {
      wordFrequency[word, default: 0] += 1
    }
    
    let topWords = wordFrequency.sorted { $0.value > $1.value }
      .prefix(5)
      .map { "\($0.key): \($0.value)" }
      .joined(separator: ", ")
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "wordCount": words,
        "characterCount": characters,
        "characterCountNoSpaces": charactersNoSpaces,
        "lineCount": lines,
        "sentenceCount": sentences,
        "averageWordLength": charactersNoSpaces / max(words, 1),
        "topWords": topWords,
        "isEmpty": text.isEmpty,
        "isAllUppercase": text == text.uppercased() && !text.isEmpty,
        "isAllLowercase": text == text.lowercased() && !text.isEmpty
      ])
    )
  }
  
  private func transformText(text: String, transformType: String?) -> ToolOutput {
    guard let type = transformType else {
      return createErrorOutput(error: TextError.missingTransformType)
    }
    
    let transformedText: String
    
    switch type.lowercased() {
    case "uppercase":
      transformedText = text.uppercased()
      
    case "lowercase":
      transformedText = text.lowercased()
      
    case "capitalize":
      transformedText = text.capitalized
      
    case "reverse":
      transformedText = String(text.reversed())
      
    case "removespaces":
      transformedText = text.replacingOccurrences(of: " ", with: "")
      
    case "camelcase":
      let words = text.lowercased().split(separator: " ")
      transformedText = words.enumerated().map { index, word in
        index == 0 ? String(word) : word.capitalized
      }.joined()
      
    case "snakecase":
      transformedText = text.lowercased()
        .replacingOccurrences(of: " ", with: "_")
        .replacingOccurrences(of: "-", with: "_")
      
    case "kebabcase":
      transformedText = text.lowercased()
        .replacingOccurrences(of: " ", with: "-")
        .replacingOccurrences(of: "_", with: "-")
      
    default:
      return createErrorOutput(error: TextError.invalidTransformType)
    }
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "originalText": text,
        "transformType": type,
        "transformedText": transformedText,
        "originalLength": text.count,
        "transformedLength": transformedText.count
      ])
    )
  }
  
  private func formatText(text: String, formatType: String?, maxLength: Int?) -> ToolOutput {
    guard let type = formatType else {
      return createErrorOutput(error: TextError.missingFormatType)
    }
    
    let formattedText: String
    
    switch type.lowercased() {
    case "trim":
      formattedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
      
    case "truncate":
      let length = maxLength ?? 50
      if text.count > length {
        let endIndex = text.index(text.startIndex, offsetBy: length - 3)
        formattedText = String(text[..<endIndex]) + "..."
      } else {
        formattedText = text
      }
      
    case "wrap":
      let width = maxLength ?? 80
      formattedText = wrapText(text, width: width)
      
    case "removenewlines":
      formattedText = text.replacingOccurrences(of: "\n", with: " ")
        .replacingOccurrences(of: "\r", with: " ")
      
    case "singlespace":
      // Replace multiple spaces with single space
      let components = text.components(separatedBy: .whitespacesAndNewlines)
        .filter { !$0.isEmpty }
      formattedText = components.joined(separator: " ")
      
    default:
      return createErrorOutput(error: TextError.invalidFormatType)
    }
    
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "originalText": text,
        "formatType": type,
        "formattedText": formattedText,
        "originalLength": text.count,
        "formattedLength": formattedText.count,
        "linesBeforeFormat": text.split(separator: "\n").count,
        "linesAfterFormat": formattedText.split(separator: "\n").count
      ])
    )
  }
  
  private func wrapText(_ text: String, width: Int) -> String {
    var result = ""
    var currentLineLength = 0
    
    let words = text.split(separator: " ", omittingEmptySubsequences: false)
    
    for (index, word) in words.enumerated() {
      let wordLength = word.count
      
      if currentLineLength + wordLength + (currentLineLength > 0 ? 1 : 0) > width {
        if currentLineLength > 0 {
          result += "\n"
          currentLineLength = 0
        }
      } else if currentLineLength > 0 {
        result += " "
        currentLineLength += 1
      }
      
      result += String(word)
      currentLineLength += wordLength
    }
    
    return result
  }
  
  private func createErrorOutput(error: Error) -> ToolOutput {
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "error",
        "error": error.localizedDescription,
        "message": "Failed to process text"
      ])
    )
  }
}

enum TextError: Error, LocalizedError {
  case invalidOperation
  case missingTransformType
  case invalidTransformType
  case missingFormatType
  case invalidFormatType
  
  var errorDescription: String? {
    switch self {
    case .invalidOperation:
      return "Invalid operation. Use 'analyze', 'transform', or 'format'."
    case .missingTransformType:
      return "Transform type is required for transformation."
    case .invalidTransformType:
      return "Invalid transform type. Use 'uppercase', 'lowercase', 'capitalize', 'reverse', etc."
    case .missingFormatType:
      return "Format type is required for formatting."
    case .invalidFormatType:
      return "Invalid format type. Use 'trim', 'wrap', or 'truncate'."
    }
  }
}
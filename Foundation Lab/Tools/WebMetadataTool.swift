//
//  WebMetadataTool.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import Foundation
import FoundationModels
import LinkPresentation

/// `WebMetadataTool` fetches metadata and content from web pages and generates social media summaries.
///
/// This tool extracts title, description, image URL, and content from web pages,
/// then uses AI to generate concise summaries perfect for social media posts.
struct WebMetadataTool: Tool {
  
  /// The name of the tool, used for identification.
  let name = "fetchWebMetadata"
  /// A brief description of the tool's functionality.
  let description = "Fetch webpage metadata and generate a social media summary"
  
  /// Arguments required to fetch web metadata.
  @Generable
  struct Arguments {
    /// The URL of the webpage to analyze
    @Guide(description: "The URL of the webpage to analyze (e.g., 'https://example.com/article')")
    var url: String
    
    /// The target social media platform for the summary
    @Guide(description: "Target platform: 'twitter', 'linkedin', 'facebook', or 'general' (default: 'general')")
    var platform: String?
    
    /// Whether to include hashtags in the summary
    @Guide(description: "Include relevant hashtags in the summary (default: true)")
    var includeHashtags: Bool?
  }
  
  /// The metadata structure returned by the tool.
  struct WebMetadata: Encodable {
    let url: String
    let title: String
    let description: String
    let imageURL: String?
    let summary: String
    let hashtags: [String]
    let platform: String
  }
  
  func call(arguments: Arguments) async throws -> ToolOutput {
    let urlString = arguments.url.trimmingCharacters(in: .whitespacesAndNewlines)
    
    guard !urlString.isEmpty else {
      return createErrorOutput(for: urlString, error: WebMetadataError.emptyURL)
    }
    
    guard let url = URL(string: urlString) else {
      return createErrorOutput(for: urlString, error: WebMetadataError.invalidURL)
    }
    
    do {
      let metadata = try await fetchMetadata(from: url)
      let summary = try await generateSocialMediaSummary(
        metadata: metadata,
        platform: arguments.platform ?? "general",
        includeHashtags: arguments.includeHashtags ?? true
      )
      
      return createSuccessOutput(from: summary)
    } catch {
      return createErrorOutput(for: urlString, error: error)
    }
  }
  
  private func fetchMetadata(from url: URL) async throws -> LPLinkMetadata {
    let provider = LPMetadataProvider()
    
    do {
      let metadata = try await provider.startFetchingMetadata(for: url)
      return metadata
    } catch {
      throw WebMetadataError.fetchFailed(error)
    }
  }
  
  private func generateSocialMediaSummary(
    metadata: LPLinkMetadata,
    platform: String,
    includeHashtags: Bool
  ) async throws -> WebMetadata {
    let title = metadata.title ?? "Untitled"
    let description = metadata.value(forKey: "_summary") as? String ?? ""
    let imageURL = metadata.imageProvider != nil ? "Image available" : nil
    
    // Extract main content from the webpage if available
    let content = extractContent(from: metadata)
    
    // Generate AI-powered summary
    let session = LanguageModelSession()
    let prompt = createSummaryPrompt(
      title: title,
      description: description,
      content: content,
      platform: platform,
      includeHashtags: includeHashtags
    )
    
    let response = try await session.respond(to: Prompt(prompt))
    let summaryText = response.content
    
    // Extract hashtags from the summary
    let hashtags = extractHashtags(from: summaryText)
    
    return WebMetadata(
      url: metadata.url?.absoluteString ?? "",
      title: title,
      description: description,
      imageURL: imageURL,
      summary: summaryText,
      hashtags: hashtags,
      platform: platform
    )
  }
  
  private func extractContent(from metadata: LPLinkMetadata) -> String {
    // Try to extract additional content from metadata
    var content = ""
    
    if let summary = metadata.value(forKey: "_summary") as? String {
      content += summary + "\n\n"
    }
    
    // LinkPresentation doesn't provide full content access
    // In a real implementation, you might want to fetch and parse HTML
    // For now, we'll work with title and description
    
    return content
  }
  
  private func createSummaryPrompt(
    title: String,
    description: String,
    content: String,
    platform: String,
    includeHashtags: Bool
  ) -> String {
    let platformLimits = [
      "twitter": "280 characters",
      "linkedin": "3000 characters (but keep it concise, around 150-300 characters)",
      "facebook": "500 characters",
      "general": "200-300 characters"
    ]
    
    let limit = platformLimits[platform.lowercased()] ?? platformLimits["general"]!
    
    var prompt = """
    Create a compelling social media post summary for the following webpage:
    
    Title: \(title)
    Description: \(description)
    \(content.isEmpty ? "" : "Content: \(content)")
    
    Requirements:
    - Platform: \(platform)
    - Character limit: \(limit)
    - Make it engaging and shareable
    - Include a call-to-action if appropriate
    - Focus on the key takeaway or most interesting aspect
    """
    
    if includeHashtags {
      prompt += "\n- Include 3-5 relevant hashtags at the end"
    }
    
    return prompt
  }
  
  private func extractHashtags(from text: String) -> [String] {
    let pattern = #"#\w+"#
    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    let matches = regex?.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text)) ?? []
    
    return matches.compactMap { match in
      if let range = Range(match.range, in: text) {
        return String(text[range])
      }
      return nil
    }
  }
  
  private func createSuccessOutput(from metadata: WebMetadata) -> ToolOutput {
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "success",
        "url": metadata.url,
        "title": metadata.title,
        "description": metadata.description,
        "imageURL": metadata.imageURL ?? "",
        "summary": metadata.summary,
        "hashtags": metadata.hashtags.joined(separator: " "),
        "platform": metadata.platform,
        "message": "Successfully generated social media summary"
      ])
    )
  }
  
  private func createErrorOutput(for url: String, error: Error) -> ToolOutput {
    return ToolOutput(
      GeneratedContent(properties: [
        "status": "error",
        "url": url,
        "error": error.localizedDescription,
        "summary": "",
        "message": "Failed to fetch metadata or generate summary"
      ])
    )
  }
}

enum WebMetadataError: Error, LocalizedError {
  case emptyURL
  case invalidURL
  case fetchFailed(Error)
  case summaryGenerationFailed
  
  var errorDescription: String? {
    switch self {
    case .emptyURL:
      return "URL cannot be empty"
    case .invalidURL:
      return "Invalid URL format"
    case .fetchFailed(let error):
      return "Failed to fetch metadata: \(error.localizedDescription)"
    case .summaryGenerationFailed:
      return "Failed to generate social media summary"
    }
  }
}
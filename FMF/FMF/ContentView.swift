//
//  ContentView.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//

import FoundationModels
import SwiftUI

struct ContentView: View {
  @State private var response: String = ""
  @State private var isLoading: Bool = false
  @State private var errorMessage: String = ""

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          // Header
          VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "brain.head.profile")
              .imageScale(.large)
              .foregroundStyle(.tint)
            Text("Foundation Models")
              .font(.largeTitle)
              .fontWeight(.bold)
            Text("On-device AI Examples")
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .padding(.horizontal)

          // Example Buttons
          VStack(spacing: 12) {
            ExampleButton(
              title: "Basic Chat",
              subtitle: "Simple conversation with the model",
              icon: "message"
            ) {
              await basicChatExample()
            }

            ExampleButton(
              title: "Structured Data",
              subtitle: "Generate typed objects from prompts",
              icon: "doc.text"
            ) {
              await structuredDataExample()
            }

            ExampleButton(
              title: "Generation Guides",
              subtitle: "Constrained and guided outputs",
              icon: "slider.horizontal.3"
            ) {
              await generationGuidesExample()
            }

            ExampleButton(
              title: "Streaming Response",
              subtitle: "Real-time response streaming",
              icon: "waveform"
            ) {
              await streamingExample()
            }

            ExampleButton(
              title: "Model Availability",
              subtitle: "Check system capabilities",
              icon: "checkmark.circle"
            ) {
              await modelAvailabilityExample()
            }
          }
          .padding(.horizontal)

          // Response Display
          if !response.isEmpty || !errorMessage.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
              Text("Response")
                .font(.headline)
                .padding(.horizontal)

              ScrollView {
                Text(errorMessage.isEmpty ? response : errorMessage)
                  .font(.system(.body, design: .monospaced))
                  .padding()
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .background(
                    RoundedRectangle(cornerRadius: 8)
                      .fill(errorMessage.isEmpty ? Color.gray.opacity(0.1) : Color.red.opacity(0.1))
                  )
                  .foregroundColor(errorMessage.isEmpty ? .primary : .red)
              }
              .frame(maxHeight: 200)
              .padding(.horizontal)
            }
          }

          if isLoading {
            HStack {
              ProgressView()
                .scaleEffect(0.8)
              Text("Generating response...")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
          }
        }
        .padding(.vertical)
      }
      .navigationBarHidden(true)
    }
  }

  // MARK: - Example Functions

  private func basicChatExample() async {
    await executeExample {
      let session = LanguageModelSession(instructions: "You are a helpful assistant.")
      let prompt = "Suggest a catchy name for a new coffee shop."
      let response = try await session.respond(to: prompt)
      return response.content
    }
  }

  private func structuredDataExample() async {
    await executeExample {
      let session = LanguageModelSession()
      let bookInfo = try await session.respond(
        to: "Suggest a sci-fi book.",
        generating: BookRecommendation.self
      )
      return """
        Title: \(bookInfo.content.title)
        Author: \(bookInfo.content.author)
        Genre: \(bookInfo.content.genre)
        Description: \(bookInfo.content.description)
        """
    }
  }

  private func generationGuidesExample() async {
    await executeExample {
      let session = LanguageModelSession()
      let review = try await session.respond(
        to: "Write a product review for a smartphone.",
        generating: ProductReview.self
      )
      return """
        Product: \(review.content.productName)
        Rating: \(review.content.rating)/5
        Review: \(review.content.reviewText)
        Recommendation: \(review.content.recommendation)
        """
    }
  }

  private func streamingExample() async {
    isLoading = true
    response = ""
    errorMessage = ""

    do {
      let session = LanguageModelSession()
      let stream = session.streamResponse(to: "Write a short poem about technology.")

      var accumulatedText = ""
      for try await partialResponse in stream {
        accumulatedText = partialResponse
        await MainActor.run {
          response = accumulatedText
        }
      }

      let finalResponse = try await stream.collect()
      await MainActor.run {
        response = finalResponse.content
        isLoading = false
      }
    } catch {
      await MainActor.run {
        errorMessage = "Streaming error: \(error.localizedDescription)"
        isLoading = false
      }
    }
  }

  private func modelAvailabilityExample() async {
    await executeExample {
      let model = SystemLanguageModel.default
      var result = "Model Availability Check:\n\n"

      switch model.availability {
      case .available:
        result += "✅ Model is available and ready\n"
        result += "Supported languages: \(model.supportedLanguages.count)\n"

        // Test different use cases
        let contentTaggingModel = SystemLanguageModel(useCase: .contentTagging)
        result +=
          "Content tagging model: \(contentTaggingModel.availability == .available ? "✅" : "❌")\n"

      case .unavailable(let reason):
        result += "❌ Model unavailable\n"
        switch reason {
        case .deviceNotEligible:
          result += "Reason: Device not eligible for Apple Intelligence\n"
        case .appleIntelligenceNotEnabled:
          result += "Reason: Apple Intelligence not enabled\n"
        case .modelNotReady:
          result += "Reason: Model assets not ready (downloading...)\n"
        @unknown default:
          fatalError("Unknown availability reason")
        }
      }

      return result
    }
  }

  // MARK: - Helper Functions

  private func executeExample(_ example: @escaping () async throws -> String) async {
    await MainActor.run {
      isLoading = true
      response = ""
      errorMessage = ""
    }

    do {
      let result = try await example()
      await MainActor.run {
        response = result
        isLoading = false
      }
    } catch let error as LanguageModelSession.GenerationError {
      await MainActor.run {
        errorMessage = handleGenerationError(error)
        isLoading = false
      }
    } catch {
      await MainActor.run {
        errorMessage = "Error: \(error.localizedDescription)"
        isLoading = false
      }
    }
  }

  private func handleGenerationError(_ error: LanguageModelSession.GenerationError) -> String {
    switch error {
    case .exceededContextWindowSize(let context):
      return "Context window exceeded: \(context.debugDescription)"
    case .assetsUnavailable(let context):
      return "Model assets unavailable: \(context.debugDescription)"
    case .guardrailViolation(let context):
      return "Content policy violation: \(context.debugDescription)"
    case .decodingFailure(let context):
      return "Failed to decode response: \(context.debugDescription)"
    case .unsupportedGuide(let context):
      return "Unsupported generation guide: \(context.debugDescription)"
    case .unsupportedLanguageOrLocale(let context):
      return "Unsupported language/locale: \(context.debugDescription)"
    @unknown default:
      fatalError()
    }
  }
}

// MARK: - Example Button Component

struct ExampleButton: View {
  let title: String
  let subtitle: String
  let icon: String
  let action: () async -> Void

  @State private var isPressed = false

  var body: some View {
    Button {
      Task {
        await action()
      }
    } label: {
      HStack(spacing: 12) {
        Image(systemName: icon)
          .font(.title2)
          .foregroundStyle(.tint)
          .frame(width: 30)

        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundStyle(.tertiary)
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color.gray.opacity(0.1))
      )
      .scaleEffect(isPressed ? 0.98 : 1.0)
    }
    .buttonStyle(PlainButtonStyle())
    .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
      withAnimation(.easeInOut(duration: 0.1)) {
        isPressed = true
      }
    } onPressingChanged: { pressing in
      if !pressing {
        withAnimation(.easeInOut(duration: 0.1)) {
          isPressed = false
        }
      }
    }
  }
}

// MARK: - Data Models

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
}

@Generable
struct ProductReview {
  @Guide(description: "Product name")
  let productName: String

  @Guide(description: "Rating from 1 to 5")
  let rating: Int

  @Guide(description: "Review text between 50-200 words")
  let reviewText: String

  @Guide(description: "Would recommend")
  let recommendation: String
}

#Preview {
  ContentView()
}

//
//  ErrorView.swift
//  Psylean
//
//  Created by Rudrank Riyam on 26/06/25.
//

import SwiftUI

struct ErrorView: View {
    let error: Error
    let retry: () -> Void

    private struct ErrorDetails {
        let type: String
        let description: String
        let suggestion: String?
    }

    private var errorDetails: ErrorDetails {
        // Check if it's a GenerationError
        let errorString = String(describing: error)

        if errorString.contains("assetsUnavailable") {
            return ErrorDetails(
                type: "Assets Unavailable",
                description: "The AI model assets are not available on this device.",
                suggestion: "Please ensure you have an internet connection and try again."
            )
        } else if errorString.contains("exceededContextWindowSize") {
            return ErrorDetails(
                type: "Context Too Large",
                description: "The request exceeded the model's context window size.",
                suggestion: "Try a shorter query or simpler Pokemon name."
            )
        } else if errorString.contains("rateLimited") {
            return ErrorDetails(
                type: "Rate Limited",
                description: "Too many requests. Please wait a moment.",
                suggestion: "Wait a few seconds before trying again."
            )
        } else if errorString.contains("decodingFailure") {
            return ErrorDetails(
                type: "Response Error",
                description: "Failed to process the AI response.",
                suggestion: "Try a different Pokemon or search term."
            )
        } else if errorString.contains("guardrailViolation") {
            return ErrorDetails(
                type: "Content Filtered",
                description: "The content was blocked by safety filters.",
                suggestion: "Try a different Pokemon name."
            )
        } else {
            return ErrorDetails(
                type: "Unknown Error",
                description: error.localizedDescription,
                suggestion: "Please try again or use a different search."
            )
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)

            Text(errorDetails.type)
                .font(.headline)

            VStack(spacing: 8) {
                Text(errorDetails.description)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                if let suggestion = errorDetails.suggestion {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Always show the actual error for debugging
                Text("Error Details: \(String(describing: error))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }

            Button("Retry") {
                retry()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        #if os(iOS) || os(macOS)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        #endif
    }
}

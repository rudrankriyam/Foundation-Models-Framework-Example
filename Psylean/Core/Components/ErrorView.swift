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

    private var errorDetails: (type: String, description: String, suggestion: String?) {
        // Check if it's a GenerationError
        let errorString = String(describing: error)

        if errorString.contains("assetsUnavailable") {
            return (
                "Assets Unavailable",
                "The AI model assets are not available on this device.",
                "Please ensure you have an internet connection and try again."
            )
        } else if errorString.contains("exceededContextWindowSize") {
            return (
                "Context Too Large",
                "The request exceeded the model's context window size.",
                "Try a shorter query or simpler Pokemon name."
            )
        } else if errorString.contains("rateLimited") {
            return (
                "Rate Limited",
                "Too many requests. Please wait a moment.",
                "Wait a few seconds before trying again."
            )
        } else if errorString.contains("decodingFailure") {
            return (
                "Response Error",
                "Failed to process the AI response.",
                "Try a different Pokemon or search term."
            )
        } else if errorString.contains("guardrailViolation") {
            return (
                "Content Filtered",
                "The content was blocked by safety filters.",
                "Try a different Pokemon name."
            )
        } else {
            return (
                "Unknown Error",
                error.localizedDescription,
                "Please try again or use a different search."
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

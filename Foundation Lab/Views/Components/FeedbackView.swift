//
//  FeedbackView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationModels

struct FeedbackView: View {
    let viewModel: ChatViewModel
    @Binding var isPresented: Bool

    private var assistantEntries: [Transcript.Entry] {
        viewModel.session.transcript.filter { entry in
            if case .response = entry {
                return true
            }
            return false
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if assistantEntries.isEmpty {
                    VStack(spacing: Spacing.large) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.largeTitle)
                            .imageScale(.large)
                            .foregroundStyle(.secondary)

                        Text("No responses to provide feedback on")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: Spacing.medium) {
                            ForEach(assistantEntries) { entry in
                                FeedbackRowView(
                                    entry: entry,
                                    viewModel: viewModel
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Provide Feedback")
        }
#if os(macOS)
        .frame(minWidth: 500, idealWidth: 600, maxWidth: .infinity,
               minHeight: 400, idealHeight: 500, maxHeight: .infinity)
#endif
    }
}

struct FeedbackRowView: View {
    let entry: Transcript.Entry
    let viewModel: ChatViewModel

    private var responseText: String {
        guard case .response(let response) = entry else { return "" }

        return response.segments.compactMap { segment in
            if case .text(let textSegment) = segment {
                return textSegment.content
            }
            return nil
        }.joined(separator: " ")
    }

    private var existingFeedback: LanguageModelFeedback.Sentiment? {
        viewModel.getFeedback(for: entry.id)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("Assistant Response")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if let feedback = existingFeedback {
                    HStack(spacing: Spacing.xSmall) {
                        Image(systemName: feedback == .positive ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                            .foregroundStyle(feedback == .positive ? .green : .red)
                        Text(feedback == .positive ? "Good" : "Bad")
                            .font(.caption)
                            .foregroundStyle(feedback == .positive ? .green : .red)
                    }
                }
            }

            Text(responseText)
                .font(.body)
                .multilineTextAlignment(.leading)
                .lineLimit(3)
                .foregroundStyle(.primary)

            HStack(spacing: Spacing.medium) {
                Button(action: {
                    viewModel.submitFeedback(for: entry.id, sentiment: .positive)
                }, label: {
                    HStack(spacing: Spacing.xSmall) {
                        Image(systemName: "hand.thumbsup.fill")
                        Text("Good")
                            .font(.caption)
                    }
                })
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .disabled(existingFeedback != nil)

                Button(action: {
                    viewModel.submitFeedback(for: entry.id, sentiment: .negative)
                }, label: {
                    HStack(spacing: Spacing.xSmall) {
                        Image(systemName: "hand.thumbsdown.fill")
                        Text("Bad")
                            .font(.caption)
                    }
                })
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(existingFeedback != nil)

                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

#Preview("Feedback View") {
    FeedbackView(
        viewModel: ChatViewModel(),
        isPresented: .constant(true)
    )
}

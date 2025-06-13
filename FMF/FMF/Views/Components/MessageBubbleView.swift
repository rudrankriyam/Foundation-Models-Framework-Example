//
//  MessageBubbleView.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/9/25.
//

import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
    @State private var animateTyping = false

    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 50)
                messageContent
            } else {
                messageContent
                Spacer(minLength: 50)
            }
        }
        .padding(.horizontal)
    }

    private var messageContent: some View {
        VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
            HStack {
                if !message.isFromUser {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.blue)
                        .font(.caption)
                }

                Text(message.isFromUser ? "You" : "Assistant")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                if message.isFromUser {
                    Image(systemName: "person.circle")
                        .foregroundStyle(.blue)
                        .font(.caption)
                }
            }

            Group {
                if !message.isFromUser && message.content.isEmpty {
                    // Show typing indicator for empty assistant messages (streaming)
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { index in
                            Circle()
                                .fill(.secondary)
                                .frame(width: 6, height: 6)
                                .scaleEffect(animateTyping ? 1.2 : 0.8)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                    value: animateTyping
                                )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .onAppear {
                        animateTyping = true
                    }
                } else {
                    Text(message.content)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(message.isFromUser ? Color.indigo : Color.gray)
            )
            .foregroundStyle(.white)

            if message.isContextSummary {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(.orange)
                    Text("Context summarized")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageBubbleView(
            message: ChatMessage(
                content: "Hello! How can I help you today?",
                isFromUser: false
            )
        )

        MessageBubbleView(
            message: ChatMessage(
                content: "Can you help me write a story?",
                isFromUser: true
            )
        )

        MessageBubbleView(
            message: ChatMessage(
                content: "This is a summary of our previous conversation to maintain context.",
                isFromUser: false,
                isContextSummary: true
            )
        )
    }
    .padding()
}

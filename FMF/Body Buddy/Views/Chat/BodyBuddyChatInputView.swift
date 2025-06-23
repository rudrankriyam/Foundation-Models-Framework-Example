//
//  BodyBuddyChatInputView.swift
//  Body Buddy
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI

struct BodyBuddyChatInputView: View {
    @Binding var messageText: String
    let chatViewModel: BodyBuddyChatViewModel
    @FocusState.Binding var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // Quick action suggestions
            if messageText.isEmpty && !chatViewModel.isLoading {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        QuickActionChip(text: "How am I doing today?") {
                            messageText = "How am I doing today?"
                            sendMessage()
                        }
                        
                        QuickActionChip(text: "Set a fitness goal") {
                            messageText = "Help me set a fitness goal"
                            sendMessage()
                        }
                        
                        QuickActionChip(text: "Sleep tips") {
                            messageText = "Give me tips to improve my sleep"
                            sendMessage()
                        }
                        
                        QuickActionChip(text: "Weekly summary") {
                            messageText = "Show me my weekly health summary"
                            sendMessage()
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
            
            // Input field
            HStack(spacing: 12) {
                TextField("Ask Body Buddy anything...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .focused($isTextFieldFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.gray.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.healthPrimary.opacity(0.3), lineWidth: 1)
                    )
                    .onSubmit {
                        sendMessage()
                    }
                    #if os(iOS)
                    .submitLabel(.send)
                    #endif
                
                Button(action: sendMessage) {
                    ZStack {
                        Circle()
                            .fill(messageText.isEmpty ? Color.gray.opacity(0.2) : Color.healthPrimary)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "arrow.up")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(messageText.isEmpty ? .gray : .white)
                    }
                }
                .disabled(
                    messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    chatViewModel.isLoading ||
                    chatViewModel.isSummarizing
                )
                .scaleEffect(messageText.isEmpty ? 1.0 : 1.1)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: messageText.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(
            Color.lightBackground
                .ignoresSafeArea()
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -2)
        )
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        messageText = ""
        isTextFieldFocused = true // Keep focus for continuous conversation
        
        Task {
            await chatViewModel.sendMessage(trimmedMessage)
        }
    }
}

struct QuickActionChip: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.healthPrimary.opacity(0.1))
                .foregroundStyle(Color.healthPrimary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.healthPrimary.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
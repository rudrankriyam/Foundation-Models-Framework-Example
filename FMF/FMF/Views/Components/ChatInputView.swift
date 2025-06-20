//
//  ChatInputView.swift
//  FMF
//
//  Created by Assistant on 6/20/25.
//

import SwiftUI

struct ChatInputView: View {
    @Binding var messageText: String
    let chatViewModel: ChatViewModel
    @FocusState.Binding var isTextFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Type your message...", text: $messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .focused($isTextFieldFocused)
                .onSubmit {
                    sendMessage()
                }
                #if os(iOS)
                .submitLabel(.send)
                #endif
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue
                    )
            }
            .disabled(
                messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                chatViewModel.isLoading ||
                chatViewModel.isSummarizing
            )
            #if os(macOS)
            .buttonStyle(.plain)
            #endif
        }
        .padding()
        #if os(iOS)
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: -2)
        )
        #elseif os(macOS)
        .background(
            Color(NSColor.windowBackgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: -2)
        )
        #endif
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
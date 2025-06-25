//
//  ChatInputView.swift
//  FoundationLab
//
//  Created by Assistant on 6/20/25.
//

import SwiftUI

struct ChatInputView: View {
    @Binding var messageText: String
    @EnvironmentObject var chatViewModel: ChatViewModel
    @FocusState.Binding var isTextFieldFocused: Bool
    @Namespace private var glassNamespace
    
    var body: some View {
#if os(iOS) || os(macOS)
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                TextField("Type your message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .focused($isTextFieldFocused)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .glassEffect(.regular, in: .rect(cornerRadius: 20))
                    .glassEffectID("textField", in: glassNamespace)
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
                .padding(8)
                .glassEffect(
                    .regular
                        .tint(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .clear : .blue)
                        .interactive(true)
                )
                .glassEffectID("sendButton", in: glassNamespace)
                .disabled(
                    messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    chatViewModel.isLoading ||
                    chatViewModel.isSummarizing
                )
#if os(macOS)
                .buttonStyle(.plain)
#endif
            }
        }
        .padding()
#else
        HStack(spacing: 12) {
            TextField("Type your message...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isTextFieldFocused)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .onSubmit {
                    sendMessage()
                }
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue
                    )
            }
            .padding(8)
            .disabled(
                messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                chatViewModel.isLoading ||
                chatViewModel.isSummarizing
            )
        }
        .padding()
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: messageText.isEmpty)
#if os(iOS)
        .background(
            Color(UIColor.systemBackground)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -2)
        )
#elseif os(macOS)
        .background(
            Color(NSColor.windowBackgroundColor)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -2)
        )
#endif
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

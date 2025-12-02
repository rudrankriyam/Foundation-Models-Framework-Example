//
//  ChatInputView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/20/25.
//

import SwiftUI

struct ChatInputView: View {
    @Binding var messageText: String
    @Environment(ChatViewModel.self) var chatViewModel
    @FocusState.Binding var isTextFieldFocused: Bool
    @Binding var showVoiceSheet: Bool
    @Namespace private var glassNamespace

    var body: some View {
#if os(iOS) || os(macOS)
        GlassEffectContainer(spacing: Spacing.medium) {
            HStack(spacing: Spacing.medium) {
                TextField("Type your message...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .focused($isTextFieldFocused)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.xLarge))
                    .glassEffectID("textField", in: glassNamespace)
                    .onSubmit {
                        sendMessage()
                    }
#if os(iOS)
                    .submitLabel(.send)
#endif

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up")
                        .font(.headline)
                        .foregroundStyle(
                            messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .white
                        )
                }
                .padding(Spacing.small)
                .glassEffect(
                    .regular
                        .tint(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .clear : .main)
                        .interactive(true), in: .circle
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

                Button(action: { showVoiceSheet = true }) {
                    Image(systemName: "waveform")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
                .padding(Spacing.small)
                .glassEffect(
                    .regular
                        .tint(.purple)
                        .interactive(true), in: .circle
                )
                .glassEffectID("voiceButton", in: glassNamespace)
            }
        }
        .padding()
#else
        HStack(spacing: Spacing.medium) {
            TextField("Type your message...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($isTextFieldFocused)
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
                .onSubmit {
                    sendMessage()
                }

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : Color.accentColor
                    )
            }
            .buttonStyle(.plain)
            .padding(Spacing.small)
            .disabled(
                messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                chatViewModel.isLoading ||
                chatViewModel.isSummarizing
            )

            Button(action: { showVoiceSheet = true }) {
                Image(systemName: "waveform.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.purple)
            }
            .buttonStyle(.plain)
            .padding(Spacing.small)
        }
        .padding()
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: messageText.isEmpty)
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

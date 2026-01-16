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
    @Namespace private var glassNamespace

    var body: some View {
#if os(iOS) || os(macOS)
        GlassEffectContainer(spacing: Spacing.medium) {
            HStack(spacing: Spacing.medium) {
                Group {
                    if case .listening(let partialText) = chatViewModel.voiceState {
                        Text(partialText.isEmpty ? "Listening..." : partialText)
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        TextField("Type your message...", text: $messageText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .focused($isTextFieldFocused)
                            .onSubmit {
                                sendMessage()
                            }
#if os(iOS)
                            .submitLabel(.send)
#endif
                    }
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.medium)
                .glassEffect(.regular, in: .rect(cornerRadius: CornerRadius.xLarge))
                .glassEffectID("textField", in: glassNamespace)

                if chatViewModel.voiceState == .preparing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(Spacing.medium)

                    Button("Cancel") {
                        chatViewModel.cancelVoiceMode()
                    }
                    .foregroundStyle(.white)
                    .padding(Spacing.medium)
                } else if case .listening = chatViewModel.voiceState {
                    Button("End") {
                        Task {
                            await chatViewModel.stopVoiceModeAndSend()
                        }
                    }
                    .foregroundStyle(.white)
                    .font(.subheadline.weight(.medium))
                    .padding(Spacing.medium)
                    .glassEffect(
                        .regular
                            .tint(.red)
                            .interactive(true), in: .circle
                    )
                } else if case .speaking = chatViewModel.voiceState {
                    Button("Stop") {
                        chatViewModel.stopSpeaking()
                    }
                    .foregroundStyle(.white)
                    .font(.subheadline.weight(.medium))
                    .padding(Spacing.medium)
                    .glassEffect(
                        .regular
                            .tint(.orange)
                            .interactive(true), in: .circle
                    )
                } else if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        Task {
                            await chatViewModel.startVoiceMode()
                        }
                    } label: {
                        Image(systemName: "waveform")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                    .padding(Spacing.medium)
                    .glassEffect(
                        .regular
                            .tint(.blue)
                            .interactive(true), in: .circle
                    )
                    .glassEffectID("voiceButton", in: glassNamespace)
                    .disabled(chatViewModel.voiceState.isActive && !chatViewModel.voiceState.isError)
                } else {
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(Spacing.medium)
                    .glassEffect(
                        .regular
                            .tint(.main)
                            .interactive(true), in: .circle
                    )
                    .glassEffectID("sendButton", in: glassNamespace)
                    .disabled(chatViewModel.isLoading || chatViewModel.isSummarizing)
#if os(macOS)
                    .buttonStyle(.plain)
#endif
                }
            }
        }
        .padding()
#else
        HStack(spacing: Spacing.medium) {
            Group {
                if case .listening(let partialText) = chatViewModel.voiceState {
                    Text(partialText.isEmpty ? "Listening..." : partialText)
                        .foregroundStyle(.secondary)
                        .italic()
                } else {
                    TextField("Type your message...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            sendMessage()
                        }
                }
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)

            if chatViewModel.voiceState == .preparing {
                ProgressView()
                    .padding(.vertical, Spacing.small)

                Button("Cancel") {
                    chatViewModel.cancelVoiceMode()
                }
                .padding(Spacing.small)
            } else if case .listening = chatViewModel.voiceState {
                Button("End") {
                    Task {
                        await chatViewModel.stopVoiceModeAndSend()
                    }
                }
                .padding(Spacing.small)
            } else if case .speaking = chatViewModel.voiceState {
                Button("Stop") {
                    chatViewModel.stopSpeaking()
                }
                .padding(Spacing.small)
            } else if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    Task {
                        await chatViewModel.startVoiceMode()
                    }
                } label: {
                    Image(systemName: "waveform.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .padding(Spacing.small)
                .disabled(chatViewModel.voiceState.isActive && !chatViewModel.voiceState.isError)
            } else {
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
            }
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

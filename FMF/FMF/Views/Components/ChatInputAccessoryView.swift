//
//  ChatInputAccessoryView.swift
//  FMF
//
//  Created by Rudrank Riyam on 6/15/25.
//

import SwiftUI

struct ChatInputAccessoryView: View {
  @Binding var messageText: String
  let chatViewModel: ChatViewModel
  @Environment(\.tabViewBottomAccessoryPlacement) private var placement
  @FocusState private var isTextFieldFocused: Bool
  
  var body: some View {
    HStack(spacing: 12) {
      TextField("Type your message...", text: $messageText, axis: .vertical)
        .textFieldStyle(.roundedBorder)
        .focused($isTextFieldFocused)
        .font(.system(size: isCollapsed ? 14 : 16))
        .onSubmit {
          sendMessage()
        }
        #if os(iOS)
        .submitLabel(.send)
        #endif
      
      Button(action: sendMessage) {
        Image(systemName: "arrow.up.circle.fill")
          .font(.system(size: isCollapsed ? 20 : 24))
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
      .keyboardShortcut(.return, modifiers: [])
      #endif
    }
    .padding(.horizontal, isCollapsed ? 8 : 16)
    .padding(.vertical, isCollapsed ? 6 : 12)
    .background(backgroundMaterial)
    .animation(.easeInOut(duration: 0.3), value: placement)
    .onAppear {
      // Auto-focus the text field when the view appears
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        isTextFieldFocused = true
      }
    }
  }
  
  private var isCollapsed: Bool {
    placement == .inline
  }
  
  private var backgroundMaterial: some ShapeStyle {
    if isCollapsed {
      return AnyShapeStyle(.ultraThinMaterial)
    } else {
      return AnyShapeStyle(.regularMaterial)
    }
  }
  
  private func sendMessage() {
    let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedMessage.isEmpty else { return }
    
    messageText = ""
    
    // Keep focus on text field for continuous conversation
    if !isCollapsed {
      isTextFieldFocused = true
    }
    
    Task {
      await chatViewModel.sendMessage(trimmedMessage)
    }
  }
}

#Preview {
  ChatInputAccessoryView(
    messageText: .constant(""),
    chatViewModel: ChatViewModel()
  )
}
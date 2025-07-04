//
//  HealthMessageBubbleView.swift
//  Physiqa
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI

struct HealthMessageBubbleView: View {
    let content: String
    let isFromUser: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isFromUser {
                // Physiqa avatar
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            
            VStack(alignment: isFromUser ? .trailing : .leading, spacing: 4) {
                // Message content
                Text(content)
                    .font(.body)
                    .foregroundStyle(isFromUser ? .primary : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isFromUser ? Color.primary.opacity(0.08) : Color.primary.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isFromUser ? Color.primary.opacity(0.1) : Color.clear, lineWidth: 1)
                    )
                    .frame(maxWidth: 280, alignment: isFromUser ? .trailing : .leading)
            }
            
            if isFromUser {
                // User avatar placeholder
                Circle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    )
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: isFromUser ? .trailing : .leading)
    }
}

#Preview {
    VStack(spacing: 16) {
        HealthMessageBubbleView(
            content: "Hi! I'm Physiqa, your personal health coach. How can I help you today?",
            isFromUser: false
        )
        
        HealthMessageBubbleView(
            content: "Can you show me my health stats for today?",
            isFromUser: true
        )
        
        HealthMessageBubbleView(
            content: "Of course! Let me fetch your health data for today. You've been doing great with 8,432 steps so far! That's 84% of your daily goal. Your sleep last night was also good at 7.2 hours. Keep up the excellent work! 🎯",
            isFromUser: false
        )
    }
    .padding()
    .background(Color.lightBackground)
}
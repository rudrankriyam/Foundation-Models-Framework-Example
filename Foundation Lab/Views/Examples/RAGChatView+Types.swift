//
//  RAGChatView+Types.swift
//  FoundationLab
//
//  Supporting types for RAG chat functionality.
//

import Foundation
import SwiftUI

// MARK: - RAG Chat Entry

@Observable
final class RAGChatEntry: Identifiable {
    let id = UUID()
    let role: Role
    var content: String
    let sources: [RAGChunk]

    init(role: Role, content: String, sources: [RAGChunk]) {
        self.role = role
        self.content = content
        self.sources = sources
    }

    enum Role {
        case user
        case assistant
    }
}

// MARK: - RAG Chunk

struct RAGChunk {
    let documentId: String
    let documentTitle: String
    let content: String
    let chunkIndex: Int
    let similarityScore: Double
}

// MARK: - Message Bubble

struct RAGMessageBubble: View {
    let entry: RAGChatEntry

    var body: some View {
        HStack {
            if entry.role == .user { Spacer(minLength: 60) }

            VStack(alignment: entry.role == .user ? .trailing : .leading, spacing: 6) {
                Text(entry.content)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(entry.role == .user ? Color.accentColor : Color.gray.opacity(0.15))
                    .foregroundStyle(entry.role == .user ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                if entry.role == .assistant && !entry.sources.isEmpty {
                    sourcesView
                }
            }

            if entry.role == .assistant { Spacer(minLength: 60) }
        }
        .padding(.horizontal, Spacing.medium)
    }

    private var sourcesView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.small) {
                ForEach(Array(entry.sources.enumerated()), id: \.offset) { index, source in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(index + 1). \(source.documentTitle)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)

                        Text(source.content)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .frame(maxWidth: 200, alignment: .leading)
                    }
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

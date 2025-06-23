//
//  BodyBuddyChatView.swift
//  Body Buddy
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI
import FoundationModels
import SwiftData

struct BodyBuddyChatView: View {
    @State private var viewModel = BodyBuddyChatViewModel()
    @State private var scrollID: String?
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messagesView
                
                BodyBuddyChatInputView(
                    messageText: $messageText,
                    chatViewModel: viewModel,
                    isTextFieldFocused: $isTextFieldFocused
                )
            }
            .background(Color.lightBackground)
            .navigationTitle("Body Buddy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        viewModel.clearChat()
                    }
                    .disabled(viewModel.session.transcript.entries.isEmpty)
                }
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            Task {
                await viewModel.loadInitialHealthData()
            }
            
            // Auto-focus when chat appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
    
    // MARK: - View Components
    
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Welcome message
                    if viewModel.session.transcript.entries.isEmpty {
                        WelcomeMessageView(healthMetrics: viewModel.currentHealthMetrics)
                            .id("welcome")
                    }
                    
                    ForEach(viewModel.session.transcript.entries) { entry in
                        BodyBuddyTranscriptEntryView(entry: entry)
                            .id(entry.id)
                    }
                    
                    if viewModel.isSummarizing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Summarizing conversation...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .id("summarizing")
                    }
                    
                    // Empty spacer for bottom padding
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.vertical)
            }
            #if os(iOS)
            .scrollDismissesKeyboard(.interactively)
            #endif
            .scrollPosition(id: $scrollID, anchor: .bottom)
            .onChange(of: viewModel.session.transcript.entries.count) { _, _ in
                if let lastEntry = viewModel.session.transcript.entries.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastEntry.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isSummarizing) { _, isSummarizing in
                if isSummarizing {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("summarizing", anchor: .bottom)
                    }
                }
            }
        }
        .defaultScrollAnchor(.bottom)
    }
}

struct BodyBuddyTranscriptEntryView: View {
    let entry: Transcript.Entry
    
    var body: some View {
        switch entry {
        case .prompt(let prompt):
            if let text = extractText(from: prompt.segments), !text.isEmpty {
                HealthMessageBubbleView(
                    content: text,
                    isFromUser: true
                )
            }
            
        case .response(let response):
            if let text = extractText(from: response.segments), !text.isEmpty {
                HealthMessageBubbleView(
                    content: text,
                    isFromUser: false
                )
            }
            
        case .toolCalls(let toolCalls):
            ForEach(Array(toolCalls.enumerated()), id: \.offset) { _, toolCall in
                ToolCallView(toolName: toolCall.toolName)
            }
            
        case .toolOutput(_):
            // Tool outputs are typically incorporated into the response
            EmptyView()
            
        case .instructions:
            // Don't show instructions in chat UI
            EmptyView()
            
        @unknown default:
            EmptyView()
        }
    }
    
    private func extractText(from segments: [Transcript.Segment]) -> String? {
        let text = segments.compactMap { segment in
            if case .text(let textSegment) = segment {
                return textSegment.content
            }
            return nil
        }.joined(separator: " ")
        
        return text.isEmpty ? nil : text
    }
}

struct WelcomeMessageView: View {
    let healthMetrics: [MetricType: Double]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "hand.wave.fill")
                    .font(.title2)
                    .foregroundStyle(Color.healthPrimary)
                
                Text("Welcome to Body Buddy!")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Text("I'm your personal health coach, here to help you achieve your wellness goals. I can see you've been active today:")
                .font(.body)
                .foregroundStyle(.secondary)
            
            if !healthMetrics.isEmpty {
                HStack(spacing: 20) {
                    if let steps = healthMetrics[.steps], steps > 0 {
                        Label("\(Int(steps)) steps", systemImage: "figure.walk")
                            .font(.caption)
                            .foregroundStyle(Color.healthPrimary)
                    }
                    
                    if let energy = healthMetrics[.activeEnergy], energy > 0 {
                        Label("\(Int(energy)) cal", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(Color.orange)
                    }
                }
            }
            
            Text("How can I help you today? Ask me about your health data, get personalized tips, or set new wellness goals!")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .padding(.horizontal)
    }
}

struct ToolCallView: View {
    let toolName: String
    
    var body: some View {
        HStack {
            Image(systemName: "gearshape.fill")
                .font(.caption)
                .foregroundStyle(Color.healthPrimary)
            
            Text("Analyzing your \(formatToolName(toolName))...")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .rect(cornerRadius: 12))
        .padding(.horizontal)
    }
    
    private func formatToolName(_ name: String) -> String {
        switch name {
        case "fetchHealthData":
            return "health data"
        case "analyzeHealthMetrics":
            return "health metrics"
        default:
            return "data"
        }
    }
}

#Preview {
    BodyBuddyChatView()
        .modelContainer(for: [BodyBuddySession.self, HealthMetric.self, HealthInsight.self])
}
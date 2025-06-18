//
//  ToolsTabView.swift
//  FMF
//
//  Created by Claude on 6/18/25.
//

import SwiftUI
import FoundationModels

// MARK: - Platform-specific Colors

#if os(macOS)
import AppKit
#endif

private var secondaryBackgroundColor: Color {
#if os(iOS)
    Color(UIColor.secondarySystemBackground)
#elseif os(macOS)
    Color(NSColor.controlBackgroundColor)
#endif
}

private var separatorColor: Color {
#if os(iOS)
    Color(UIColor.separator)
#elseif os(macOS)
    Color(NSColor.separatorColor)
#endif
}

struct ToolsTabView: View {
    @State private var isRunning = false
    @State private var result: String = ""
    @State private var errorMessage: String?
    @State private var selectedTool: ToolExample?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerView
                    toolButtonsView
                    if selectedTool != nil {
                        resultView
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Tools")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
        }
    }

    // MARK: - View Components

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI Tools")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Explore AI-powered tools")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }

    private var toolButtonsView: some View {
        LazyVGrid(columns: adaptiveGridColumns, spacing: gridSpacing) {
            ForEach(ToolExample.allCases, id: \.self) { tool in
                ToolButton(
                    tool: tool,
                    isSelected: selectedTool == tool,
                    isRunning: isRunning && selectedTool == tool
                ) {
                    selectedTool = tool
                    Task {
                        await executeToolExample(tool: tool)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var adaptiveGridColumns: [GridItem] {
#if os(iOS)
        // iPhone: 2 columns with flexible sizing
        return [
            GridItem(.flexible(minimum: 140), spacing: 12),
            GridItem(.flexible(minimum: 140), spacing: 12)
        ]
#elseif os(macOS)
        // Mac: Adaptive columns based on available width
        return Array(repeating: GridItem(.adaptive(minimum: 280), spacing: 12), count: 1)
#else
        // Default fallback
        return [
            GridItem(.flexible(minimum: 140), spacing: 12),
            GridItem(.flexible(minimum: 140), spacing: 12)
        ]
#endif
    }

    private var gridSpacing: CGFloat {
#if os(iOS)
        16
#else
        12
#endif
    }

    @ViewBuilder
    private var resultView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Result")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    result = ""
                    errorMessage = nil
                    selectedTool = nil
                }
                .font(.caption)
            }

            if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }

            if !result.isEmpty {
                ScrollView {
                    Text(result)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(secondaryBackgroundColor)
                        .cornerRadius(8)
                }
                .frame(maxHeight: 300)
            }
        }
        .padding(.horizontal)
    }

    @MainActor
    private func executeToolExample(tool: ToolExample) async {
        isRunning = true
        errorMessage = nil
        result = ""

        do {
            let service = FoundationModelsService()
            let response: String

            switch tool {
            case .weather:
                response = try await service.sendMessageWithWeatherTool()
            case .web:
                response = try await service.sendMessageWithWebTool()
            case .contacts:
                response = try await service.sendMessageWithContactsTool()
            case .calendar:
                response = try await service.sendMessageWithCalendarTool()
            case .reminders:
                response = try await service.sendMessageWithRemindersTool()
            case .location:
                response = try await service.sendMessageWithLocationTool()
            case .health:
                response = try await service.sendMessageWithHealthTool()
            }

            result = response
        } catch {
            errorMessage = error.localizedDescription
        }

        isRunning = false
    }
}

// MARK: - Tool Button Component

struct ToolButton: View {
    let tool: ToolExample
    let isSelected: Bool
    let isRunning: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Image(systemName: tool.icon)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? .white : .accentColor)
                        .opacity(isRunning ? 0 : 1)

                    if isRunning {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    }
                }
                .frame(width: 50, height: 50)

                VStack(spacing: 4) {
                    Text(tool.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                        .multilineTextAlignment(.center)

                    Text(tool.shortDescription)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 140)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : secondaryBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : separatorColor, lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isRunning)
    }
}

// MARK: - Tool Example Enum

enum ToolExample: String, CaseIterable {
    case weather
    case web
    case contacts
    case calendar
    case reminders
    case location
    case health

    var displayName: String {
        switch self {
        case .weather: return "Weather"
        case .web: return "Web Search"
        case .contacts: return "Contacts"
        case .calendar: return "Calendar"
        case .reminders: return "Reminders"
        case .location: return "Location"
        case .health: return "Health"
        }
    }

    var icon: String {
        switch self {
        case .weather: return "cloud.sun"
        case .web: return "magnifyingglass"
        case .contacts: return "person.2"
        case .calendar: return "calendar"
        case .reminders: return "checklist"
        case .location: return "location"
        case .health: return "heart"
        }
    }

    var shortDescription: String {
        switch self {
        case .weather: return "Get weather info"
        case .web: return "Search the web"
        case .contacts: return "Find contacts"
        case .calendar: return "View events"
        case .reminders: return "Manage tasks"
        case .location: return "Get location"
        case .health: return "Health data"
        }
    }

    var description: String {
        switch self {
        case .weather: return "Get current weather information for any location"
        case .web: return "Search the web for any topic using AI-powered search"
        case .contacts: return "Search and display contact information"
        case .calendar: return "Create, search, and manage calendar events"
        case .reminders: return "Create and manage reminder tasks"
        case .location: return "Get location information and perform geocoding"
        case .health: return "Access health data like steps, heart rate, and workouts"
        }
    }
}

#Preview {
    ToolsTabView()
}

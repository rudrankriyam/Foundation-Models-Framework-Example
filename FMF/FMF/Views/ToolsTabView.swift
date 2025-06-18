//
//  ToolsTabView.swift
//  FMF
//
//  Created by Claude on 6/18/25.
//

import SwiftUI
import FoundationModels

struct ToolsTabView: View {
    @State private var selectedTool: ToolExample = .weather
    @State private var isRunning = false
    @State private var result: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Tool selector
                Picker("Select Tool", selection: $selectedTool) {
                    ForEach(ToolExample.allCases, id: \.self) { tool in
                        Text(tool.displayName).tag(tool)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
                
                // Tool description
                Text(selectedTool.description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .frame(maxHeight: 80)
                
                // Run button
                Button(action: runSelectedTool) {
                    HStack {
                        if isRunning {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text(isRunning ? "Running..." : "Run Example")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRunning)
                .padding(.horizontal)
                
                // Result display
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        if let error = errorMessage {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        if !result.isEmpty {
                            Text("Result:")
                                .font(.headline)
                            
                            Text(result)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: .infinity)
            }
            .navigationTitle("Tool Examples")
        }
    }
    
    private func runSelectedTool() {
        Task {
            await executeToolExample()
        }
    }
    
    @MainActor
    private func executeToolExample() async {
        isRunning = true
        errorMessage = nil
        result = ""
        
        do {
            let service = FoundationModelsService()
            let response: String
            
            switch selectedTool {
            case .weather:
                response = try await service.sendMessageWithWeatherTool()
            case .web:
                response = try await service.sendMessageWithWebTool()
            case .timer:
                response = try await service.sendMessageWithTimerTool()
            case .math:
                response = try await service.sendMessageWithMathTool()
            case .contacts:
                response = try await service.sendMessageWithContactsTool()
            case .calendar:
                response = try await service.sendMessageWithCalendarTool()
            case .reminders:
                response = try await service.sendMessageWithRemindersTool()
            case .text:
                response = try await service.sendMessageWithTextTool()
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

enum ToolExample: String, CaseIterable {
    case weather
    case web
    case timer
    case math
    case contacts
    case calendar
    case reminders
    case text
    case location
    case health
    
    var displayName: String {
        switch self {
        case .weather: return "Weather Tool"
        case .web: return "Web Search Tool"
        case .timer: return "Timer Tool"
        case .math: return "Math Tool"
        case .contacts: return "Contacts Tool"
        case .calendar: return "Calendar Tool"
        case .reminders: return "Reminders Tool"
        case .text: return "Text Tool"
        case .location: return "Location Tool"
        case .health: return "Health Tool"
        }
    }
    
    var description: String {
        switch self {
        case .weather: return "Get current weather information for any location"
        case .web: return "Search the web for any topic using AI-powered search"
        case .timer: return "Create and manage timers with various durations"
        case .math: return "Perform mathematical calculations and solve equations"
        case .contacts: return "Search and display contact information"
        case .calendar: return "Create, search, and manage calendar events"
        case .reminders: return "Create and manage reminder tasks"
        case .text: return "Transform text with various operations"
        case .location: return "Get location information and perform geocoding"
        case .health: return "Access health data like steps, heart rate, and workouts"
        }
    }
}

#Preview {
    ToolsTabView()
}
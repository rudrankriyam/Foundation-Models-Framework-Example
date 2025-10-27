//
//  ProductionLanguageExampleView.swift
//  FoundationLab
//
//  Created by Assistant on 12/30/25.
//

import SwiftUI
import FoundationModels
import Observation

struct ProductionLanguageExampleView: View {
    @State private var detectedLanguage = ""
    @State private var selectedLanguage = "English (en-US)"
    @State private var foodDescription = "I had 2 scrambled eggs with toast for breakfast"
    @State private var nutritionResult: NutritionResult?
    @State private var isRunning = false
    @State private var errorMessage: String?
    
    @Environment(LanguageService.self) private var languageService
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                languageSelectionSection
                inputSection
                
                Button("Analyze Nutrition") {
                    Task {
                        await analyzeNutrition()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isRunning || foodDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)
                
                if isRunning {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Analyzing nutrition...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                if let result = nutritionResult {
                    resultSection(result: result)
                }
                
                implementationSection
            }
            .padding(.vertical)
        }
        .navigationTitle("Insights Example")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .onAppear {
            detectUserLanguage()
        }
    }
    
    private var languageSelectionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Language Configuration")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Detected Language: \(detectedLanguage)")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                if languageService.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading supported languages...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Picker("Response Language", selection: $selectedLanguage) {
                        // Always include the detected language first
                        if !detectedLanguage.isEmpty {
                            Text(detectedLanguage).tag(detectedLanguage)
                        }
                        
                        // Add English (en-US) if it's not the detected language
                        if detectedLanguage != "English (en-US)" {
                            Text("English (en-US)").tag("English (en-US)")
                        }
                        
                        // Add other supported languages, excluding duplicates
                        ForEach(languageService.getSupportedLanguageNames().filter {
                            $0 != detectedLanguage && $0 != "English (en-US)"
                        }, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                if let errorMessage = languageService.errorMessage {
                    Text("Language loading error: \(errorMessage)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Food Description")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: Spacing.small) {
                TextEditor(text: $foodDescription)
                    .font(.body)
                    .padding()
                    .frame(height: 100)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                
                Text("Example: \"I had a chicken salad with avocado and olive oil dressing\"")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
    }
    
    private func resultSection(result: NutritionResult) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Nutrition Analysis")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: Spacing.medium) {
                NutritionCard(
                    title: "Parsed Food",
                    value: result.foodName,
                    color: .blue
                )
                
                HStack(spacing: Spacing.medium) {
                    NutritionCard(
                        title: "Calories",
                        value: "\(result.calories)",
                        color: .orange
                    )
                    
                    NutritionCard(
                        title: "Protein",
                        value: "\(result.proteinGrams)g",
                        color: .green
                    )
                }
                
                HStack(spacing: Spacing.medium) {
                    NutritionCard(
                        title: "Carbs",
                        value: "\(result.carbsGrams)g",
                        color: .purple
                    )
                    
                    NutritionCard(
                        title: "Fat",
                        value: "\(result.fatGrams)g",
                        color: .red
                    )
                }
                
                if !result.insights.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("AI Insights")
                            .font(.headline)
                        
                        Text(result.insights)
                            .font(.body)
                            .padding()
                            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var implementationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Implementation Details")
                .font(.headline)
                .padding(.horizontal)
            
            CodeViewer(
                code: """
struct NutritionAnalysisService {
    func analyze(_ description: String, language: String) async throws -> NutritionResult {
        let session = LanguageModelSession(instructions: \"\"\"
            You are a nutrition expert specializing in food analysis.

            IMPORTANT: Respond in \\(language). All responses must be in: \\(language)

            When parsing food descriptions:
            - Estimate realistic portions for typical adults
            - Consider cooking methods and additions
            - Be practical with portion sizes
            - Round to reasonable numbers

            Tone: Supportive, knowledgeable, practical, encouraging.
            Language: \\(language)
            \"\"\")

        return try await session.respond(
            to: description,
            generating: NutritionResult.self
        ).content
    }
}
"""
            )
        }
        .padding(.horizontal)
    }
    
    private func detectUserLanguage() {
        let detected = languageService.getCurrentUserLanguageDisplayName()
        detectedLanguage = detected
        selectedLanguage = detected // Set the detected language as the default selection
    }
    
    @MainActor
    private func analyzeNutrition() async {
        isRunning = true
        errorMessage = nil
        nutritionResult = nil
        
        do {
            let session = LanguageModelSession(instructions: """
                You are a nutrition expert specializing in food analysis and macro tracking.
                
                IMPORTANT: Respond in \(selectedLanguage). All your responses must be in the user's language: \(selectedLanguage)
                
                When parsing food descriptions:
                - Estimate realistic portions for typical adults
                - Consider cooking methods (grilled vs fried affects calories)
                - Account for common additions (butter, oil, condiments)
                - Be practical with portion sizes people actually eat
                - Round to reasonable numbers (don't say 247.3 calories, say ~250)
                
                For nutritional insights:
                - Focus on energy for fitness and performance
                - Be encouraging and supportive like a fitness coach
                - Highlight good nutritional choices
                - Suggest balance when needed
                - Keep responses brief and actionable
                
                Tone: Supportive, knowledgeable, practical, encouraging.
                Language: \(selectedLanguage)
                """)
            
            let prompt = """
                RESPOND IN \(selectedLanguage). Parse this food description into nutritional data: "\(foodDescription)"
                
                Examples of good parsing:
                "I had 2 scrambled eggs with toast" → Consider: 2 large eggs (~140 cal), 1 slice toast (~80 cal), cooking butter (~30 cal)
                "protein shake after workout" → Consider: 1 scoop protein powder (~120 cal) + milk/water
                "pizza slice for lunch" → Consider: 1 slice medium pizza (~280 cal)
                
                Be realistic about portions people actually eat.
                Account for cooking methods and common additions.
                
                Language: \(selectedLanguage)
                """
            
            let response = try await session.respond(
                to: prompt,
                generating: NutritionParseResult.self
            )
            
            // Generate insights
            let insightsPrompt = """
                RESPOND IN \(selectedLanguage). Provide brief, encouraging nutritional insights about this meal: \(response.content.foodName) with \(response.content.calories) calories, \(response.content.proteinGrams)g protein, \(response.content.carbsGrams)g carbs, \(response.content.fatGrams)g fat.
                
                Be supportive and focus on the positive aspects. Keep it brief (2-3 sentences).
                Language: \(selectedLanguage)
                """
            
            let insightsResponse = try await session.respond(to: insightsPrompt)
            
            nutritionResult = NutritionResult(
                foodName: response.content.foodName,
                calories: response.content.calories,
                proteinGrams: response.content.proteinGrams,
                carbsGrams: response.content.carbsGrams,
                fatGrams: response.content.fatGrams,
                insights: insightsResponse.content
            )
            
        } catch {
            errorMessage = "Analysis failed: \(error.localizedDescription)"
        }
        
        isRunning = false
    }
}

@Generable
struct NutritionParseResult {
    @Guide(description: "The name or description of the food item")
    let foodName: String
    
    @Guide(description: "Estimated calories as a whole number")
    let calories: Int
    
    @Guide(description: "Protein content in grams as a whole number")
    let proteinGrams: Int
    
    @Guide(description: "Carbohydrate content in grams as a whole number")
    let carbsGrams: Int
    
    @Guide(description: "Fat content in grams as a whole number")
    let fatGrams: Int
}

struct NutritionResult {
    let foodName: String
    let calories: Int
    let proteinGrams: Int
    let carbsGrams: Int
    let fatGrams: Int
    let insights: String
}

struct NutritionCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Spacing.small) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        ProductionLanguageExampleView()
    }
    .environment(LanguageService())
}

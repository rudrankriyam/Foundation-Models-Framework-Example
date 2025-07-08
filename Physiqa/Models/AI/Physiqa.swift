//
//  Physiqa.swift
//  Physiqa
//
//  Created by Rudrank Riyam on 6/23/25.
//

import Foundation
import FoundationModels

/// The main AI character that interacts with users about their health
@Generable
struct Physiqa {
    @Guide(description: "A friendly greeting based on time of day and user's recent health data")
    let greeting: String
    
    @Guide(description: "Current mood/personality of the buddy (cheerful, encouraging, concerned, celebratory)")
    let mood: PhysiqaMood
    
    @Guide(description: "A motivational message tailored to the user's health goals")
    let motivationalMessage: String
    
    @Guide(description: "Key health metrics to highlight in the conversation")
    let focusMetrics: [String]
    
    @Guide(description: "Suggested actions or activities for the user")
    let suggestions: [String]
}

@Generable
enum PhysiqaMood {
    case cheerful
    case encouraging
    case concerned
    case celebratory
    case supportive
    case energetic
    case calm
}

/// Represents a personalized response from Physiqa
@Generable
struct PhysiqaResponse {
    @Guide(description: "The main message content from Physiqa")
    let message: String
    
    @Guide(description: "The emotional tone of the response")
    let tone: ResponseTone
    
    @Guide(description: "Follow-up questions to engage the user")
    let followUpQuestions: [String]
    
    @Guide(description: "Related health metrics to reference")
    let relatedMetrics: [String]
    
    @Guide(description: "Actionable tips based on the conversation context")
    let actionableTips: [String]
}

@Generable
enum ResponseTone {
    case friendly
    case professional
    case empathetic
    case motivational
    case educational
    case celebratory
}

/// Health coaching session structure
@Generable
struct CoachingSession {
    @Guide(description: "The main topic or focus of this coaching session")
    let topic: String
    
    @Guide(description: "Key insights about the user's health")
    let insights: [String]
    
    @Guide(description: "Personalized recommendations")
    let recommendations: [String]
    
    @Guide(description: "Goals to work towards")
    let goals: [HealthGoal]
    
    @Guide(description: "Encouraging closing message")
    let closingMessage: String
}

@Generable
struct HealthGoal {
    @Guide(description: "The specific goal description")
    let description: String
    
    @Guide(description: "Target value or metric")
    let target: String
    
    @Guide(description: "Suggested timeframe (daily, weekly, monthly)")
    let timeframe: String
    
    @Guide(description: "Tips to achieve this goal")
    let achievementTips: [String]
}
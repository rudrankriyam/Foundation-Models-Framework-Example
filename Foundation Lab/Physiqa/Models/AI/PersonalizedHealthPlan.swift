//
//  PersonalizedHealthPlan.swift
//  Physiqa
//
//  Created by Rudrank Riyam on 6/23/25.
//

import Foundation
import FoundationModels

/// AI-generated personalized health plan based on user's data
@Generable
struct PersonalizedHealthPlan {
    @Guide(description: "A catchy, personalized title for the health plan")
    let title: String

    @Guide(description: "Brief overview of the plan's focus and benefits")
    let overview: String

    @Guide(description: "Current health status summary")
    let currentStatus: HealthStatus

    @Guide(description: "Weekly health activities organized by day")
    let weeklyActivities: [DailyActivity]

    @Guide(description: "Nutrition recommendations")
    let nutritionGuidelines: NutritionPlan

    @Guide(description: "Sleep optimization strategies")
    let sleepStrategy: SleepPlan

    @Guide(description: "Key milestones to track progress")
    let milestones: [HealthMilestone]
}

@Generable
struct HealthStatus {
    @Guide(description: "Overall health assessment (excellent, good, needs improvement)")
    let overall: String

    @Guide(description: "Strengths to maintain")
    let strengths: [String]

    @Guide(description: "Areas for improvement")
    let improvementAreas: [String]

    @Guide(description: "Risk factors to monitor")
    let riskFactors: [String]
}

@Generable
struct DailyActivity {
    @Guide(description: "Day of the week")
    let day: String

    @Guide(description: "Primary exercise or activity")
    let primaryActivity: String

    @Guide(description: "Duration in minutes")
    let duration: Int

    @Guide(description: "Intensity level (low, moderate, high)")
    let intensity: String

    @Guide(description: "Alternative activities if primary isn't possible")
    let alternatives: [String]

    @Guide(description: "Recovery or rest recommendations")
    let recovery: String
}

@Generable
struct NutritionPlan {
    @Guide(description: "Daily caloric target range")
    let caloricTarget: String

    @Guide(description: "Macronutrient breakdown (proteins, carbs, fats)")
    let macroBreakdown: MacroNutrients

    @Guide(description: "Foods to emphasize")
    let emphasizeFoods: [String]

    @Guide(description: "Foods to limit or avoid")
    let limitFoods: [String]

    @Guide(description: "Hydration recommendations")
    let hydrationGoal: String

    @Guide(description: "Meal timing suggestions")
    let mealTiming: [String]
}

@Generable
struct MacroNutrients {
    @Guide(description: "Protein percentage and grams")
    let protein: String

    @Guide(description: "Carbohydrates percentage and grams")
    let carbohydrates: String

    @Guide(description: "Fats percentage and grams")
    let fats: String
}

@Generable
struct SleepPlan {
    @Guide(description: "Target sleep duration")
    let targetHours: String

    @Guide(description: "Recommended bedtime")
    let bedtime: String

    @Guide(description: "Recommended wake time")
    let wakeTime: String

    @Guide(description: "Pre-sleep routine suggestions")
    let eveningRoutine: [String]

    @Guide(description: "Sleep environment optimizations")
    let environmentTips: [String]
}

@Generable
struct HealthMilestone {
    @Guide(description: "Milestone name")
    let name: String

    @Guide(description: "Target date or timeframe")
    let targetDate: String

    @Guide(description: "Specific measurable goal")
    let measurableGoal: String

    @Guide(description: "Reward or celebration suggestion")
    let reward: String
}

//
//  HealthAnalysisTool.swift
//  Physiqa
//
//  Created by Rudrank Riyam on 6/23/25.
//

import Foundation
import FoundationModels
import SwiftData

/// Tool for AI to analyze health metrics and provide insights
struct HealthAnalysisTool: Tool {
    let name = "analyzeHealthMetrics"
    let description = "Analyze user's health metrics to provide insights, trends, and recommendations"

    @Generable
    struct Arguments {
        @Guide(
            description: "Type of analysis to perform: 'daily', 'weekly', 'trends', 'correlations', or 'comprehensive'"
        )
        var analysisType: String

        @Guide(description: "Specific metrics to focus on (optional, comma-separated)")
        var focusMetrics: String?

        @Guide(description: "Number of days to analyze (default: 7)")
        var daysToAnalyze: Int?

        @Guide(description: "Include predictions (true/false)")
        var includePredictions: Bool?
    }

    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        // In a real implementation, this would query SwiftData for health metrics
        // For now, we'll return a structured response

        let analysisType = arguments.analysisType.lowercased()
        let days = arguments.daysToAnalyze ?? 7

        switch analysisType {
        case "daily":
            return createDailyAnalysis()
        case "weekly":
            return createWeeklyAnalysis(days: days)
        case "trends":
            return createTrendsAnalysis(days: days)
        case "correlations":
            return createCorrelationsAnalysis()
        case "comprehensive":
            return createComprehensiveAnalysis(days: days, includePredictions: arguments.includePredictions ?? false)
        default:
            return GeneratedContent(properties: [
                "status": "error",
                "message": "Invalid analysis type. Use 'daily', 'weekly', 'trends', 'correlations', or 'comprehensive'"
            ])
        }
    }

    private func createDailyAnalysis() -> GeneratedContent {
        let metricsJson = """
        {
            "steps": {"value": 8432, "goal": 10000, "percentage": 84.3},
            "activeEnergy": {"value": 412, "goal": 500, "percentage": 82.4},
            "heartRate": {"average": 72, "resting": 58, "peak": 145},
            "sleep": {"hours": 7.2, "quality": "Good"}
        }
        """

        let insightsJson = """
        ["You're 84% towards your daily step goal!",
         "Your resting heart rate is excellent",
         "Consider a short walk to reach your activity goal"]
        """

        return GeneratedContent(properties: [
            "status": "success",
            "analysisType": "daily",
            "date": DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none),
            "metrics": metricsJson,
            "insights": insightsJson,
            "score": 82
        ])
    }

    private func createWeeklyAnalysis(days: Int) -> GeneratedContent {
        let averagesJson = """
        {"steps": 7845, "activeEnergy": 385, "sleep": 6.9, "heartRate": 70}
        """

        let achievementsJson = """
        ["Met step goal 5 out of 7 days",
         "Improved sleep duration by 12%",
         "Maintained consistent exercise routine"]
        """

        let improvementsJson = """
        ["Weekend activity levels dropped 30%",
         "Sleep consistency can be improved"]
        """

        return GeneratedContent(properties: [
            "status": "success",
            "analysisType": "weekly",
            "period": "\(days) days",
            "averages": averagesJson,
            "achievements": achievementsJson,
            "improvements": improvementsJson,
            "weekScore": 78
        ])
    }

    private func createTrendsAnalysis(days: Int) -> GeneratedContent {
        let trendsJson = """
        {
            "steps": {"direction": "improving", "change": "+12%"},
            "sleep": {"direction": "stable", "change": "+2%"},
            "heartRate": {"direction": "improving", "change": "-3%"},
            "weight": {"direction": "declining", "change": "-0.5kg"}
        }
        """

        let patternsJson = """
        ["Activity peaks on weekdays, drops on weekends",
         "Sleep quality improves with earlier bedtimes",
         "Heart rate variability increases after meditation"]
        """

        return GeneratedContent(properties: [
            "status": "success",
            "analysisType": "trends",
            "period": "\(days) days",
            "trends": trendsJson,
            "patterns": patternsJson
        ])
    }

    private func createCorrelationsAnalysis() -> GeneratedContent {
        let correlationsJson = """
        [
            {
                "metrics": ["steps", "sleep"],
                "strength": "moderate",
                "insight": "Days with more steps tend to have better sleep quality"
            },
            {
                "metrics": ["stress", "heartRate"],
                "strength": "strong",
                "insight": "Higher stress levels correlate with elevated heart rate"
            },
            {
                "metrics": ["activeEnergy", "mood"],
                "strength": "moderate",
                "insight": "More active days associated with better mood scores"
            }
        ]
        """

        let recommendationsJson = """
        ["Maintain daily step count for better sleep",
         "Practice stress reduction techniques to improve heart health"]
        """

        return GeneratedContent(properties: [
            "status": "success",
            "analysisType": "correlations",
            "correlations": correlationsJson,
            "recommendations": recommendationsJson
        ])
    }

    private func createComprehensiveAnalysis(days: Int, includePredictions: Bool) -> GeneratedContent {
        let strengthsJson = """
        ["Excellent cardiovascular fitness",
         "Good sleep duration",
         "Meeting most activity goals"]
        """

        let improvementsJson = """
        ["Weekend activity consistency",
         "Hydration levels",
         "Stress management"]
        """

        let recommendationsJson = """
        ["Schedule weekend activities to maintain consistency",
         "Set hydration reminders throughout the day",
         "Try 5-minute meditation breaks"]
        """

        if includePredictions {
            let predictionsJson = """
            ["Likely to meet step goal tomorrow based on weekly pattern",
             "Sleep quality may decrease if stress levels remain high",
             "Weight trend suggests reaching goal in 3-4 weeks"]
            """

            return GeneratedContent(properties: [
                "status": "success",
                "analysisType": "comprehensive",
                "period": "\(days) days",
                "healthScore": 81,
                "summary": "Overall health trending positively with room for improvement in consistency",
                "strengths": strengthsJson,
                "improvements": improvementsJson,
                "topRecommendations": recommendationsJson,
                "predictions": predictionsJson
            ])
        } else {
            return GeneratedContent(properties: [
                "status": "success",
                "analysisType": "comprehensive",
                "period": "\(days) days",
                "healthScore": 81,
                "summary": "Overall health trending positively with room for improvement in consistency",
                "strengths": strengthsJson,
                "improvements": improvementsJson,
                "topRecommendations": recommendationsJson
            ])
        }
    }
}

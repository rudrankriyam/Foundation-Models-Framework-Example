import FoundationModels
import Playgrounds

#Playground {
    // Widget instructions for ultra-brief encouragements
    let widgetInstructions = Instructions("""
        Generate brief, natural encouragements for completed workouts.
        Be genuine and conversational, like a supportive friend.
        Keep it simple and authentic, under 100 characters.
        """)

    // Notification instructions with structured constraints
    let notificationInstructions = Instructions("""
        You are a fitness coach generating notifications for workout achievements and milestones.

        For workout notifications: Title 4-6 words max, body 1-2 motivating sentences.
        For milestone notifications: Title 3-5 words celebrating milestone, body 1 encouraging sentence.

        Tone: Supportive, energetic, celebratory.
        """)

    // Widget session for short encouragements
    let widgetSession = LanguageModelSession(instructions: widgetInstructions)
    let workoutPrompt = "User just completed a 30-minute run"

    debugPrint("Widget Encouragement (Under 100 characters)")
    let widgetResponse = try await widgetSession.respond(to: workoutPrompt)
    debugPrint("Response: \(widgetResponse.content)")
    debugPrint("Character count: \(widgetResponse.content.count)")

    // Notification session for structured responses
    let notificationSession = LanguageModelSession(instructions: notificationInstructions)
    let workoutNotificationPrompt = "Generate a workout notification for completing a personal record in bench press"

    debugPrint("Workout Notification (Title + Body)")
    let workoutNotification = try await notificationSession.respond(to: workoutNotificationPrompt)
    debugPrint("Response: \(workoutNotification.content)")

    let milestonePrompt = "Generate a milestone notification for reaching 100 workouts completed"

    debugPrint("Milestone Notification (Title + Body)")
    let milestoneNotification = try await notificationSession.respond(to: milestonePrompt)
    debugPrint("Response: \(milestoneNotification.content)")
}

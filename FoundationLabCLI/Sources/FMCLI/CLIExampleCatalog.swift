import FoundationLabCore

struct CLIExampleDescriptor {
    let id: String
    let title: String
    let summary: String
}

let cliExampleDescriptors: [CLIExampleDescriptor] = [
    CLIExampleDescriptor(
        id: FoundationLabExampleDemo.basicChat.rawValue,
        title: FoundationLabExampleDemo.basicChat.title,
        summary: "Send one prompt and print a single text response."
    ),
    CLIExampleDescriptor(
        id: FoundationLabExampleDemo.structuredData.rawValue,
        title: FoundationLabExampleDemo.structuredData.title,
        summary: "Generate structured book recommendations from a prompt."
    ),
    CLIExampleDescriptor(
        id: FoundationLabExampleDemo.generationGuides.rawValue,
        title: FoundationLabExampleDemo.generationGuides.title,
        summary: "Guide structured review generation with a shared schema."
    ),
    CLIExampleDescriptor(
        id: FoundationLabExampleDemo.streaming.rawValue,
        title: FoundationLabExampleDemo.streaming.title,
        summary: "Stream text generation updates as they arrive."
    ),
    CLIExampleDescriptor(
        id: FoundationLabExampleDemo.journaling.rawValue,
        title: FoundationLabExampleDemo.journaling.title,
        summary: "Turn a journal entry into a gentle structured reflection."
    ),
    CLIExampleDescriptor(
        id: FoundationLabExampleDemo.creativeWriting.rawValue,
        title: FoundationLabExampleDemo.creativeWriting.title,
        summary: "Generate a structured story outline from a creative prompt."
    ),
    CLIExampleDescriptor(
        id: FoundationLabExampleDemo.generationOptions.rawValue,
        title: FoundationLabExampleDemo.generationOptions.title,
        summary: "Experiment with sampling, temperature, and token limits."
    ),
    CLIExampleDescriptor(
        id: "multilingual",
        title: "Multilingual Responses",
        summary: "Run localized prompts across the supported model languages."
    ),
    CLIExampleDescriptor(
        id: "language-session",
        title: "Language Session",
        summary: "Keep one session alive while switching languages and checking memory."
    ),
    CLIExampleDescriptor(
        id: "nutrition",
        title: "Localized Nutrition",
        summary: "Analyze nutrition and localize the result into a chosen language."
    )
]

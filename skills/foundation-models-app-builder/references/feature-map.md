# Feature Map

Use this reference to find working Foundation Lab examples before adding new code.

## Sessions And Text Generation

- `FoundationLabCore/Sources/FoundationLabCore/Capabilities/GenerateTextUseCase.swift`
- `FoundationLabCore/Sources/FoundationLabCore/Providers/FoundationModelsTextGenerator.swift`
- `FoundationLabCore/Sources/FoundationLabCore/Capabilities/StreamTextGenerationUseCase.swift`
- `FoundationLabCore/Sources/FoundationLabCore/Providers/FoundationModelsStreamingTextGenerator.swift`
- `BookPlaygrounds/02_GettingStartedWithSessions/`

## Conversation And Context

- `FoundationLabCore/Sources/FoundationLabCore/Capabilities/RunConversationUseCase.swift`
- `FoundationLabCore/Sources/FoundationLabCore/Providers/FoundationLabConversationEngine.swift`
- `FoundationLabCore/Sources/FoundationLabCore/Providers/FoundationLabConversationContextBuilder.swift`
- `FoundationLabCore/Sources/FoundationLabCore/Providers/FoundationModelsTranscriptTokenCounting.swift`
- `Foundation Lab/ViewModels/ChatViewModel.swift`
- `Foundation Lab/Views/Chat/`

## Structured Generation

- `FoundationLabCore/Sources/FoundationLabCore/Capabilities/GenerateStructuredDataUseCase.swift`
- `FoundationLabCore/Sources/FoundationLabCore/Providers/FoundationModelsStructuredGenerator.swift`
- `FoundationLabCore/Sources/FoundationLabCore/Models/BookRecommendation.swift`
- `FoundationLabCore/Sources/FoundationLabCore/Models/ProductReview.swift`
- `FoundationLabCore/Sources/FoundationLabCore/Models/StoryOutline.swift`
- `Foundation Lab/Views/Examples/StructuredDataView.swift`

## Dynamic Schemas

- `FoundationLabCore/Sources/FoundationLabCore/Capabilities/GenerateDynamicSchemaContentUseCase.swift`
- `FoundationLabCore/Sources/FoundationLabCore/Providers/FoundationModelsDynamicSchemaGenerator.swift`
- `Foundation Lab/Views/Examples/DynamicSchemas/`
- `Foundation Lab/Models/DynamicSchemaExampleType.swift`

## Tools And System Integrations

- `FoundationLabCore/Sources/FoundationLabCore/Providers/FoundationModelsToolInvoker.swift`
- `FoundationLabCore/Sources/FoundationLabCore/Tools/Search1WebSearchTool.swift`
- `Foundation Lab/Views/Tools/`
- `Foundation Lab/AppIntents/`
- `BookPlaygrounds/08_BasicToolUse/`

## RAG

- `Foundation Lab/Services/RAGService.swift`
- `Foundation Lab/ViewModels/RAGChatViewModel.swift`
- `Foundation Lab/Views/Examples/RAGChatView.swift`

## Voice

- `Foundation Lab/Voice/VoiceViewModel.swift`
- `Foundation Lab/Voice/VoiceView.swift`
- `Foundation Lab/Voice/Services/`
- `Foundation Lab/Voice/State/`

## Health

- `Foundation Lab/Health/`
- `FoundationLabCore/Sources/FoundationLabCore/Capabilities/AnalyzeNutritionUseCase.swift`
- `FoundationLabCore/Sources/FoundationLabCore/Capabilities/QueryHealthDataUseCase.swift`
- `FoundationLabCore/Sources/FoundationLabCore/Providers/FoundationModelsHealthDataQuerier.swift`

## Languages

- `FoundationLabCore/Sources/FoundationLabCore/Capabilities/ListSupportedLanguagesUseCase.swift`
- `FoundationLabCore/Sources/FoundationLabCore/Capabilities/GenerateMultilingualResponsesUseCase.swift`
- `Foundation Lab/Services/LanguageService.swift`
- `Foundation Lab/Views/Languages/`
- `BookPlaygrounds/13_SupportedLanguagesAndInternationalization/`

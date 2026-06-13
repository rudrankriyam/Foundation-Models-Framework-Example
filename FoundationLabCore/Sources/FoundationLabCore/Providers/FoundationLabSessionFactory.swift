import Foundation
import FoundationModels

enum FoundationLabSessionFactory {
    static func makeSession(
        runtime: FoundationLabModelRuntime,
        model: SystemLanguageModel,
        tools: [any Tool],
        instructions: String
    ) -> LanguageModelSession {
        #if compiler(>=6.4)
        if runtime == .privateCloudCompute {
            if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
                return makePrivateCloudSession(
                    tools: tools,
                    instructions: instructions
                )
            }
        }
        #endif

        return makeOnDeviceSession(
            model: model,
            tools: tools,
            instructions: instructions
        )
    }

    private static func makeOnDeviceSession(
        model: SystemLanguageModel,
        tools: [any Tool],
        instructions: String
    ) -> LanguageModelSession {
        let trimmedInstructions = instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tools.isEmpty {
            if trimmedInstructions.isEmpty {
                return LanguageModelSession(model: model, tools: tools)
            }
            return LanguageModelSession(
                model: model,
                tools: tools,
                instructions: Instructions(trimmedInstructions)
            )
        }

        if trimmedInstructions.isEmpty {
            return LanguageModelSession(model: model)
        }

        return LanguageModelSession(
            model: model,
            instructions: Instructions(trimmedInstructions)
        )
    }

    #if compiler(>=6.4)
    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    private static func makePrivateCloudSession(
        tools: [any Tool],
        instructions: String
    ) -> LanguageModelSession {
        let model = PrivateCloudComputeLanguageModel()
        let trimmedInstructions = instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tools.isEmpty {
            if trimmedInstructions.isEmpty {
                return LanguageModelSession(model: model, tools: tools)
            }
            return LanguageModelSession(
                model: model,
                tools: tools,
                instructions: Instructions(trimmedInstructions)
            )
        }

        if trimmedInstructions.isEmpty {
            return LanguageModelSession(model: model)
        }

        return LanguageModelSession(
            model: model,
            instructions: Instructions(trimmedInstructions)
        )
    }
    #endif
}

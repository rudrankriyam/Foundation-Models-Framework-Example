import Foundation
import FoundationModels
import XCTest
@testable import FoundationLabCore

@Generable
struct ModelConfigurationTestOutput {
    let value: String
}

final class FoundationLabModelConfigurationTests: XCTestCase {
    func testModelOptionsUseStableCommandLineIdentifiers() {
        XCTAssertEqual(FoundationLabModelUseCase.contentTagging.rawValue, "content-tagging")
        XCTAssertEqual(
            FoundationLabGuardrails.permissiveContentTransformations.rawValue,
            "permissiveContentTransformations"
        )
    }

    func testStructuredRequestPreservesAdapterAndGenerationControls() {
        let adapterURL = URL(fileURLWithPath: "/tmp/Test.fmadapter")
        let options = FoundationLabGenerationOptions(
            sampling: .greedy,
            temperature: 0.2,
            maximumResponseTokens: 128
        )
        let request = StructuredGenerationRequest<ModelConfigurationTestOutput>(
            prompt: "Extract a value",
            adapterURL: adapterURL,
            generationOptions: options,
            includeSchemaInPrompt: false,
            context: CapabilityInvocationContext(source: .cli)
        )

        XCTAssertEqual(request.adapterURL, adapterURL)
        XCTAssertEqual(request.generationOptions, options)
        XCTAssertFalse(request.includeSchemaInPrompt)
    }

    func testModelFactoryRejectsCustomGuardrailsForAdapters() {
        XCTAssertThrowsError(
            try FoundationModelsModelFactory.makeModel(
                guardrails: .permissiveContentTransformations,
                adapterURL: URL(fileURLWithPath: "/tmp/Test.fmadapter")
            )
        ) { error in
            XCTAssertEqual(
                error as? FoundationLabCoreError,
                .invalidRequest(
                    "Foundation Models adapters only support the framework's default guardrails."
                )
            )
        }
    }
}

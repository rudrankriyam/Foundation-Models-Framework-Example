//
//  01_BasicToolProtocol.swift
//  Exploring Foundation Models
//
//  Created by Rudrank Riyam on 9/24/25.
//

import Foundation
import FoundationModels
import Playgrounds

struct BasicTool: Tool {
    let name = "basicTool"
    let description = "A simple example tool that shows how to implement the Tool protocol structure"

    @Generable
    struct Arguments {
        @Guide(description: "The input message to process")
        var message: String
    }

    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        "Processed: \(arguments.message)"
    }
}

#Playground {
    let tool = BasicTool()

    let arguments = BasicTool.Arguments(message: "Hello, tool!")
    let result = try await tool.call(arguments: arguments)

    debugPrint("Tool result: \(result)")
}

//
//  DynamicSchemaExecutorExtension.swift
//  FoundationLab
//
//  Created by Assistant on 7/3/25.
//

import Foundation
import FoundationModels

extension ExampleExecutor {
    /// Execute a custom async operation and capture the result
    func execute(_ operation: @escaping () async throws -> String) async {
        isRunning = true
        errorMessage = nil
        result = ""
        
        do {
            result = try await operation()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isRunning = false
    }
}
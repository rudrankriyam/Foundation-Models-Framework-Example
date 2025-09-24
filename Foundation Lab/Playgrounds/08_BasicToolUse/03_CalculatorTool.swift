//
//  03_CalculatorTool.swift
//  Exploring Foundation Models
//
//  Created by Rudrank Riyam on 9/24/25.
//

import Foundation
import FoundationModels
import Playgrounds

struct CalculatorTool: Tool {
    let name = "calculate"
    let description = "Perform basic mathematical calculations including addition, subtraction, multiplication, and division"

    @Generable
    struct Arguments {
        @Guide(description: "The first number in the calculation")
        var firstNumber: Double

        @Guide(description: "The mathematical operation: 'add', 'subtract', 'multiply', or 'divide'")
        var operation: String

        @Guide(description: "The second number in the calculation")
        var secondNumber: Double
    }

    @Generable
    struct CalculationResult {
        let operation: String
        let firstNumber: Double
        let secondNumber: Double
        let result: Double
        let expression: String
    }

    func call(arguments: Arguments) async throws -> CalculationResult {
        let operation = arguments.operation.lowercased()

        guard let result = performCalculation(
            first: arguments.firstNumber,
            operation: operation,
            second: arguments.secondNumber
        ) else {
            if operation == "divide" && arguments.secondNumber == 0 {
                throw CalculationError.divisionByZero
            } else {
                throw CalculationError.unsupportedOperation(operation)
            }
        }

        let expression = formatExpression(
            first: arguments.firstNumber,
            operation: operation,
            second: arguments.secondNumber,
            result: result
        )

        return CalculationResult(
            operation: operation,
            firstNumber: arguments.firstNumber,
            secondNumber: arguments.secondNumber,
            result: result,
            expression: expression
        )
    }

    private func performCalculation(first: Double, operation: String, second: Double) -> Double? {
        switch operation {
        case "add", "addition", "+":
            return first + second
        case "subtract", "subtraction", "-":
            return first - second
        case "multiply", "multiplication", "*":
            return first * second
        case "divide", "division", "/":
            return second != 0 ? first / second : nil
        default:
            return nil
        }
    }

    private func formatExpression(first: Double, operation: String, second: Double, result: Double) -> String {
        let operatorSymbol = getOperatorSymbol(for: operation)
        return "\(formatNumber(first)) \(operatorSymbol) \(formatNumber(second)) = \(formatNumber(result))"
    }

    private func getOperatorSymbol(for operation: String) -> String {
        switch operation {
        case "add", "addition": return "+"
        case "subtract", "subtraction": return "-"
        case "multiply", "multiplication": return "×"
        case "divide", "division": return "÷"
        default: return operation
        }
    }

    private func formatNumber(_ number: Double) -> String {
        if number.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(number))
        } else {
            return String(format: "%.2f", number)
        }
    }

    enum CalculationError: Error, LocalizedError {
        case divisionByZero
        case unsupportedOperation(String)

        var errorDescription: String? {
            switch self {
            case .divisionByZero:
                return "Cannot divide by zero"
            case .unsupportedOperation(let operation):
                return "Unsupported operation: '\(operation)'. Use 'add', 'subtract', 'multiply', or 'divide'."
            }
        }
    }
}

#Playground {
    let calculator = CalculatorTool()

    let arguments = CalculatorTool.Arguments(
        firstNumber: 15.5,
        operation: "multiply",
        secondNumber: 3.2
    )

    let result = try await calculator.call(arguments: arguments)
    debugPrint("Calculation result: \(result)")
}
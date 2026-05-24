# Tool Calling

Use this reference when Foundation Models needs app capabilities such as weather, search, contacts, calendar, reminders, location, HealthKit, music, or web metadata.

Tool calling is app integration work. Model the intent, permissions, validation, failure cases, and user confirmation.

## Basic Tool

```swift
import Foundation
import FoundationModels

struct CalculatorTool: Tool {
    let name = "calculate"
    let description = "Perform basic arithmetic."

    @Generable
    struct Arguments: Sendable {
        let firstNumber: Double
        let operation: Operation
        let secondNumber: Double
    }

    @Generable
    enum Operation: Sendable {
        case add
        case subtract
        case multiply
        case divide
    }

    @Generable
    struct CalculationResult: Sendable {
        let expression: String
        let result: Double
    }

    enum CalculationError: Error, LocalizedError {
        case divisionByZero

        var errorDescription: String? {
            switch self {
            case .divisionByZero:
                "Cannot divide by zero."
            }
        }
    }

    func call(arguments: Arguments) async throws -> CalculationResult {
        let result = switch arguments.operation {
        case .add:
            arguments.firstNumber + arguments.secondNumber
        case .subtract:
            arguments.firstNumber - arguments.secondNumber
        case .multiply:
            arguments.firstNumber * arguments.secondNumber
        case .divide:
            guard arguments.secondNumber != 0 else {
                throw CalculationError.divisionByZero
            }
            arguments.firstNumber / arguments.secondNumber
        }

        return CalculationResult(
            expression: "\(arguments.firstNumber) \(arguments.operation.symbol) \(arguments.secondNumber)",
            result: result
        )
    }
}

private extension CalculatorTool.Operation {
    var symbol: String {
        switch self {
        case .add: "+"
        case .subtract: "-"
        case .multiply: "*"
        case .divide: "/"
        }
    }
}
```

## Session With Tool

```swift
let session = LanguageModelSession(
    tools: [CalculatorTool()],
    instructions: "Use the calculator tool for arithmetic. Explain the result briefly."
)

let response = try await session.respond(
    to: Prompt("What is 19.5 multiplied by 4.2?")
)
```

## Recoverable Tool Output

Prefer structured failure output when the model can recover. Throw when the app should stop execution.

```swift
@Generable
struct ToolResult: Sendable {
    let success: Bool
    let message: String
    let value: String?
}
```

## Write Tool Confirmation

For tools that write data, split planning from committing.

```swift
@Generable
struct ReminderDraft: Sendable {
    let title: String
    let dueDateDescription: String?
    let priority: Priority

    @Generable
    enum Priority: Sendable {
        case low
        case medium
        case high
    }
}
```

Flow:

1. Let the model create a draft.
2. Show the draft to the user.
3. Commit to Reminders, Calendar, Contacts, or files only after explicit confirmation.

## Permission Boundaries

- Contacts: search narrowly; do not pass full address books to the model.
- Calendar: preview event creation before saving.
- Reminders: preview title, due date, priority, and notes.
- Location: request foreground location only when needed.
- Music: handle no subscription or denied media access.
- HealthKit: expose selected metrics and date ranges clearly.

## Tool Design Checklist

- The `name` is short and action-oriented.
- The `description` tells the model when to use the tool.
- Arguments are strongly typed and constrained with `@Generable`.
- The tool validates input before touching app data.
- The output is bounded and does not leak unnecessary private data.
- Permission denial is a normal result path.

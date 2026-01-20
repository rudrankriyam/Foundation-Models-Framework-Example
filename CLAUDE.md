# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Foundation Models Benchmark framework that measures Apple Intelligence performance across macOS, iOS, iPadOS, and visionOS. The project consists of two main components:

1. **BenchmarkCore** - A Swift Package Manager (SPM) library with the core benchmarking logic
2. **FoundationStudio** - An Xcode project containing tests and UI components

## Requirements

- Xcode 26.0 or newer (with SDKs for macOS 26, iOS 26, iPadOS 26, visionOS 26)
- Apple Intelligence enabled on the test device
- Swift 6.2+

## Common Commands

### Building the Swift Package

```bash
# Build BenchmarkCore package
cd BenchmarkCore
swift build                    # Debug build
swift build -c Release         # Release build

# Build and run the CLI
./benchmark                    # Run normal benchmark (Release)
./benchmark --debug            # Run with debug configuration

# Build from root directory
cd BenchmarkCore && swift build -c Release
```

### Running Tests

```bash
# Run all tests in Xcode
Cmd+U                          # All tests
Control+Option+Command+U       # Specific test method

# Run tests via command line
xcodebuild test -project FoundationStudio.xcodeproj -scheme FoundationStudioTests -destination "platform=macOS"
xcodebuild test -project FoundationStudio.xcodeproj -scheme FoundationStudioTests -destination "platform=iOS,name=Rudrank 17 Pro"
xcodebuild test -project FoundationStudio.xcodeproj -scheme FoundationStudioTests -destination "platform=iOS Simulator,name=iPhone 17 Pro"
```

### Code Quality

```bash
# Run SwiftLint on the project
swiftlint
swiftlint --fix               # Auto-fix issues where possible

# SwiftLint is configured to check:
# - BenchmarkCore/Sources
# - FoundationStudio/FoundationStudio
```

### Package Management

```bash
# The BenchmarkCore package has two products:
# 1. BenchmarkCore library (used by other modules)
# 2. BenchmarkCLI executable (CLI tool entry point)

# Package.swift location: BenchmarkCore/Package.swift
```

## Code Architecture

### Core Components

**BenchmarkCore (Swift Package)**

Located in `BenchmarkCore/Sources/`:

- **BenchmarkRunner.swift** - Main actor that executes benchmarks by sending prompts to the system language model and measuring performance metrics. Uses `LanguageModelSession.streamResponse()` to get streaming responses.

- **BenchmarkRunnerConfiguration.swift** - Configuration struct that holds the prompt and generation options for benchmarks. Defaults to `.productDesign` prompt with greedy sampling.

- **BenchmarkPrompt.swift** (in `Prompts.swift`) - Defines benchmark prompts with system instructions and user prompts. Includes `.productDesign` - a canonical prompt designed to stress throughput with maximum token output (25 paragraphs).

- **Environment.swift** - Captures execution environment including device info, CPU/GPU model, RAM, OS version, and locale. Platform-specific implementations for macOS, iOS, and visionOS.

- **Metrics.swift** - Data structures for storing benchmark results:
  - `BenchmarkMetrics` - performance metrics (duration, TTFT, token counts, TPS)
  - `BenchmarkResult` - complete benchmark result with prompt, metrics, environment, and response
  - `BenchmarkReport` - serialization to JSON/Markdown

- **Utilities.swift** - Token estimation utilities with calibrated ratios:
  - Input tokens: ~4.5 chars/token (based on xctrace data)
  - Output tokens: ~6.0 chars/token
  - Uses `Transcript.Entry` extensions to estimate tokens from session data

- **BenchmarkCLI/main.swift** - CLI entry point that orchestrates benchmark execution. Supports normal mode and xctrace recording mode.

**FoundationStudio (Xcode Project)**

Located in `FoundationStudio/`:

- **FoundationStudioTests/** - Test target with `BenchmarkTests.swift` that runs the actual benchmark as an XCTest and validates results (asserts >1000 response tokens and >10 TPS)

### Key Dependencies

- **FoundationModels** - Apple's Foundation Models framework (SystemLanguageModel, LanguageModelSession, etc.)
- The project uses the system language model (`SystemLanguageModel.default`) for benchmarking

### Token Measurement

The framework supports two modes for measuring tokens:

1. **Estimated tokens** - Uses calibrated character-to-token ratios based on xctrace data
2. **Actual tokens** - Use xctrace's Foundation Models instrument:
   ```bash
   xctrace record --instrument 'Foundation Models' \
     --output token-test.trace \
     --launch -- ./BenchmarkCLI -- token-test
   ```

## Platform-Specific Notes

- **macOS**: Displays specific GPU model (e.g., "Apple M5 10-core") using `system_profiler`
- **iOS/iPadOS/visionOS**: GPU shown as "Apple GPU" (platform limitation)
- **CPU detection**: Uses platform-specific mechanisms (sysctl on macOS, ProcessInfo on iOS)

## Development Workflow

1. **For CLI changes**: Edit files in `BenchmarkCore/Sources/`, then rebuild with `./benchmark --debug`
2. **For test changes**: Edit files in `FoundationStudio/FoundationStudioTests/`, run tests with Cmd+U
3. **For UI changes**: Edit files in `FoundationStudio/FoundationStudio/`
4. **Linting**: Run `swiftlint` before committing; auto-fix with `swiftlint --fix`

## VSCode Configuration

- Debug configurations available in `.vscode/launch.json` for both Debug and Release builds of BenchmarkCLI
- Working directory: `BenchmarkCore`
- Swift extension settings apply to the entire workspace

## Testing Strategy

Tests run actual benchmarks by calling the language model, so they:
- Require Apple Intelligence to be enabled
- Take ~15-20 seconds to complete
- Display detailed ASCII banners and environment info
- Assert on minimum performance thresholds

## Important Implementation Details

- **Actors**: `BenchmarkRunner` is an actor to ensure thread-safe async operations
- **Streaming**: Uses `LanguageModelSession.streamResponse()` for real-time token streaming
- **Error Handling**: Catches `SystemLanguageModel.Availability.UnavailableReason` for model unavailability
- **Calibration**: Token estimation calibrated against xctrace measurements from actual benchmark runs
- **Platform Detection**: Uses compiler directives (`#if os(macOS)`) for platform-specific code paths

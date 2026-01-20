# Foundation Models Benchmark Tests

This test suite provides a simple, fast way to benchmark Foundation Models performance on any device or simulator.

## Why Tests?

- **Super Fast**: Just press Cmd+U
- **Any Device**: Select from Xcode's device dropdown
- **Console Output**: Direct to Xcode console, no UI needed
- **Automated**: Works great in CI/CD
- **Multiple Tests**: Compare runs, custom prompts, statistics
- **No Manual Work**: No buttons to tap, no copy/paste needed

## How to Use

### 1. Select Your Device
In Xcode, use the device selector dropdown at the top to choose:
- A physical device (iPhone, iPad, Mac)
- A simulator (iOS Simulator, VisionOS Simulator)

### 2. Run Tests
Press **Cmd+U** to run all benchmark tests, or:
- Place cursor in test method and press **Control+Option+Command+U** to run a specific test
- Use the test navigator to run individual tests

### 3. View Results
Check the **Xcode console** (View → Debug Area → Show Debug Area) for formatted results:

```
================================================================================
FOUNDATION MODELS BENCHMARK - Product Design Prompt
================================================================================

Environment
----------------------------------------
Device: iPhone 17 Pro
OS: iOS 26.1
Locale: en_US
Timestamp: 2025-11-30 23:45:00+09:00

Performance Metrics
----------------------------------------
Duration: 38.42s
Time to First Token: 0.66s
Prompt Tokens (est.): 228
Response Tokens (est.): 2,280
Total Tokens (est.): 2,508
Tokens/sec: 65.44

Response Preview
----------------------------------------
1. Why Morning Routines Matter
...

================================================================================
```

## Available Tests

### testProductDesignBenchmark
Runs a single benchmark with the comprehensive `.productDesign` prompt.

**Validates:**
- Response tokens > 1000
- Tokens/sec > 10

### testMultipleBenchmarkRuns
Runs 3 benchmark iterations and calculates statistics:
- Average tokens/sec
- Min/Max tokens/sec
- Variance

**Perfect for:**
- Measuring consistency
- Comparing performance across devices
- Finding performance regressions

### testCustomPromptBenchmark
Runs a benchmark with a custom prompt about neural networks.

**Validates:**
- Response tokens > 100
- Tokens/sec > 5

## Example Output - Multiple Runs

```
================================================================================
MULTIPLE BENCHMARK RUNS (3 iterations)
================================================================================

Run #1
----------------------------------------
Duration: 38.42s
Time to First Token: 0.66s
Total Tokens: 2,508
Tokens/sec: 65.44

Run #2
----------------------------------------
Duration: 39.01s
Time to First Token: 0.68s
Total Tokens: 2,511
Tokens/sec: 64.37

Run #3
----------------------------------------
Duration: 38.75s
Time to First Token: 0.67s
Total Tokens: 2,505
Tokens/sec: 64.65

Summary
----------------------------------------
Average Tokens/sec: 64.82
Min Tokens/sec: 64.37
Max Tokens/sec: 65.44
Variance: 1.07
```

## Customization

### Add More Tests

Create new test methods in `BenchmarkTests.swift`:

```swift
func testYourCustomBenchmark() async throws {
    let customPrompt = BenchmarkPrompt(
        instructions: "Your instructions",
        userPrompt: "Your prompt"
    )
    let config = BenchmarkRunnerConfiguration(prompt: customPrompt)
    let runner = BenchmarkRunner(configuration: config)
    let result = try await runner.run()

    print("Your custom results...")
    print("Duration: \(result.metrics.duration)")
    print("Tokens/sec: \(result.metrics.tokensPerSecond ?? 0)")

    XCTAssertGreaterThan(result.metrics.tokensPerSecond ?? 0, 10)
}
```

### Different Generation Options

```swift
import FoundationModels

let options = GenerationOptions(
    sampling: .greedy,
    temperature: 0.0  // Completely deterministic
)

let config = BenchmarkRunnerConfiguration(
    prompt: customPrompt,
    options: options
)
```

## Troubleshooting

### Model Unavailable
If you see "Apple Intelligence is unavailable":
- Ensure you're on macOS 26.0+ or iOS 26.0+
- Check that Foundation Models framework is available
- System Language Model must be configured

### Long Test Duration
Tests take 30-90 seconds each (depends on device/model).
Use individual tests to test just what you need:
- `testProductDesignBenchmark` is the quickest
- `testMultipleBenchmarkRuns` takes ~3x longer

### Device Selection
Make sure to:
1. Select your target device
2. Build and run tests (Cmd+U)
3. Check console for results

## Benefits Over UI

| Feature | UI Approach | Test Approach |
|---------|-------------|---------------|
| **Speed** | Tap, wait, copy | Cmd+U |
| **Device Testing** | Build & run on each | Switch device, Cmd+U |
| **Automation** | Manual only | CI/CD ready |
| **Output** | Copy/paste needed | Console display |
| **Multiple Runs** | Manual repetition | Automatic |
| **Statistics** | Calculate yourself | Auto-calculated |

## CI/CD

Run tests in GitHub Actions:

```yaml
- name: Run Foundation Models Benchmark
  run: |
    xcodebuild test \
      -project FoundationStudio.xcodeproj \
      -scheme FoundationStudio \
      -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
      -testPlan FoundationStudioTests
```

## Contributing

When adding new tests:
1. Use descriptive test names
2. Print clear, formatted output
3. Add appropriate assertions (XCTAssertGreaterThan, etc.)
4. Include validation for reasonable metrics
5. Document what the test validates

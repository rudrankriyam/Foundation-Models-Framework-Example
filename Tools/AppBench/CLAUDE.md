# Foundation Models AppBench

## Purpose

AppBench evaluates practical Foundation Models workloads across Apple devices, OS
builds, the on-device model, and Private Cloud Compute. Quality and performance must
always remain separate metrics.

## Requirements

- Swift 6.2+
- Xcode 26+ for the OS 26-compatible core
- Xcode 27 for PCC code paths
- Apple Intelligence enabled on supported physical hardware

## Commands

```bash
./appbench list
./appbench --suite quick --model on-device --repetitions 3
cd BenchmarkCore && swift test

DEVELOPER_DIR=/Users/rudrank/Downloads/Xcode-beta.app/Contents/Developer \
  xcodebuild -project AppBenchDeviceRunner/AppBenchDeviceRunner.xcodeproj \
  -scheme AppBenchDeviceRunner \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Architecture

- `BenchmarkCore/Sources/AppBenchCore`: scenarios, deterministic graders, model runner,
  metrics, statistics, environment capture, and reports.
- `BenchmarkCore/Sources/AppBenchCLI`: canonical runner for official Mac results.
- `AppBenchDeviceRunner/AppBenchDeviceRunner`: signed iOS harness for physical-device
  iPhone and iPad results.
- `BenchmarkCore/Tests/AppBenchCoreTests`: offline grading/statistics tests.
- `AppBenchDeviceRunner/AppBenchDeviceRunnerTests`: live model smoke test.

## Rules

- Keep OS 26 compatibility unless a file is compiler- and availability-gated.
- Prefer deterministic checks over LLM judges.
- Prompt pass requires every check to pass.
- Output throughput must use output tokens and decode duration only.
- Never call snapshot timing inter-token latency.
- Preserve failures in reports.
- Include OS build, thermal state, Low Power Mode, and timestamp.
- PCC results are service measurements, not device inference measurements.
- Add new scenarios using synthetic fixtures, clear provenance, and inspectable checks.
- Never publish simulator results. Use the CLI on Mac and the device runner on a
  physical iPhone or iPad.
- Do not commit raw `.trace` bundles.

Read `docs/METHODOLOGY.md` before changing metrics or evaluation behavior.

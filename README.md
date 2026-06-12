# Foundation Models AppBench

Foundation Models AppBench measures real application workloads across Apple devices,
OS releases, the on-device system model, and Private Cloud Compute.

It reports **quality and performance separately**. A fast incorrect response remains
incorrect; a high-quality response does not hide poor latency.

Guided generation structure is not counted as quality. AppBench grades the semantic
values inside a framework-constrained response, not JSON validity that decoding already
guarantees.

## Included Scenarios

The starter corpus uses synthetic, reproducible inputs modeled after app experiences
Apple highlighted in its
[Foundation Models framework app showcase](https://www.apple.com/newsroom/2025/09/apples-foundation-models-framework-unlocks-new-intelligent-app-experiences/).

| Scenario | App pattern | Primary quality signal |
| --- | --- | --- |
| Natural-language task capture | Stuff, OmniFocus | Exact structured fields |
| Stacked notification summary | Stoic, Gratitude | Required facts and word limit |
| Journal reflection | Stoic, Gratitude | Grounding and instruction following |
| Habit classification | Motivation, Streaks, Vocabulary | Exact constrained category |
| Workout plan | SmartGym, 7 Minute Workout, Train Fitness | Schema and constraint compliance |
| Grounded document answer | Signeasy, Agenda, Essayist, CellWalk, Platzi | Exact answer and citations |
| Synthetic sustained generation | Original repository workload | Decode throughput |

The app inputs are original synthetic fixtures. App names describe the product pattern
that inspired each workload; AppBench does not reproduce proprietary app data.

## Metrics

Every measured trial records:

- Prompt-level pass: every deterministic constraint passed.
- Constraint score: fraction of individual checks passed.
- End-to-end duration.
- Time to first token (TTFT).
- Decode duration.
- Estimated output tokens per second.
- Output characters per second.
- Stream update count and maximum stream-update gap.
- Device, chip, memory, OS version/build, locale, thermal state, and Low Power Mode.

Token counts are calibrated estimates unless an Instruments trace is captured. Decode
throughput uses **output tokens only** and excludes TTFT.

Each scenario summary reports median, p90, mean, range, and standard deviation.

## Run

Requirements:

- Xcode 26 or newer.
- macOS/iOS/iPadOS/visionOS 26 or newer.
- Apple Intelligence enabled on a supported physical device.
- Xcode 27 and the managed PCC entitlement for Private Cloud Compute.

```bash
# List workloads
./appbench list

# Practical suite, one warmup and three measured repetitions
./appbench --suite quick --model on-device

# Full practical suite with export
./appbench --suite full --repetitions 5 \
  --json Results/macbook-m5-macos-27.json \
  --markdown Results/macbook-m5-macos-27.md

# Original sustained-generation workload
./appbench --suite performance --repetitions 5

# OS 27 PCC, when the executable has the approved entitlement
DEVELOPER_DIR=/path/to/Xcode-beta.app/Contents/Developer \
  ./appbench --suite quick --model pcc
```

The legacy `./benchmark` command remains as a compatibility wrapper.

## App

Open `FoundationStudio/FoundationStudio.xcodeproj`. The app provides controls for:

- Practical Quick, Practical Full, and Synthetic Performance suites.
- On-device and PCC execution.
- Warmup count and measured repetitions.
- Per-scenario prompt pass, constraint score, median TTFT, and median output speed.
- Markdown report copying.

## OS 26 vs OS 27

Use the same physical device, fixtures, sampling, warmups, and repetition count.

Recommended initial matrix:

| Device | OS | Model |
| --- | --- | --- |
| MacBook Pro M5 | macOS 26 | On-device |
| MacBook Pro M5 | macOS 27 | On-device |
| MacBook Pro M5 | macOS 27 | PCC |
| iPhone 16 Pro Max | iOS 26 | On-device |
| iPhone 16 Pro Max | iOS 27 | On-device |
| iPhone 16 Pro Max | iOS 27 | PCC |

PCC measures end-to-end service behavior, including network and server time. It is not
a measurement of the client device’s inference speed. PCC can change server-side
without an OS update, so every result must retain its timestamp and OS build.

See [Methodology](docs/METHODOLOGY.md), [Device Matrix](docs/DEVICE_MATRIX.md),
and [Migration Notes](docs/MIGRATION.md).

## Package

`BenchmarkCore/Package.swift` exports:

- `AppBenchCore`: scenarios, graders, runner, statistics, and reports.
- `AppBenchCLI`: command-line experiment runner.
- `BenchmarkCore`: compatibility product that exposes the `AppBenchCore` module.

## License

MIT. See [LICENSE](LICENSE).

[![Star History Chart](https://api.star-history.com/svg?repos=rudrankriyam/Foundation-Models-AppBench&type=Date)](https://star-history.com/#rudrankriyam/Foundation-Models-AppBench&Date)

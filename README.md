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

| Workload | App pattern | Primary quality signal |
| --- | --- | --- |
| Natural-language task parsing | Stuff, OmniFocus | Exact date, list, title, and tags |
| Workout generation | SmartGym, 7 Minute Workout | Constraint compliance |
| Journal summarization | Stoic, Gratitude | Grounding, completeness, and length |
| Classification | Motivation, Streaks, Vocabulary | Exact category |
| Grounded explanation | CellWalk, Platzi | Tool selection, arguments, and grounding |
| Exercise substitution | Train Fitness | Tool arguments and recommendation validity |
| Document question answering | Signeasy, Agenda | Answer and citation accuracy |
| Citation extraction | Essayist | Exact bibliographic fields |
| Creative writing | Detail | Instruction and length compliance |
| Visual recommendation | VLLO, SwingVision | Image-grounded recommendation |
| Synthetic sustained generation | Original repository workload | Decode throughput |

Each practical workload has 25 fixed samples: five semantic cases across five prompt
phrasings. The app inputs and generated image fixture are original and synthetic. App
names describe the product pattern that inspired each workload; AppBench does not
reproduce proprietary app data.

## Metrics

Every measured trial records:

- Prompt-level pass: every deterministic constraint passed.
- Constraint score: fraction of individual checks passed.
- End-to-end duration.
- Time to first token (TTFT).
- Decode duration.
- Output tokens per second, using Apple's tokenizer for on-device OS 26.4+ runs.
- Output characters per second.
- Stream update count and maximum stream-update gap.
- Input, output, and reasoning token usage where OS 27 exposes it.
- Runtime model context size and per-trial context utilization.
- Starting, ending, and peak observed process memory.
- Starting, ending, and worst observed thermal state.
- Tool names and typed arguments.
- Requested model, executed model, and fallback reason.
- PCC quota state before and after the run.
- Device, chip, total memory, OS version/build, locale, and Low Power Mode.

Decode throughput uses **output tokens only** and excludes TTFT. On older on-device
systems and PCC runs, AppBench records a calibrated character estimate and marks
the source in each trial.

Each scenario summary reports median, p90, mean, range, standard deviation, prompt
pass, constraint score, and execution failure rate.

## Run

Requirements:

- Xcode 26 or newer.
- macOS/iOS/iPadOS/visionOS 26 or newer.
- Apple Intelligence enabled on a supported physical device.
- Xcode 27 and the managed PCC entitlement for Private Cloud Compute.

```bash
# List workloads
./appbench list

# Practical quick suite, five warmups and twenty measured repetitions
./appbench --suite quick --model on-device

# Full 250-sample practical corpus with export
./appbench --suite full --warmups 5 --repetitions 20 \
  --json Results/macbook-m5-macos-27.json \
  --markdown Results/macbook-m5-macos-27.md

# Compare cold sessions with reused conversational sessions
./appbench --suite quick --session warm --seed 20260929

# Original sustained-generation workload
./appbench --suite performance --repetitions 20

# Long-context retrieval and explicit offline experiment label
./appbench --suite context --connectivity offline

# OS 27 PCC, when the executable has the approved entitlement
DEVELOPER_DIR=/path/to/Xcode-beta.app/Contents/Developer \
  ./appbench --suite quick --model pcc --reasoning moderate \
  --fallback on-device
```

The legacy `./benchmark` command remains as a compatibility wrapper.
Set `APPBENCH_DEVICE_NAME` when you want a friendly public label; otherwise
AppBench uses the non-personal hardware identifier rather than the machine
hostname.

To pair a run with Apple's Foundation Models Instrument:

```bash
cd BenchmarkCore
./run-trace.sh --suite quick --samples 1 --repetitions 1 --no-randomize
```

## App

Open `FoundationStudio/FoundationStudio.xcodeproj`. The app provides controls for:

- Practical Quick, Practical Full, and Synthetic Performance suites.
- On-device and PCC execution.
- Five-warmup/twenty-run publishable defaults.
- One or all 25 samples per workload.
- Cold or reused sessions and randomized order.
- PCC reasoning level and on-device fallback.
- Normal or user-induced offline experiment labels.
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
without an OS update, so every result retains its timestamp and OS build. AppBench
records Apple's qualitative quota state; the API does not expose numeric request or
token consumption.

See [Methodology](docs/METHODOLOGY.md),
[Research Notes](docs/RESEARCH_NOTES.md),
[OS 26 vs OS 27](docs/OS_26_VS_27.md),
[PCC Notes](docs/PCC.md),
[Device Matrix](docs/DEVICE_MATRIX.md), and
[Migration Notes](docs/MIGRATION.md).

## Current Baseline

The first curated baseline was captured on June 12, 2026, using a MacBook Pro
with Apple M5 and 32 GB of memory on macOS 27 beta build `26A5353q`.

- Practical suite: 25/25 measured trials passed every semantic check.
- Synthetic sustained generation: median TTFT `0.413s`, median decode rate
  `55.35 tok/s`.
- Thermal state remained nominal and Low Power Mode was off.
- PCC was unavailable in the current system context and the failed attempt is
  retained rather than omitted.

That baseline predates the 250-sample practical corpus and is retained as historical
performance data. It must not be compared as if it were a run of the expanded suite.

See [Results](Results/README.md) for the reports and the limits on interpreting
this single-device baseline. Pre-AppBench community measurements are preserved
in [Legacy Results](docs/LEGACY_RESULTS.md), but their throughput formula is not
comparable with current reports.

## Package

`BenchmarkCore/Package.swift` exports:

- `AppBenchCore`: scenarios, graders, runner, statistics, and reports.
- `AppBenchEvaluations`: OS 27 adapter for Evaluations samples and evaluators.
- `AppBenchCLI`: command-line experiment runner.
- `BenchmarkCore`: compatibility product that exposes the `AppBenchCore` module.

## License

MIT. See [LICENSE](LICENSE).

[![Star History Chart](https://api.star-history.com/svg?repos=rudrankriyam/Foundation-Models-AppBench&type=Date)](https://star-history.com/#rudrankriyam/Foundation-Models-AppBench&Date)

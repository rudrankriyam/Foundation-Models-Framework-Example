# AppBench Live Tests

`AppBenchLiveTests` runs a real Foundation Models scenario through `AppBenchCore`.
It is intentionally a smoke test rather than the primary benchmark runner.

## Run

1. Open `FoundationStudio.xcodeproj`.
2. Select a physical Apple Intelligence device or the local Mac.
3. Run `AppBenchLiveTests/testPracticalTaskCaptureScenario`.

The test asserts that one measured trial completed and prints the same Markdown
report used by the CLI. Simulators may report that the system model is unavailable.

For publishable measurements, use the app or CLI with at least one warmup and five
measured repetitions:

```bash
./appbench --suite quick --warmups 1 --repetitions 5
```

Do not add fixed performance thresholds to live tests. Throughput and latency vary
by hardware, OS build, thermal state, and background load; compare recorded
distributions instead.

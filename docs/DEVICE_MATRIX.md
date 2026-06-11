# Device Matrix

## Primary Devices

### MacBook Pro M5

- OS 26 on-device baseline.
- OS 27 on-device comparison.
- OS 27 PCC service comparison.

### iPhone 16 Pro Max

- OS 26 on-device baseline.
- OS 27 on-device comparison.
- OS 27 PCC service comparison.

Capture OS 26 results before upgrading. Apple may stop signing an older OS, making a
downgrade unavailable.

## Result Naming

Use:

```text
Results/<device>-<os-build>-<model>-<suite>-<timestamp>.json
Results/<device>-<os-build>-<model>-<suite>-<timestamp>.md
```

Examples:

```text
Results/macbook-pro-m5-26A5353q-on-device-quick-2026-06-12.json
Results/iphone-16-pro-max-ios26-on-device-full-2026-06-12.json
```

## Minimum Published Run

- One warmup.
- Five measured repetitions.
- Nominal or fair thermal state.
- Low Power Mode recorded.
- No omitted failures.
- AppBench commit SHA recorded alongside the result.

## Comparability Labels

- **OS comparison:** same device, different OS build.
- **Device comparison:** same model class and OS generation, different hardware.
- **Execution comparison:** same fixture, on-device versus PCC.
- **Longitudinal PCC comparison:** same client setup, different date.

These labels prevent PCC network latency from being mistaken for device inference
performance and prevent hardware changes from being attributed only to the OS.

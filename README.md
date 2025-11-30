# Foundation Models Framework Benchmark (WORK IN PROGRESS)

This repo measures Foundation Models performance across macOS, iOS, iPadOS, and visionOS using the Foundation Models framework.

## Requirements

- Xcode 26.0 or newer (SDKs for macOS 26, iOS 26, iPadOS 26, visionOS 26).
- Apple Intelligence enabled on the test device.

## Running the Benchmark

Open the project in Xcode and select the appropriate destination in the run destination picker.

Launch `FoundationStudio.app`, and ensure Apple Intelligence is available. Then tap **Run Benchmark**. Once complete, use the export buttons to save or share the report.

## macOS

| Device | CPU | GPU | RAM | OS | Input Tokens | Output Tokens | Total Tokens | Duration | Tokens/sec |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MacBook Pro 14" (2025) | Apple M5 10‑core | Apple M5 10‑core | 32 GB | macOS 26.0 | 125 | 1,069 | 1,194 | 14.41s | **82.86** |
| MacBook Pro 14" (2024) | Apple M4 10‑core | Apple M4 10‑core | 16 GB | macOS 26.1 | 125 | 1,069 | 1,194 | 15.64s | **76.33** |
| MacBook Air 15" (2025) | Apple M4 10‑core | Apple M4 10‑core | 24 GB | macOS 26.1 | 144 | 887 | 1,031 | 15.23s | **58.24** |
| MacBook Air 13" (2025) | Apple M4 10‑core | Apple M4 10‑core | 32 GB | macOS 26.1 | 228 | 3,040 | 3,268 | 41.04s | **79.63** |
| Mac Mini (2024) | Apple M4 10‑core | Apple M4 10‑core | 16 GB | macOS 26.1 | 228 | 3,040 | 3,268 | 40.95s | **79.80** |

## iOS

| Device | CPU | GPU | RAM | OS | Input Tokens | Output Tokens | Total Tokens | Duration | Tokens/sec |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| iPhone 17 Pro Max | Apple A19 Pro 6‑core | Apple A19 Pro 6‑core | 12 GB | iOS 26.1 | 228 | 3,040 | 3,268 | 31.88s | **102.50** |
| iPhone 17 Pro | Apple A19 Pro 6‑core | Apple A19 Pro 6‑core | 12 GB | iOS 26.1 | 125 | 1,069 | 1,194 | 11.93s | **100.08** |
| iPhone 16 Pro Max | Apple A18 Pro 6‑core | Apple A18 Pro 6‑core | 8 GB | iOS 26.2 | 125 | 1,069 | 1,194 | 17.53s | **68.13** |

## iPadOS

| Device | CPU | GPU | RAM | OS | Input Tokens | Output Tokens | Total Tokens | Duration | Tokens/sec |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| iPad Pro 13" (M4) | Apple M4 10‑core | Apple M4 10‑core | 16 GB | iPadOS 18.1 | TBD | TBD | TBD | TBD | TBD |
| iPad Pro 13" (M4, 8 GB) | Apple M4 10‑core | Apple M4 10‑core | 8 GB | iPadOS 26.1 | 228 | 3,040 | 3,268 | 39.45s | **82.84** |

## visionOS

| Device | CPU | GPU | RAM | OS | Input Tokens | Output Tokens | Total Tokens | Duration | Tokens/sec |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Apple Vision Pro (M2) | Apple M2 8‑core (4P + 4E) | Apple M2 10‑core | 16 GB | visionOS 26.1 | 228 | 2,641 | 2,869 | 69.88s | **41.05** |
| Apple Vision Pro (M5) | Apple M5 10‑core (4P + 6E) | Apple M5 10‑core | 16 GB | visionOS 26.0 | TBD | TBD | TBD | TBD | TBD |

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Contributions welcome!

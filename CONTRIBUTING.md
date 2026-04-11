# Contributing

Thanks for your interest in improving `afm`.

## Scope

This repository is the standalone home for the `afm` command-line tool and its shared runtime pieces. The goal is to build a fast, powerful, and well-documented CLI for Foundation Models on Apple platforms.

## Development Setup

Requirements:

- Xcode 26 or newer
- Swift 6.2 or newer
- macOS 26 or newer

Clone the repository and build locally:

```bash
git clone https://github.com/rudrankriyam/Foundation-Models-Framework-CLI.git
cd Foundation-Models-Framework-CLI
swift build
swift run afm
```

## Contribution Guidelines

- Keep changes focused and reviewable.
- Prefer small pull requests over broad refactors.
- Update documentation when behavior or public APIs change.
- Add or update tests for behavioral changes.
- Keep command names, help text, and output formats intentional and stable.

## Pull Requests

Before opening a pull request:

```bash
swift build
swift test
```

If your change affects command UX, include:

- the command(s) you ran
- expected output examples
- any behavior changes or migration notes

## Design Direction

`afm` should feel like a first-class product, not a sidecar demo. Contributions that improve runtime quality, command ergonomics, structured generation, streaming, transcripts, tooling, and future extensibility are especially welcome.

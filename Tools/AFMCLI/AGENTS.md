# AGENTS.md

This file provides guidance to coding agents working in this repository.

## Project Overview

`afm` is a standalone Swift command-line interface for Foundation Models on Apple platforms.

The repository is meant to be product-oriented rather than demo-oriented:

- the `afm` command should feel stable, powerful, and scriptable
- runtime logic should be reusable across future package targets
- command UX should be intentional and well-documented

## Current Direction

The long-term architecture should separate:

- `AFMCLI` for command parsing and output formatting
- shared runtime modules for sessions, streaming, transcripts, schemas, and tools
- Apple-specific adapters for Foundation Models APIs

Avoid coupling new CLI features to sample-app concepts or demo-specific naming.

## Commands

Build locally:

```bash
swift build
```

Run the CLI:

```bash
swift run afm
```

Run tests:

```bash
swift test
```

## Coding Guidelines

- Prefer modern Swift and Swift concurrency.
- Keep command layers thin; push reusable logic into shared modules as the package grows.
- Favor additive, reviewable changes over broad rewrites.
- Update `README.md` and help text when public behavior changes.
- Do not introduce fake placeholder subcommands that imply finished behavior.

## Repo Hygiene

When adding significant new package features:

- document the new command or module in `README.md`
- add tests where behavior is stable enough to verify
- keep names product-oriented rather than example-oriented
- preserve `afm` as the public command name

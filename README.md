# Foundation Models Framework CLI

`afm` is a powerful command-line interface for Foundation Models on Apple platforms.

This repository is the standalone home for the `afm` command. It is designed to move beyond demo-oriented workflows and grow into a first-class CLI for sessions, streaming, structured generation, transcripts, feedback export, batch runs, and future Foundation Models capabilities.

## Status

V1 runtime migration is in place. The CLI now ships a single executable target with workflow-first commands for model inspection, session flows, schema generation, transcript export, and feedback export.

## Command

```bash
afm
```

## Commands

```bash
afm model status
afm model languages

afm session respond --prompt "Summarize Foundation Models briefly."
afm session stream --prompt "Write a short poem about rain."
afm session chat --message "Hello" --message "Now answer in French."

afm schema list
afm schema run typed-person --input "Jane is a designer in Berlin."
afm schema run basic-object --preset product
afm schema run array-schema --preset todo
afm schema run enum-schema --preset sentiment

afm transcript export --message "Hello" --message "Summarize our conversation." --file transcript.json
afm feedback export --prompt "What is the capital of France?" --sentiment positive --file feedback.json
```

## UX

- Explicit long-form flags in docs and examples
- TTY-aware defaults: text for terminals, JSON for pipes/CI
- `--output text|json` for explicit control
- `--pretty` only with JSON output
- Validation errors before runtime work starts
- Unknown-command suggestions for root and grouped subcommands

## Local Development

```bash
swift build
swift test
swift run afm --help
```

# Foundation Models Framework CLI

`afm` is a workflow-first command-line interface for Foundation Models.

This repository is the standalone home for the `afm` command. The goal is simple: make Foundation Models fast to script, pleasant to explore, and reliable to automate. `afm` is built as a single executable target with a runtime-first architecture so it can grow into a serious tool for sessions, streaming, structured generation, transcripts, feedback export, evals, and future Foundation Models capabilities.

## Why `afm`

- Natural command groups for real workflows: `model`, `session`, `schema`, `tool`, `transcript`, and `feedback`
- TTY-aware output defaults: readable text in terminals, JSON for pipes and CI
- Agent-friendly JSON streaming for live session output
- File-backed schemas and tools that can be resolved from `.afm/` directories
- `@file`, `--stdin`, and directory-based artifact loading for fast iteration
- Strong upfront validation before model work starts
- One standalone CLI instead of a demo companion bolted onto an example app

## Install From Source

```bash
git clone https://github.com/rudrankriyam/Foundation-Models-Framework-CLI.git
cd Foundation-Models-Framework-CLI
swift build -c release
.build/release/afm --help
```

Start with a readiness check:

```bash
afm model status
```

## Command Surface

```bash
afm model status
afm model languages

afm session respond --prompt "Summarize Foundation Models in one paragraph."
afm session respond --prompt @prompt.txt
afm session stream --prompt "Write a short poem about rain."
afm session chat --message "Hello" --message "Now answer in French."

afm schema list
afm schema run custom --schema person-card --schema-dir .afm/schemas --input @person.txt
afm schema run typed-person --input "Alex Rivera is a designer in Berlin."
afm schema run basic-object --preset product
afm schema run array-schema --preset todo
afm schema run enum-schema --preset sentiment

afm tool inspect --tool echo-json --tool-dir .afm/tools
afm tool validate --tool echo-json --tool-dir .afm/tools
afm tool call --tool echo-json --tool-dir .afm/tools --args @args.json

afm transcript export --message "Hello" --message "Summarize our conversation." --file transcript.json
afm feedback export --prompt "What is the capital of France?" --sentiment positive --file feedback.json
```

## Output Modes

`afm` defaults to text in an interactive terminal and JSON when piped or used in automation. You can always override that explicitly:

```bash
afm model status --output text
afm model status --output json --pretty
```

Streaming JSON output is emitted as newline-delimited event objects so agents and scripts can react incrementally instead of waiting for one final blob:

```bash
afm session stream --output json --prompt "Reply with three short lines."
afm session chat --stream --output json --message "Hello" --message "Keep going."
```

## Input And Artifact Ergonomics

`afm` is designed to be easy to drive from files, pipes, and agent workflows:

```bash
afm session respond --prompt @prompt.md
cat prompt.md | afm session respond --output json
afm schema run custom --schema person-card --schema-dir .afm/schemas --input @person.txt
afm tool call --tool echo-json --tool-dir .afm/tools --args @args.json
```

Bare schema and tool identifiers are resolved through `--schema-dir` and `--tool-dir`, which default to `.afm/schemas` and `.afm/tools`.

## Quick Examples

One-shot response:

```bash
afm session respond --prompt "Explain structured generation in simple terms."
```

Typed schema generation:

```bash
afm schema run typed-person --input "Alex Rivera is a designer in Berlin."
```

Dynamic schema generation:

```bash
afm schema run basic-object --preset product --input "A lightweight notebook with a 14-inch display and 18-hour battery life."
```

Custom schema generation from a file-backed artifact:

```bash
afm schema run custom \
  --schema person-card \
  --schema-dir .afm/schemas \
  --input @person.txt
```

Tool validation and direct execution:

```bash
afm tool validate --tool echo-json --tool-dir .afm/tools
afm tool call --tool echo-json --tool-dir .afm/tools --args @args.json
```

Transcript export:

```bash
afm transcript export \
  --message "Hello" \
  --message "Summarize this conversation in one sentence." \
  --file transcript.json
```

Feedback attachment export:

```bash
afm feedback export \
  --prompt "What is the capital of France?" \
  --desired-output "Paris" \
  --sentiment positive \
  --file feedback.json
```

## UX Principles

- Explicit long-form flags in docs, tests, and examples
- `--output text|json` for predictable integrations
- `--pretty` only when JSON output is selected
- `@file`, `--stdin`, and directory-backed artifact resolution for prompts, schemas, tools, and inputs
- Unknown-command suggestions for root and grouped subcommands
- Export commands that work cleanly with nested output paths

## Local Development

```bash
swift build
swift test
swift run afm --help
```

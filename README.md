# Foundation Models Framework CLI

`afm` is a native command-line interface for Foundation Models on Apple platforms.

This repository is the standalone home for the `afm` command. The goal is simple: make Foundation Models fast to script, pleasant to explore, and reliable to automate. `afm` is built as a single Swift executable with a runtime-first architecture so it can grow into a serious tool for sessions, streaming, structured generation, transcripts, feedback export, evals, and future Foundation Models capabilities.

## Why `afm`

- A real CLI product instead of a demo companion
- Natural workflows for model inspection, prompting, tagging, schemas, tools, transcripts, and feedback
- TTY-aware output defaults: readable text in terminals, JSON for pipes and CI
- Agent-friendly JSON streaming for live session output
- File-backed schemas and tools that can be resolved from `.afm/` directories
- `@file`, `--stdin`, and directory-based artifact loading for fast iteration
- Strong upfront validation before model work starts
- First-class Foundation Models controls for use cases, guardrails, schema prompting, and feedback issues

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

## First Commands

```bash
afm model status
afm tag run --prompt "A joyful dog playing in a sunny park."
afm session respond --prompt "Summarize Foundation Models in one paragraph."
afm schema run typed-person --input "Alex Rivera is a designer in Berlin."
afm session stream --prompt "Write a short poem about rain."
afm schema run custom --schema person-card --schema-dir .afm/schemas --input @person.txt
```

## Sample Workflows

### Model inspection

Use `afm model` to inspect runtime readiness and Foundation Models capabilities.

```bash
afm model status
afm model status --use-case content-tagging
afm model languages
afm model use-cases
afm model guardrails
```

### Prompting and chat

Use `afm session` for one-shot prompts, streaming responses, and multi-turn conversations.

```bash
afm session respond --prompt "Summarize Foundation Models in one paragraph."
afm session respond --prompt @prompt.txt
afm session respond --use-case content-tagging --prompt "Organize this photo library item."
afm session stream --prompt "Write a short poem about rain."
afm session chat --message "Hello" --message "Now answer in French."
```

### Content tagging

Use `afm tag` when you want to try the content-tagging system model directly.

```bash
afm tag run --prompt "A joyful dog playing in a sunny park."
```

### Structured generation

Use `afm schema` for typed generation and runtime-defined schemas.

```bash
afm schema list
afm schema run typed-person --input "Alex Rivera is a designer in Berlin."
afm schema run basic-object --preset product
afm schema run array-schema --preset todo
afm schema run enum-schema --preset sentiment
afm schema run custom --schema person-card --schema-dir .afm/schemas --input @person.txt
afm schema run custom --schema person-card --input @person.txt --no-include-schema-in-prompt
```

### Tool artifacts

Use `afm tool` to inspect, validate, and execute file-backed tool manifests.

```bash
afm tool inspect --tool echo-json --tool-dir .afm/tools
afm tool validate --tool echo-json --tool-dir .afm/tools
afm tool call --tool echo-json --tool-dir .afm/tools --args @args.json
```

### Transcript and feedback exports

Use export commands to persist transcripts and Feedback Assistant attachments.

```bash
afm transcript export --message "Hello" --message "Summarize our conversation." --file transcript.json
afm feedback export --prompt "What is the capital of France?" --sentiment positive --issue incorrect --file feedback.json
```

## Output And Streaming

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

## Files, Pipes, And Automation

`afm` is designed to be easy to drive from files, pipes, and agent workflows:

```bash
afm session respond --prompt @prompt.md
cat prompt.md | afm session respond --output json
afm schema run custom --schema person-card --schema-dir .afm/schemas --input @person.txt
afm tool call --tool echo-json --tool-dir .afm/tools --args @args.json
```

Bare schema and tool identifiers are resolved through `--schema-dir` and `--tool-dir`, which default to `.afm/schemas` and `.afm/tools`.

## Foundation Models Controls

`afm` exposes the main Foundation Models controls directly instead of hiding them inside demo presets:

```bash
afm model use-cases
afm model guardrails

afm session respond --use-case general --guardrails default --prompt "Summarize this."
afm tag run --guardrails permissive-content-transformations --prompt "A stormy beach at sunset."

afm schema run custom \
  --schema person-card \
  --input @person.txt \
  --no-include-schema-in-prompt

afm feedback export \
  --prompt "What is the capital of France?" \
  --issue incorrect \
  --issue-explanation "The answer should be Paris." \
  --file feedback.json
```

Supported Foundation Models use cases:

- `general`
- `content-tagging`

Supported guardrails:

- `default`
- `permissive-content-transformations`

## UX Principles

- Explicit long-form flags in docs, tests, and examples
- `--output text|json` for predictable integrations
- `--pretty` only when JSON output is selected
- `@file`, `--stdin`, and directory-backed artifact resolution for prompts, schemas, tools, and inputs
- `--use-case`, `--guardrails`, `--include-schema-in-prompt`, and feedback `--issue` flags map cleanly to Foundation Models APIs
- Unknown-command suggestions for root and grouped subcommands
- Export commands that work cleanly with nested output paths

## Local Development

```bash
swift build
swift test
swift run afm --help
```

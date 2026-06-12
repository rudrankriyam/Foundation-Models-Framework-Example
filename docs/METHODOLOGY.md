# AppBench Methodology

## Design Principles

AppBench follows five rules:

1. Evaluate deployment-shaped scenarios rather than a single generic prompt.
2. Keep quality, latency, and resource context as separate measurements.
3. Prefer deterministic, inspectable graders whenever an answer can be verified.
4. Report distributions and failures, not only successful averages.
5. Preserve the complete fixture, response, environment, OS build, and timestamp.

These rules draw from:

- [HELM](https://arxiv.org/abs/2211.09110): scenario and metric coverage, standardized conditions, and explicit incompleteness.
- [IFEval](https://arxiv.org/abs/2311.07911): interpretable verifiable instructions plus prompt-level and instruction-level accuracy.
- [BFCL](https://proceedings.mlr.press/v267/patil25a.html): structural evaluation for tool and function calls.
- [RULER](https://arxiv.org/abs/2404.06654): configurable task complexity and context length beyond simple retrieval.
- [G-Eval](https://arxiv.org/abs/2303.16634): rubric-based subjective evaluation and documented evaluator bias.
- [MT-Bench and Chatbot Arena](https://arxiv.org/abs/2306.05685): human preference, judge agreement, and position/verbosity/self-enhancement biases.
- [Mobile LLM inference benchmarking](https://arxiv.org/abs/2410.03613): user-facing latency, energy, and system-state concerns on mobile hardware.
- [Metron](https://arxiv.org/abs/2407.07000): token delivery stalls can be hidden by aggregate throughput.
- [MLPerf Client](https://mlcommons.org/benchmarks/client/): TTFT and post-first-token generation rate as separate client metrics.
- Apple’s [2024 AFM report](https://arxiv.org/abs/2407.21075) and
  [2025 AFM report](https://arxiv.org/abs/2507.13575): public benchmarks,
  human evaluation, feature-specific evaluation, and quality regression checks after optimization.

## Quality Scoring

Each fixture has deterministic checks such as:

- Exact generated fields.
- Required and forbidden text.
- Semantically required array members.
- Maximum or minimum word count.
- Exact source citations.

Guided generation schema conformance is not scored as quality. The framework enforces
the JSON shape, property types, enum choices, and schema-level array bounds during
decoding. AppBench records guided generation as the execution mode, then grades only
whether the generated values solve the task. For example, an allowed category can
still be the wrong category, and a well-formed citation array can cite the wrong note.

AppBench reports two quality values:

- **Constraint score:** checks passed divided by total checks.
- **Prompt pass:** true only when every check passes.

This mirrors IFEval’s distinction between instruction-level and prompt-level accuracy.
The prompt pass rate is intentionally strict because a production action can fail when
only one required field is wrong.

Subjective model judging is intentionally absent from the starter suite. Future rubrics
for tone, fluency, or usefulness should:

- Use a frozen judge and rubric version.
- Grade responses independently before pairwise comparison.
- Swap pairwise response order.
- Retain judge explanations and raw outputs.
- Be calibrated periodically against human ratings.

## Performance Scoring

For each request:

- `TTFT = first stream update - request start`
- `decode duration = final update - first stream update`
- `output tokens/sec = (final output tokens - first snapshot tokens) / decode duration`
- `end-to-end duration = final update - request start`

Prompt tokens are never included in output throughput.

On OS 26.4 and later, on-device runs use
`SystemLanguageModel.tokenCount(for:)` for instructions, prompts, schemas, and
responses. Each trial records `tokenCountSource: systemTokenizer`.

Earlier on-device systems and PCC runs use estimates calibrated from prior
Foundation Models Instruments traces because the public tokenizer API belongs to
`SystemLanguageModel`. Those trials record
`tokenCountSource: characterEstimate`. Characters per second remains a
tokenizer-independent secondary measurement.

Stream snapshots are not guaranteed to map one-to-one to tokens. Consequently,
AppBench calls their timing **stream update gaps**, not inter-token latency.
The first snapshot can contain multiple tokens, so AppBench excludes every token
already present in that snapshot rather than assuming it contains one token.

## Experiment Protocol

For publishable comparisons:

1. Reboot or otherwise establish the same starting state.
2. Disconnect external displays and power-hungry peripherals when possible.
3. Record charging state, Low Power Mode, thermal state, and network.
4. Run at least one warmup.
5. Run at least five measured repetitions per scenario.
6. Randomize scenario order between larger experimental rounds.
7. Stop and cool the device if the thermal state reaches serious or critical.
8. Keep input fixtures, generation options, and AppBench commit identical.
9. Report all execution failures.
10. Compare median and p90, not the single fastest run.

For public reports, set `APPBENCH_DEVICE_NAME` to a generic label such as
`MacBook Pro M5`. AppBench never needs the machine hostname.

For exploratory development, one repetition is acceptable but must not be presented as
a stable device ranking.

## OS Comparisons

An OS comparison requires the same hardware. A Mac-versus-iPhone comparison is a
device comparison even when both run the same OS generation.

OS 26 and OS 27 results can differ because of:

- Foundation model weights.
- Framework behavior.
- Compiler and SDK behavior.
- Runtime scheduling and memory management.
- Guided-generation implementation.
- Tool-calling behavior.
- Thermal and power policies.

The report therefore records the OS build, not only the major version.

## PCC Comparisons

PCC is a service benchmark:

- Record connection type and approximate location separately.
- Run enough repetitions to expose network variance.
- Keep PCC reasoning configuration fixed.
- Timestamp results because the server model can change independently.
- Never combine PCC throughput with on-device throughput in a single device ranking.
- Record quota and availability failures instead of dropping them.

PCC requires OS 27, an Apple Intelligence-capable device with Apple Intelligence
enabled, service availability, and Apple’s managed entitlement.

## Known Limitations

- The starter corpus is deliberately small and is not statistically representative of every app.
- PCC and pre-26.4 token counts are estimated without Instruments.
- Energy use is not yet sampled directly.
- Snapshot timing cannot provide true token-level jitter.
- The practical scenarios are English-only.
- Deterministic checks measure specified requirements, not every aspect of usefulness.
- PCC cannot be reproduced without entitlement and stable network conditions.

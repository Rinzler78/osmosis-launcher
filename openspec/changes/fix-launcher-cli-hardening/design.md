## Context

The launcher project combines shell orchestration, Git operations, dynamic code patching, and a small Go runtime shim. The current implementation favors convenience and incremental compatibility, but several parts rely on optimistic assumptions: text replacement against upstream source layout, shell argument defaults inferred too broadly, and stdin parsing that treats commands as whitespace-separated tokens instead of preserving shell-like grouping.

## Goals / Non-Goals

- Goals:
  - Make the public CLI contract internally consistent and externally trustworthy.
  - Convert silent failure modes into explicit, actionable errors.
  - Reduce shell fragility around quoting, unknown options, and destructive operations.
  - Add regression coverage for the exact edge cases that are currently under-specified.
- Non-Goals:
  - Re-architect the entire build chain away from Bash.
  - Add broad new product capabilities unrelated to launcher/build correctness.
  - Remove all positional compatibility unless it directly conflicts with safety or clarity.

## Decisions

- Decision: Treat the README and root CLI as a single contract surface.
  - Rationale: The current mismatch is a direct user-facing defect; the code and documentation must converge.
  - Alternatives considered: Keep the code unchanged and narrow the docs. This is acceptable only if the project intentionally rejects named arguments at the root; otherwise it preserves unnecessary confusion.

- Decision: Make patching explicitly verifiable.
  - Rationale: A patching step that can succeed without changing the target source is too risky when upstream Osmosis changes shape.
  - Alternatives considered: Keep simple string replacement and rely on downstream build/test failures. This delays feedback and allows partial false-positive success.

- Decision: Define launcher stdin semantics before changing implementation.
  - Rationale: Preserving quotes is a behavior decision, not just an implementation detail.
  - Alternatives considered: Keep `strings.Fields` and document the limitation. This would weaken the launcher value proposition for automation use cases.

- Decision: Prioritize shell hardening in critical paths instead of bulk style cleanup.
  - Rationale: Not every shell warning is equally valuable; the first pass should focus on path safety, option validation, and deterministic failures.
  - Alternatives considered: Large-scale script rewrite. This raises risk without proportionate benefit for the current issue set.

## Risks / Trade-offs

- Tightening unknown-option handling may break undocumented usage patterns.
  - Mitigation: Add clear compatibility notes and targeted tests for supported positional forms.

- Changing launcher stdin parsing may alter edge-case behavior for existing automation.
  - Mitigation: Document the exact parsing contract and keep simple whitespace-only commands working unchanged.

- Guarding destructive resets may slightly reduce convenience in local rebuild loops.
  - Mitigation: Allow explicit force behavior while making the default safer.

## Migration Plan

1. Define the canonical CLI contract and validation scenarios.
2. Refactor root CLI and shared argument parsing with compatibility tests.
3. Harden patching and launcher parsing with dedicated regression coverage.
4. Update README and CI to reflect and enforce the new contract.
5. Run targeted tests, shellcheck, and OpenSpec validation before implementation approval.

## Open Questions

- Should the root `make.sh` continue to support positional arguments once named arguments are fully implemented?
- Should launcher stdin parsing follow shell quoting strictly, or should it switch to an explicit structured format in a later change?
- Should `clone.sh` destructive reset behavior require an explicit `--force`, or is a loud warning sufficient for now?


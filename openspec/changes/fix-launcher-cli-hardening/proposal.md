## Why

The project currently works on its main happy path, but several user-facing and maintenance-critical areas are inconsistent or fragile: the documented root CLI does not match the implemented interface, the patching flow can succeed without proving the launcher injection was applied, stdin command parsing in launcher mode does not preserve quoted arguments, and the shell layer tolerates ambiguous input and unsafe path handling.

These issues do not necessarily break the current test suite, but they increase the risk of user confusion, silent regressions against upstream Osmosis changes, and avoidable failures in automation environments.

## What Changes

- Align the root `make.sh` contract with the documented named-argument interface, while preserving clearly defined backward compatibility rules for positional usage where still needed.
- Harden `src/patch.sh` so it becomes idempotent, path-safe, and explicitly fails when the launcher injection point is missing or unchanged.
- Improve launcher stdin argument handling so quoted values and escaped spaces are preserved according to a documented input contract.
- Tighten the shared shell layer by rejecting unknown options, improving quoting and strict-mode usage, and reducing silent fallbacks.
- Clarify and constrain destructive clone/update behavior so repository resets are explicit and predictable.
- Expand test coverage and CI validation to cover the newly hardened behaviors and prevent regressions.
- Update documentation to reflect the real supported workflows and validation expectations.

## Impact

- Affected specs: `launcher-build-workflow`
- Affected code: [make.sh](/Users/bleclereperso/Projects/osmosis-launcher/.claude/worktrees/fix-launcher-hardening-plan/make.sh), [src/parse_args.sh](/Users/bleclereperso/Projects/osmosis-launcher/.claude/worktrees/fix-launcher-hardening-plan/src/parse_args.sh), [src/patch.sh](/Users/bleclereperso/Projects/osmosis-launcher/.claude/worktrees/fix-launcher-hardening-plan/src/patch.sh), [src/launcher.go](/Users/bleclereperso/Projects/osmosis-launcher/.claude/worktrees/fix-launcher-hardening-plan/src/launcher.go), [src/clone.sh](/Users/bleclereperso/Projects/osmosis-launcher/.claude/worktrees/fix-launcher-hardening-plan/src/clone.sh), [tests/test_all.sh](/Users/bleclereperso/Projects/osmosis-launcher/.claude/worktrees/fix-launcher-hardening-plan/tests/test_all.sh), [README.md](/Users/bleclereperso/Projects/osmosis-launcher/.claude/worktrees/fix-launcher-hardening-plan/README.md), [.github/workflows/release.yml](/Users/bleclereperso/Projects/osmosis-launcher/.claude/worktrees/fix-launcher-hardening-plan/.github/workflows/release.yml)

## Validation Criteria

- `./make.sh --tag <tag> --os <os> --arch <arch> --target-dir <dir>` MUST execute according to the documented contract, or the README/examples MUST be updated so no unsupported syntax remains.
- `src/patch.sh` MUST fail with a clear error if the injection point cannot be found, and MUST succeed idempotently when the launcher has already been applied.
- Launcher mode MUST preserve quoted stdin arguments in at least the following forms: plain spaces, quoted memo text, and escaped whitespace.
- Unknown command-line options passed to user-facing scripts MUST fail fast with a non-zero exit code and actionable error output.
- Path handling MUST support target directories containing spaces for patch and build-related flows that advertise arbitrary target directories.
- The test suite MUST include explicit coverage for the hardened cases above.
- CI MUST include at least one fast shell validation step before heavier network/build steps.


## 1. CLI Contract Alignment

- [x] 1.1 Decide and document the canonical root `make.sh` interface, including named arguments and any retained positional compatibility.
- [x] 1.2 Update the root `make.sh` implementation to match the canonical interface.
- [x] 1.3 Add regression tests that exercise the documented root CLI examples.

## 2. Patch Flow Hardening

- [x] 2.1 Refactor `src/patch.sh` to quote all paths and writes safely.
- [x] 2.2 Make patch application idempotent and fail when the expected injection point is missing.
- [x] 2.3 Add tests for patch success, already-patched success, missing injection-point failure, and target directories containing spaces.

## 3. Launcher Argument Semantics

- [x] 3.1 Define the stdin command parsing contract for launcher mode.
- [x] 3.2 Update `src/launcher.go` to preserve quoted arguments according to the contract.
- [x] 3.3 Add tests for quoted values, escaped whitespace, and compatibility with existing simple commands.

## 4. Shell Layer Cleanup

- [x] 4.1 Update `src/parse_args.sh` and related scripts to fail on unknown options.
- [x] 4.2 Standardize strict shell behavior and fix high-value quoting and path-safety issues in critical scripts.
- [x] 4.3 Review clone/update behavior and introduce explicit guardrails for destructive resets if needed.
- [x] 4.4 Run `shellcheck` on the primary shell scripts and reduce warnings to an agreed baseline.

## 5. Documentation and CI

- [x] 5.1 Update README usage examples and script descriptions to match implemented behavior.
- [x] 5.2 Add or adjust CI steps so fast shell validation runs before heavy integration/build jobs.
- [x] 5.3 Ensure the full validation checklist below is executable and documented.

## 6. Validation Checklist

- [x] 6.1 `tests/test_01_parse_args.sh` passes with unknown-option failure coverage added.
- [x] 6.2 `tests/test_07_patch.sh` passes with idempotence and path-with-spaces coverage added.
- [x] 6.3 A launcher-focused regression test passes for quoted stdin arguments.
- [x] 6.4 A root `make.sh` regression test passes for the documented named-argument interface.
- [x] 6.5 `tests/test_11_platform_tools.sh` passes unchanged or with only intentional expectation updates.
- [x] 6.6 `shellcheck make.sh src/*.sh tests/*.sh` passes or remaining exclusions are explicitly justified.
- [x] 6.7 `openspec validate fix-launcher-cli-hardening --strict` passes.

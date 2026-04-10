## Context

The root repository currently exposes a single tag-triggered GitHub Actions workflow that combines validation and release creation. That workflow validates shell scripts and test orchestration, but it runs too late in the lifecycle and does not publish usable binaries or checksums.

The repository already contains embedded upstream Osmosis workflows under `osmosis/.github/workflows/`, but those workflows are part of the vendored upstream codebase and do not define the authoritative CI/CD behavior of the launcher repository itself.

## Goals / Non-Goals

- Goals:
- Provide earlier feedback on pull requests and protected branch pushes
- Publish usable root-repository release artifacts on version tags
- Preserve the Bash-centric validation strategy already used by the project
- Make the workflow boundary between the launcher repository and embedded upstream Osmosis explicit

- Non-Goals:
- Replicate the full upstream Osmosis CI/CD stack in the launcher repository
- Introduce heavy infrastructure beyond what is needed to validate the launcher scripts and release flow
- Redesign the existing build scripts as part of this proposal

## Decisions

- Decision: split root automation into dedicated `ci`, `build`, and `release` workflows
- Why: separating fast validation from artifact production and publication reduces release-time risk and keeps responsibilities clear

- Decision: keep shell linting and `tests/test_all.sh` as the primary validation baseline
- Why: the root repository's core behavior is implemented and tested through Bash scripts, so these checks are the most representative quality gate

- Decision: publish binaries and checksums as GitHub release assets
- Why: a release without attached deliverables is not sufficient for downstream consumers or for traceable distribution

- Decision: treat embedded upstream workflows as out of scope for root CI/CD compliance
- Why: those workflows belong to the upstream Osmosis codebase and should not be counted as launcher repository automation

## Alternatives Considered

- Keep the current single tag-only workflow
- Rejected because validation remains too late and releases still lack usable artifacts

- Reuse or mirror the upstream Osmosis workflow set
- Rejected because it is significantly heavier than the launcher repository needs and would blur ownership boundaries

## Risks / Trade-offs

- Additional workflows increase maintenance overhead slightly
- Cross-platform release builds may increase runtime and require a clearly defined supported publishing matrix
- Artifact publication may force clearer decisions about which target platforms are officially supported by release policy

## Migration Plan

1. Add a CI workflow for pull requests and protected branch pushes
2. Add a build workflow that produces releasable artifacts
3. Update the tag-based release workflow to attach binaries and checksums
4. Update README documentation and badges to reflect the new workflow structure

## Open Questions

- Which OS and architecture combinations should be published as official release assets?
- Should Docker-based outputs be the canonical release artifacts, or only one implementation path among several supported build modes?

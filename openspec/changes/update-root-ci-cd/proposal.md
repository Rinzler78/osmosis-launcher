## Why

The root repository currently validates changes only on tag push and creates a GitHub release without publishing usable build artifacts. This delays feedback until release time and makes the release process incomplete for downstream users who expect versioned launcher deliverables.

The project relies primarily on Bash orchestration, regression tests, and build delegation logic implemented in the root repository. Its CI/CD should therefore validate those paths earlier and publish the outputs that the release process claims to provide.

## What Changes

- Add a dedicated CI workflow for pull requests and protected branch pushes in the root repository.
- Add a dedicated build workflow that produces versioned release artifacts for the root repository.
- Update the tag-based release workflow to publish binaries and checksums to GitHub Releases.
- Preserve the existing shell-based test suite as the primary validation mechanism.
- Scope the change to root repository automation only, excluding embedded upstream Osmosis workflows under `osmosis/`.

## Impact

- Affected specs: `root-ci-cd`
- Affected code: `.github/workflows/*.yml`, `README.md`
- Affected process: pull request validation, artifact generation, release publishing

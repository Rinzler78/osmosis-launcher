## ADDED Requirements

### Requirement: Pull Request Validation
The system SHALL validate root repository changes on pull requests before release tagging.

#### Scenario: Shell and regression checks run on pull request
- **WHEN** a pull request is opened or updated against the main development branch
- **THEN** the CI workflow runs shell linting and the root test suite
- **AND** the pull request reports pass or fail status before merge

### Requirement: Release Artifact Publishing
The system SHALL publish usable release artifacts for tagged versions of the root repository.

#### Scenario: Tagged release publishes binaries and checksums
- **WHEN** a tag matching the project release pattern is pushed
- **THEN** the release workflow builds the supported release artifacts
- **AND** attaches binaries and checksums to the GitHub release

### Requirement: Root Workflow Scope Isolation
The system SHALL scope root CI/CD automation to the root repository workflows only.

#### Scenario: Embedded upstream workflows are not treated as root CI
- **WHEN** CI/CD behavior is evaluated for the launcher repository
- **THEN** only workflows under the root repository automation scope are considered authoritative
- **AND** embedded upstream Osmosis workflows do not satisfy root repository CI/CD requirements

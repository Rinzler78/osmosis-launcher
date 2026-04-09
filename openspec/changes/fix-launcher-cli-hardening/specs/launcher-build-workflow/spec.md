## ADDED Requirements

### Requirement: Root Build CLI Contract
The system SHALL provide a root build entrypoint whose supported invocation forms are consistent across implementation, tests, and user documentation.

#### Scenario: Documented named arguments are supported
- **WHEN** a user invokes the documented root build command with supported named arguments
- **THEN** the root entrypoint accepts the arguments without falling back to an unrelated positional-usage error
- **AND** it delegates to the correct build workflow using the provided values

#### Scenario: Unsupported options fail fast
- **WHEN** a user passes an unknown option to a user-facing build script
- **THEN** the script exits non-zero
- **AND** it prints an actionable error identifying the unknown option

### Requirement: Verifiable Launcher Patch Application
The system SHALL apply the launcher patch in a way that is path-safe, idempotent, and explicitly verifiable.

#### Scenario: Patch succeeds only when injection is present
- **WHEN** the patch script runs against a compatible Osmosis source tree
- **THEN** it copies the launcher source into the expected destination
- **AND** it injects the launcher call into the target `main.go`
- **AND** it verifies that the target file contains the injected launcher call before reporting success

#### Scenario: Missing injection point is rejected
- **WHEN** the target source layout no longer contains the expected injection point
- **THEN** the patch script exits non-zero
- **AND** it reports that the injection point was not found

#### Scenario: Already patched tree remains valid
- **WHEN** the patch script is run a second time on an already patched tree
- **THEN** it does not duplicate the launcher injection
- **AND** it exits successfully with an idempotent outcome

#### Scenario: Target paths containing spaces are supported
- **WHEN** a user provides a target directory containing spaces
- **THEN** patch-related file reads, writes, and copies operate on the intended path
- **AND** the script does not fail due to shell word splitting

### Requirement: Launcher Stdin Argument Preservation
The system SHALL preserve intended argument boundaries for launcher commands provided on stdin according to the documented input contract.

#### Scenario: Quoted argument with spaces is preserved
- **WHEN** a launcher command includes a quoted argument containing spaces
- **THEN** the launched process receives that value as a single argument

#### Scenario: Escaped whitespace is preserved
- **WHEN** a launcher command includes escaped whitespace in an argument
- **THEN** the launched process receives the intended unescaped single argument value

#### Scenario: Simple whitespace-separated commands remain supported
- **WHEN** a launcher command contains only plain whitespace-separated arguments
- **THEN** the command continues to execute successfully

### Requirement: Validation Gates For Shell Reliability
The system SHALL enforce validation gates that detect shell regressions before expensive release-time builds.

#### Scenario: Fast shell validation runs before heavy jobs
- **WHEN** CI executes for a change affecting launcher/build workflows
- **THEN** it runs at least one fast shell validation step before heavier network or build stages

#### Scenario: Hardened regression cases are covered
- **WHEN** the test suite is executed
- **THEN** it includes explicit regression coverage for unknown options, patch idempotence, patch injection failure, and launcher quoted-argument handling


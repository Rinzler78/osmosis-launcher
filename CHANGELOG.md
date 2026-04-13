# Changelog

All notable changes to this project will be documented in this file.

The format is inspired by Keep a Changelog and the project release tags.

## [v0.0.0.7] - 2026-04-13

### Added
- Imported the BMAD skills bundle used by local assistant workflows.

### Changed
- Hardened the launcher CLI behavior.
- Isolated heavy test workspaces so parallel test runs no longer collide on shared temporary directories or generated binaries.
- Added versioned Git hooks to protect direct work on `develop` and `master`.
- Documented the root worktree location and parallel heavy test isolation.

### Notes
- This release collects all changes merged into `develop` since `v0.0.0.6`.


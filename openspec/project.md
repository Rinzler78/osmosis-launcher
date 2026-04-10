# Project Context

## Purpose
Osmosis Launcher is a wrapper for [osmosis](https://github.com/osmosis-labs/osmosis) that enables running `osmosisd` in "launcher" mode, allowing dynamic command injection via stdin. The project facilitates scripting, automation, and integration of osmosisd into complex workflows.

**Key Goals:**
- Enable programmatic control of osmosisd through stdin
- Provide cross-platform build support with automatic OS/architecture detection
- Simplify Osmosis integration into automation pipelines
- Maintain compatibility with multiple Osmosis versions

## Tech Stack
- **Go**: Core launcher implementation, dynamically injected into osmosisd
- **Bash (>= 4)**: Build automation scripts, testing framework
- **Docker**: Containerized cross-platform builds
- **Git & Git LFS**: Version control and large file handling
- **jq**: JSON processing for platform validation
- **GitHub Actions**: CI/CD with automated testing and releases

## Project Conventions

### Code Style
**Bash Scripts:**
- POSIX-compliant where possible, Bash 4+ features allowed
- Named parameters using `parse_args.sh` for all user-facing scripts
- Error messages and console output in English for international compatibility
- Functions should validate inputs and provide clear error messages
- Use descriptive variable names (e.g., `TARGET_DIR`, `OS`, `ARCH`)

**Go Code:**
- Standard Go formatting (`gofmt`)
- Launcher code injected into osmosisd must be minimal and focused
- Follow Osmosis project conventions where applicable

**Naming Conventions:**
- Scripts: lowercase with underscores (e.g., `parse_args.sh`, `docker_make.sh`)
- Test scripts: numbered prefix pattern `test_NN_description.sh`
- Variables: UPPERCASE for constants/environment, lowercase for local
- Functions: snake_case

### Architecture Patterns
**Modular Script Design:**
- Each script has a single, well-defined responsibility
- Common functionality extracted to shared utilities (`parse_args.sh`, `utils.sh`)
- Platform detection/validation abstracted into dedicated scripts
- Build process supports multiple execution modes (local, Docker, cross-platform)

**Build Orchestration:**
- Main `make.sh` acts as smart orchestrator
- Auto-detects Docker availability and delegates appropriately
- `src/docker_make.sh` for containerized builds
- `src/make.sh` for local Go builds
- `src/build.sh` for advanced cross-compilation scenarios

**Parameter Handling:**
- Centralized argument parsing via `src/parse_args.sh`
- Named parameters with sensible defaults
- Auto-detection for `--tag`, `--os`, `--arch`, `--target-dir`
- Backward compatibility maintained for positional arguments where needed

### Testing Strategy
**Comprehensive Test Suite:**
- Located in `tests/` directory
- Numbered test scripts for sequential execution
- `test_all.sh` runs complete suite
- Each major component has dedicated test coverage:
  - Parameter parsing (`test_01_parse_args.sh`)
  - Tag operations (`test_02_tags.sh`, `test_03_last_tag.sh`)
  - Clone functionality (`test_04_clone.sh`)
  - Build processes (`test_06_build.sh`, `test_08_make.sh`, `test_09_docker_make.sh`)
  - Platform tools (`test_11_platform_tools.sh`)

**Testing Approach:**
- Unit-style tests for individual scripts
- Integration tests for end-to-end build workflows
- CI runs all tests on every tag push
- Tests use shared utilities from `tests/utils.sh`

### Git Workflow
**Branching Strategy:**
- `master`: Main production branch (stable releases)
- `develop`: Development branch for ongoing work
- Feature branches: Created from `develop`, merged back via PR
- Linked worktrees for feature and hotfix work MUST be created under `.worktrees/` at the project root
- `.claude/worktrees/` MUST NOT be used as the project worktree location

**Commit Conventions:**
- Clear, descriptive commit messages in English
- Multi-line commits with detailed context in body
- Reference issues/PRs where applicable

**Release Process:**
- Version tags follow `vX.Y.Z` pattern
- GitHub Actions automatically runs tests on tag push
- Successful tests trigger automated GitHub release creation
- Release workflow defined in `.github/workflows/release.yml`

**Tag Management:**
- `clean_unpushed_tags.sh`: Cleanup utility for local tags

## Domain Context

### Osmosis Integration
- **osmosisd**: The Osmosis blockchain daemon binary
- **Launcher Mode**: Custom patch that makes osmosisd wait for stdin commands
- **Version Compatibility**: Supports multiple Osmosis versions via `--tag` parameter
- **Go Version Requirements**: Automatically detected from Osmosis's `go.mod`

### Build Environments
- **Local Builds**: Require Go installation matching Osmosis requirements
- **Docker Builds**: Self-contained, no local Go needed
- **Cross-Compilation**: Supports extensive platform matrix (see `supported_platforms.json`)

### Platform Support
**Supported OS:**
- Linux (primary target), Darwin (macOS), Windows
- Extended support: FreeBSD, OpenBSD, NetBSD, AIX, Solaris, etc.

**Supported Architectures:**
- amd64, arm64 (primary)
- Extended: 386, arm, ppc64, s390x, riscv64, mips variants, etc.

**Validation:**
- Platform combinations validated against `src/supported_platforms.json`
- Auto-detection uses `src/resolve_os.sh` and `src/resolve_arch.sh`
- Validation via `src/validate_platform.sh`

## Important Constraints

### Technical Constraints
- **Bash Version**: Minimum Bash 4 required for associative arrays and modern features
- **Docker Compatibility**: Optional but recommended for reproducible builds
- **Git LFS**: Required for handling large files in Osmosis repo
- **Memory**: Docker builds check available RAM via `src/get_available_ram_gb.sh`
- **Go Version**: Must match Osmosis requirements (dynamically determined)

### Build Constraints
- Launcher patch must apply cleanly to target Osmosis version
- Cross-platform builds require Docker with BuildKit support
- Local builds require exact Go version matching Osmosis

### Compatibility Constraints
- Must maintain backward compatibility for existing automation scripts
- Named parameters preferred but positional arguments supported where legacy compatibility needed
- Console messages and logs must remain in English

## External Dependencies

### Primary Dependencies
- **Osmosis Repository**: https://github.com/osmosis-labs/osmosis
  - Source code for osmosisd
  - Version controlled via Git tags
  - Requires Git LFS for complete checkout

### Build Tools
- **Go**: Version determined by Osmosis's `go.mod`
- **Docker**: Optional, for containerized builds
- **Git**: Version control operations
- **Git LFS**: Large file support
- **jq**: JSON processing for platform validation
- **Bash**: Shell scripting and automation

### CI/CD
- **GitHub Actions**: Automated testing and releases
- **GitHub Releases API**: Automated release creation via `softprops/action-gh-release@v2`

### Optional Tools
- **Clang**: Alternative build toolchain (VSCode tasks support)
- Platform-specific build tools as needed for cross-compilation

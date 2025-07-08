# Osmosis Launcher

[![Issues](https://img.shields.io/github/issues/Rinzler78/osmosis-launcher)](https://github.com/Rinzler78/osmosis-launcher/issues)
[![Pull Requests](https://img.shields.io/github/issues-pr/Rinzler78/osmosis-launcher)](https://github.com/Rinzler78/osmosis-launcher/pulls)
[![Contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/Rinzler78/osmosis-launcher/issues)
[![Last Commit](https://img.shields.io/github/last-commit/Rinzler78/osmosis-launcher)](https://github.com/Rinzler78/osmosis-launcher/commits/main)
[![Forks](https://img.shields.io/github/forks/Rinzler78/osmosis-launcher?style=social)](https://github.com/Rinzler78/osmosis-launcher/fork)
[![Stars](https://img.shields.io/github/stars/Rinzler78/osmosis-launcher?style=social)](https://github.com/Rinzler78/osmosis-launcher/stargazers)
[![CI](https://github.com/Rinzler78/osmosis-launcher/actions/workflows/release.yml/badge.svg)](https://github.com/Rinzler78/osmosis-launcher/actions)
[![GitHub All Releases](https://img.shields.io/github/downloads/Rinzler78/osmosis-launcher/total.svg)](https://github.com/Rinzler78/osmosis-launcher/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![made-with-bash](https://img.shields.io/badge/-Made%20with%20Bash-1f425f.svg?logo=gnu-bash)](https://www.gnu.org/software/bash/)
[![Latest Release](https://img.shields.io/github/v/tag/Rinzler78/osmosis-launcher)](https://github.com/Rinzler78/osmosis-launcher/releases)

---

Osmosis Launcher is a wrapper for [osmosis](https://github.com/osmosis-labs/osmosis) that allows you to run `osmosisd` in "launcher" mode and send commands dynamically via stdin. This project makes scripting, automation, and integration of osmosisd into complex workflows much easier.

## Table of Contents
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Parameter Handling](#parameter-handling)
- [Quick Start](#quick-start)
- [Build Process](#build-process)
- [Scripts Details](#scripts-details)
- [Contributing](#contributing)
- [License](#license)

## Features
- Launch `osmosisd` in "launcher" mode (waits for commands on stdin)
- Dynamically inject commands after startup
- Automation scripts to clone, patch, and build Osmosis
- Automated tests for each key step
- Unified and modern parameter handling across all scripts

## Requirements
- [git](https://git-scm.com/)
- [git-lfs](https://git-lfs.github.com/)
- [go](https://go.dev/) (required for local build if Docker is not used)
- bash (>= 4)
- [docker](https://www.docker.com/) (optional, used for building)
- [jq](https://stedolan.github.io/jq/) (for platform validation)

## Installation
1. **Clone the project**
   ```console
git clone https://github.com/Rinzler78/osmosis-launcher.git
cd osmosis-launcher
```

## Parameter Handling
All scripts now use a unified and modern parameter system, handled by `src/parse_args.sh`. This means you can use named options everywhere, and defaults are smartly chosen if you omit them.

**Common parameters:**
- `--tag <tag>`: Osmosis version to use (default: latest tag)
- `--os <os>`: Target OS (default: auto-detected)
- `--arch <arch>`: Target architecture (default: auto-detected)
- `--target-dir <dir>`: Working directory (default: `osmosis`)

**Example usage:**
```console
src/clone.sh --tag v12.3.0 --target-dir myosmo
src/patch.sh --target-dir myosmo
src/build.sh --os linux --arch amd64 --target-dir myosmo
src/docker_make.sh --os linux --arch amd64 --target-dir myosmo
```
If you omit a parameter, the script will choose a sensible default (e.g., latest tag, current platform, etc.).

Some scripts (like `download_go_archive.sh`) still accept positional arguments for backward compatibility, but named options are preferred.

## Quick Start

The fastest way to get started is to use the main `make.sh` script at the root of the project. This script will automatically detect your environment and build everything for you.

### Minimal (no parameters)
```console
./make.sh
```
- Clones the latest Osmosis version
- Applies the launcher patch
- Builds the binary for your current platform (using Docker if available, otherwise locally)
- Produces the `osmosisd` binary in the project root (or in `./buildx-out/build/` for cross-builds)

### Advanced (with parameters)
You can specify the version, platform, and target directory if needed:
```console
./make.sh --tag v12.3.0 --os linux --arch amd64 --target-dir myosmo
```
- `--tag <tag>`: Osmosis version (default: latest)
- `--os <os>`: Target OS (default: auto-detected)
- `--arch <arch>`: Target architecture (default: auto-detected)
- `--target-dir <dir>`: Working directory (default: `osmosis`)

**Example:**
```console
./make.sh --tag v12.3.0 --os linux --arch amd64
```

You can then launch osmosisd in launcher mode:
```console
./osmosisd --launcher
```

For more control or to run steps individually, see the [Parameter Handling](#parameter-handling) and [Scripts Details](#scripts-details) sections.

## Build Process
The main `make.sh` script orchestrates the build. It automatically detects if Docker is available:

- **With Docker:** Uses `src/docker_make.sh` to build in a container for maximum reproducibility and no local Go install required.
- **Without Docker:** Uses `src/make.sh` for a local build (requires Go installed locally).

All scripts accept the same named parameters, and will auto-detect missing values:
- If `--tag` is omitted, the latest tag is used.
- If `--os` or `--arch` are omitted, the current platform is detected.
- If `--target-dir` is omitted, `osmosis` is used.

**To build:**
```console
./make.sh --tag v12.3.0 --os linux --arch amd64 --target-dir osmosis
```

## Scripts Details
- **make.sh**: Main build script. Detects Docker and delegates to the appropriate build method. Accepts all named parameters.
- **src/clone.sh**: Clone the Osmosis repo at a given tag into the target directory. Usage: `src/clone.sh --tag <tag> --target-dir <dir>`
- **src/patch.sh**: Apply the launcher patch to the Osmosis sources. Usage: `src/patch.sh --target-dir <dir>`
- **src/make.sh**: Build the modified Osmosis sources locally (requires Go). Usage: `src/make.sh --os <os> --arch <arch> --target-dir <dir>`
- **src/docker_make.sh**: Build the patched binary using Docker. Usage: `src/docker_make.sh --os <os> --arch <arch> --target-dir <dir>`
- **src/build.sh**: Advanced build for different environments. Handles Go installation and cross-compilation. Usage: `src/build.sh --os <os> --arch <arch> --target-dir <dir>`
- **src/tags.sh**: List available tags from the Osmosis repo.
- **src/last_tag.sh**: Show the latest available tag.
- **src/retrieve_required_go_version.sh**: Retrieve the required Go version from Osmosis's go.mod.
- **src/launcher.go**: Source code for the launcher mode injected into osmosisd.
- **src/parse_args.sh**: Centralized argument parsing for all scripts.
- **src/resolve_os.sh** / **src/resolve_arch.sh**: Detect and validate supported OS/architecture.
- **src/validate_platform.sh**: Check if a platform combination is supported (uses `supported_platforms.json`).
- **src/get_available_ram_gb.sh**: Detect available RAM for Docker builds.

Test scripts are available in the `tests/` folder to validate each step.

## Contributing
Contributions are welcome! Please:
- Respect the script structure and naming conventions
- Document your additions
- Add tests if possible

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file.

---

> Console messages and comments are in English to ensure international compatibility of logs and scripts.


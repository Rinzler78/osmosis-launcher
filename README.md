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

## Requirements
- [git](https://git-scm.com/)
- [git-lfs](https://git-lfs.github.com/)
- [go](https://go.dev/) (required for local build if Docker is not used)
- bash (>= 4)
- [docker](https://www.docker.com/) (optional, used for building)

## Installation
1. **Clone the project**
   ```console
git clone https://github.com/Rinzler78/osmosis-launcher.git
cd osmosis-launcher
```
2. **Clone Osmosis sources**
   ```console
src/clone.sh <tag>
# Example: src/clone.sh v12.3.0
```
3. **Apply the launcher patch**
   ```console
src/patch.sh osmosis
```
4. **Build Osmosis with the launcher**
   ```console
./make.sh <tag>
# Example: ./make.sh v12.3.0
```

## Quick Start
Launch osmosisd in launcher mode:
```console
./osmosisd --launcher
```
You can then write commands to execute (example: `version`).

Launch osmosisd in launcher mode with arguments:
```console
./osmosisd --launcher optionalArg1 optionalArg2 ...
```
This is equivalent to:
```console
./osmosisd optionalArg1 optionalArg2 ...
```

## Build Process
The build is handled by the main `make.sh` script, which simplifies the process by automatically detecting if Docker is available.

- If Docker is running, it will be used to build the `osmosisd` binary in a containerized environment (`src/docker_make.sh`). This avoids the need to install Go and other dependencies on your local machine.
- If Docker is not available, the script will fall back to a local build using `src/make.sh`, which requires Go to be installed.

To build, simply run:
```console
./make.sh [tag]
```
The script will create the `osmosisd` binary in the project root.

## Scripts Details
- **make.sh**: Main build script. Automatically uses Docker if available, otherwise performs a local build.
- **src/clone.sh**: Clone the Osmosis repo at a given tag into the `osmosis` folder.
- **src/patch.sh**: Apply the patch to enable launcher mode in osmosisd.
- **src/make.sh**: Build the modified Osmosis sources locally (requires Go).
- **src/docker_make.sh**: Build the patched binary using Docker.
- **src/build.sh**: Advanced build for different environments.
- **src/tags.sh**: List available tags from the Osmosis repo.
- **src/last_tag.sh**: Show the latest available tag.
- **src/retrieve_required_go_version.sh**: Retrieve the required Go version from Osmosis's go.mod.
- **src/launcher.go**: Source code for the launcher mode injected into osmosisd.

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


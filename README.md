# civic-dev (Command Line Interface)

[![Version](https://img.shields.io/badge/version-v0.0.2-blue)](https://github.com/civic-interconnect/civic-dev/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Build](https://github.com/civic-interconnect/civic-dev/actions/workflows/build.yml/badge.svg)](https://github.com/civic-interconnect/civic-dev/actions/workflows/build.yml)
[![Nightly Zig Check](https://github.com/civic-interconnect/civic-dev/actions/workflows/zig_check.yml/badge.svg)](https://github.com/civic-interconnect/civic-dev/actions/workflows/zig_check.yml)

> A Command Line Interface (CLI) toolkit for Civic Interconnect projects.

Setup is as easy as ABC. Then we can use these CLI commands when working on Civic Interconnect.

## Setup ABC

### A. Install Zig

- Follow the [official Zig instructions](https://ziglang.org/download/) to download and install Zig.
- Ensure the Zig binary is added to your `PATH`.

### B. Install Civic Dev CLI

Build and install the CLI executable. (Use the full path to the `zig` binary if it’s not on your PATH.)

    ```zig
    zig build install
    ```

This command installs `civic-dev` into Zig’s local bin directory, e.g.:

- macOS/Linux: `~/.zig/bin`
- Windows: `%USERPROFILE%\.zig\bin`

### C. Add Civic Dev CLI to PATH

macOS / Linux – Bash

    ```bash
    echo 'export PATH="$HOME/.zig/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    ```

macOS / Linux – Zsh

    ```zsh
    echo 'export PATH="$HOME/.zig/bin:$PATH"' >> ~/.zshrc
    source ~/.zshrc
    ```

Windows – PowerShell

    ```powershell
    [System.Environment]::SetEnvironmentVariable(
        "Path",
        "$Env:Path;$Env:UserProfile\.zig\bin",
        "User"
    )
    ```

---

## Use the Civic Dev CLI

Run the Civic Dev CLI while working on Civic Interconnect projects:

```shell
civic-dev [command] [options...]
```

Examples:

```shell
civic-dev bump-version 0.0.2 0.0.2
civic-dev sync-files --project py
civic-dev check-policy
```

---

## Available Commands

| Command                  | Description                                           | Arguments / Flags |
| ------------------------ | ----------------------------------------------------- | ------------------|
| `civic-dev setup-py`     | Set up the Python environment (install dependencies). | *(none)*          |
| `civic-dev start-py`     | Start the Python environment (e.g. run dev tools).    | *(none)*          |
| `civic-dev sync-files`   | Sync shared Civic Interconnect files into the repo.   | `--root`, `--project [py|pwa]` (optional) |
| `civic-dev layout`       | Show project layout information.                      | *(none)*          |
| `civic-dev check-policy` | Check repo files against project policy.              | *(none)*          |
| `civic-dev run`          | Auto-detect and run the appropriate environment.      | *(none)*          |
| `civic-dev bump-version` | Update version numbers in files.                      | `OLD_VERSION` `NEW_VERSION` *(required)* |
| `civic-dev release`      | Run the release process for the repo.                 | *(none)*          |

---

## CLI Development

See [DEVELOPER.md](./DEVELOPER.md)

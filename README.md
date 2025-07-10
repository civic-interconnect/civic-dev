# civic-dev (Command Line Interface)

[![Version](https://img.shields.io/badge/version-v0.0.5-blue)](https://github.com/civic-interconnect/civic-dev/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Build](https://github.com/civic-interconnect/civic-dev/actions/workflows/build.yml/badge.svg)](https://github.com/civic-interconnect/civic-dev/actions/workflows/build.yml)
[![Nightly Zig Check](https://github.com/civic-interconnect/civic-dev/actions/workflows/zig_check.yml/badge.svg)](https://github.com/civic-interconnect/civic-dev/actions/workflows/zig_check.yml)

> A Command Line Interface (CLI) toolkit for Civic Interconnect projects.

## Quick Start

1. Download the latest civic-dev executable from the [Releases](https://github.com/civic-interconnect/civic-dev/releases/) page.
2. Extract the archive.
3. Include the executable file in your Path.

For example, on Windows, put the executable in C:\Users\<username>\AppData\Local\Microsoft\WindowsApps.


## Use the civic-dev CLI

Use the civic-dev CLI while working on Civic Interconnect projects:

```shell
civic-dev [command] [options...]
```

Examples:
```shell
civic-dev layout
civic-dev check-policy
```

---

## Available Commands

| Command                  | Description                                       | Arguments / Flags |
| ------------------------ | ------------------------------------------------- | ------------------|
| `civic-dev setup-py`     | Set up Python environment (install dependencies). | *(none)*          |
| `civic-dev start-py`     | Start Python environment (e.g. run dev tools).    | *(none)*          |
| `civic-dev sync-files`   | Sync shared Civic Interconnect files into repo.   | `--root`, `--project [py|pwa]` (optional) |
| `civic-dev layout`       | Show project layout information.                  | *(none)*          |
| `civic-dev check-policy` | Check repo files against project policy.          | *(none)*          |
| `civic-dev run`          | Auto-detect and run the appropriate environment.  | *(none)*          |
| `civic-dev bump-version` | Update version numbers in files.                  | `OLD_VERSION` `NEW_VERSION` *(required)* |
| `civic-dev release`      | Run release process for repo.                     | *(none)*          |

---

## CLI Development

See [DEVELOPER.md](./DEVELOPER.md)

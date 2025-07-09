# DEVELOPER.md

## Install

1. [Install Zig](https://ziglang.org/download/) (≥ version recommended in repo README).
2. [Install Git](https://git-scm.com/).
3. [Install GitHub CLI](https://cli.github.com/).
4. [Install VS Code](https://code.visualstudio.com/download)
5. [Install VS Code Extension: **Zig Language**](https://marketplace.visualstudio.com/items?itemName=ziglang.vscode-zig)

## Fork and Clone

1. GitHub: Fork this repo into your GitHub account.
2. Clone your fork to your machine, replacing `<your-username>` with your GitHub username.
3. Cd (change directory) into the new repo.
4. Install git pre-commit hooks.

    ```powershell
    git clone https://github.com/<your-username>/civic-dev.git
    cd civic-dev
    pre-commit install
    ```

## Get Started

- Open the repo folder in VS Code.
- Open a terminal to run commands.

```powershell
zig build
zig build test
zig fmt .
pre-commit run --all-files
pre-commit run --all-files
zig-out\bin\civic-dev.exe

# make updates

git add .
git commit -m "describe changes"
git push origin main

# when ready, update version in release.ps1
# then run it (it will add-commit-push changes and new tag)
./release.ps1
```

## Add to Path

Windows: copy from zig-out/bin/civic-dev.exe to C:\Users\edaci\AppData\Local\Microsoft\WindowsApps.

## Release New Version

```powershell
git pull origin main
Remove-Item -Recurse -Force .zig-cache, zig-out
zig build test
zig fmt .
pre-commit run --all-files
```

Repeat the pre-commit several times as needed.

Important: Update version numbers in the release.ps1 script before running.

```
./release.ps1
```


## Quick Workflow

Typical development flow:

```powershell
git pull
zig build test
zig fmt
zig build run -- layout
```

---

**Notes:**

- Commands are wired into `src/main.zig`.
- Shared files like policies, templates, etc. are in `shared_files/`.

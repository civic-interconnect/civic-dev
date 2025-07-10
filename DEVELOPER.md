# DEVELOPER.md

## Install

1. [Install Zig](https://ziglang.org/download/) (≥ version recommended in repo README).
2. [Install anyzig](https://marler8997.github.io/anyzig/) - and include in PATH
3. [Install Git](https://git-scm.com/).
4. [Install GitHub CLI](https://cli.github.com/).
5. [Install VS Code](https://code.visualstudio.com/download)
6. [Install VS Code Extension: **Zig Language**](https://marketplace.visualstudio.com/items?itemName=ziglang.vscode-zig)


## Fork and Clone

1. GitHub: Fork this repo into your GitHub account.
2. Clone your fork to your machine, replacing `<your-username>` with your GitHub username.
3. Cd (change directory) into the new repo.
4. Install git pre-commit hooks.

    ```powershell
    git clone https://github.com/<your-username>/civic-dev.git
    cd civic-dev
    pre-commit install
    pre-commit autoupdate
    ```

## Keep Zig updated

Update the min zig version in the build.zig.zon file. Any zig will automatically download and install it.
To switch, just say `(Get-Command zig).Source` and find the path. Delete older versions and run `zig`.

## Get Started

- Open the repo folder in VS Code.
- Open a terminal to run commands.

```powershell
zig build
zig build test
zig fmt .
pre-commit run --all-files
pre-commit run --all-files
zig build docs
zig-out\bin\civic-dev.exe

# Git add-commit-push updates

git add .
git commit -m "describe changes"
git push -u origin main

# when ready, UPDATE version numbers in release.ps1 THEN run release.ps1 (it will add-commit-push changes and new tag)
./release.ps1
```

## Add to Path

Windows: copy from zig-out/bin/civic-dev.exe to C:\Users\edaci\AppData\Local\Microsoft\WindowsApps.

## Release New Version

```powershell
git pull origin main
Remove-Item -Recurse -Force .zig-cache, zig-out
zig build
zig build test
zig fmt .
pre-commit run --all-files
pre-commit run --all-files
zig build docs
zig-out\bin\civic-dev.exe layout
zig-out\bin\civic-dev.exe check-policy
```

Repeat the pre-commit several times as needed.

Test locally: Copy `zig-out/bin/civic-dev.exe` to include it in your PATH.
- For example, on Windows, put the executable in C:\Users\<username>\AppData\Local\Microsoft\WindowsApps.

```pwsh
civic-dev layout
civic-dev check-policy
```

## Manual Updates for Documentation on GH Pages

In **docs/main.js**, change sources to ./sources:

    ```javascript
    let sources_promise = fetch("sources.tar").then(function(response) {

    let sources_promise = fetch("./sources.tar").then(function(response) {
    ```

In **docs/index.html**:

1. Add base script at the top of `body`:

    ```html
    <body>
    <script>
        (function () {
        const isGhPages = location.hostname.endsWith('.github.io');
        if (isGhPages) {
            const repo = '/civic-dev/docs/';
            const base = document.createElement('base');
            base.href = repo;
            document.head.appendChild(base);
        }
        else {
            console.log('Running in local mode — no <base> tag needed.');
        }
        })();
    </script>
    ```

2. Change main to ./main :

    ```html
    <script src="main.js"></script>
    <script src="./main.js"></script>
    ```

3. In kbd styles, delete:

    `box-shadow-color: #c6cbd1; `

4. In kbd styles, change

    `box-shadow: inset 0 -1px 0;`
    to:
    `box-shadow: inset 0 -1px 0 #c6cbd1;`

```

## Manually Update docs/

**Important**: Update version numbers in the release.ps1 script before running.

```
./release.ps1
```

## AnyZig Notes

zig any
zig zen

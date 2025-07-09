# release.ps1
# This script automates the release process for the civic-dev CLI tool.
# It includes pulling the latest code, cleaning the build, running tests,
# bumping the version, committing changes, tagging the release, building the
# release binary, moving it to the releases folder, creating a zip archive,
# and publishing the release on GitHub.

# Requirements:
# - Git installed and configured
# - Zig installed and configured
# - GitHub CLI installed and authenticated
# - PowerShell environment

# IMPORTANT:
# - Edit the `$oldVersion` and `$newVersion` variables.

# Run (after updating the version variables):
# 1. Open PowerShell.
# 2. Navigate to the directory containing this script.
# 4. Run the script: `.\release.ps1`

# Set your versions
$oldVersion = "0.0.2"
$newVersion = "0.0.3"

$ErrorActionPreference = "Stop"

function Invoke-Checked {
    param([string]$cmd)
    Write-Host "Running: $cmd"
    Invoke-Expression $cmd
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Command failed: $cmd"
        exit 1
    }
}

# Always pull the latest code
Invoke-Checked "git pull origin main"

# Clean everything
@(".zig-cache", "zig-out") | ForEach-Object {
    if (Test-Path $_) {
        Write-Host "Removing $_..."
        Remove-Item -Recurse -Force $_
    }
}

# Run tests before bumping
Invoke-Checked "zig build test"

# Build for release (ReleaseSafe)
Invoke-Checked "zig build -Doptimize=ReleaseSafe"

# Bump version in files
$exe = ".\zig-out\bin\civic-dev.exe"
if (-not (Test-Path $exe)) {
    Write-Error "ERROR: civic-dev.exe not found. Did you run zig build?"
    exit 1
}
Invoke-Checked "& $exe bump-version $oldVersion $newVersion"

# Commit version bump
Invoke-Checked "git add ."
Invoke-Checked 'git commit -m "chore(release): bump version to v$newVersion"'

# Tag the release
Invoke-Checked "git tag v$newVersion"

# Push code and tag
Invoke-Checked "git push origin main"
Invoke-Checked "git push origin v$newVersion"

#==================================================================
# Remaining commands are automated in .github/workflows/release.yml
#==================================================================
# Build release binary
# zig build -Drelease-safe=true

# Move binary into release folder
# Move-Item ./zig-out/bin/civic-dev.exe ./releases/civic-dev.exe -Force

# Create a zip archive
# Compress-Archive ./releases/civic-dev.exe civic-dev-windows.zip -Force

# Publish release on GitHub
# gh release create v$newVersion civic-dev-windows.zip --title "v$newVersion" --notes "Release notes."

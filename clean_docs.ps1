<#
.SYNOPSIS
    Cleans the local ./docs folder before regenerating documentation.

.DESCRIPTION
    This script safely removes the ./docs directory
    to ensure that newly generated documentation does not mix with
    old or obsolete files.

.NOTES
    - Intended for use as part of the civic-dev Zig build process.
    - Safe to run multiple times.

.EXAMPLE
    ./clean_docs.ps1
#>

$docsPath = Join-Path -Path (Get-Location) -ChildPath "docs"
$zigDocsPath = Join-Path -Path (Get-Location) -ChildPath "zig-out/docs"

if (Test-Path $docsPath) {
    Write-Host "Removing existing ./docs folder..."
    Remove-Item -Path $docsPath -Recurse -Force
} else {
    Write-Host "No existing ./docs folder to remove."
}

Write-Host "Copying from $zigDocsPath to $docsPath...   "
if (Test-Path $zigDocsPath) {
    # Create the destination directory if it doesn't exist
    if (-not (Test-Path $docsPath)) {
        New-Item -ItemType Directory -Path $docsPath | Out-Null
    }
    # Copy all contents recursively
    Copy-Item -Path "$zigDocsPath\*" -Destination $docsPath -Recurse -Force
    Write-Host "Documentation copied successfully."
} else {
    Write-Warning "WARNING: Documentation source path '$zigDocsPath' not found. Skipping docs copy."
}

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

if (Test-Path $docsPath) {
    Write-Host "Removing existing ./docs folder..."
    Remove-Item -Path $docsPath -Recurse -Force
} else {
    Write-Host "No existing ./docs folder to remove."
}

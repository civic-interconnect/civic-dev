<#
.SCRIPTNAME
    docs_copy.ps1

.SYNOPSIS
Copies Zig-generated documentation from the build output
into the local ./docs folder for deployment or local viewing.

Typically run after:
    zig build docs

Pairs with:
    - docs_clean.ps1
    - docs_post.ps1
#>

$docsPath = Join-Path -Path (Get-Location) -ChildPath "docs"
$zigDocsPath = Join-Path -Path (Get-Location) -ChildPath "zig-out/docs"

if (Test-Path $zigDocsPath) {
    Write-Host "Copying documentation from '$zigDocsPath' to '$docsPath'..."

    # Ensure the destination directory exists
    if (-not (Test-Path $docsPath)) {
        Write-Host "Creating docs folder at: $docsPath"
        New-Item -ItemType Directory -Path $docsPath | Out-Null
    }

    # Copy all contents recursively, overwriting as needed
    Copy-Item -Path (Join-Path $zigDocsPath '*') -Destination $docsPath -Recurse -Force

    Write-Host "Documentation copied successfully."
}
else {
    Write-Warning "WARNING: Documentation source path '$zigDocsPath' not found. Skipping docs copy."
}

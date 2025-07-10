$docsPath = Join-Path -Path (Get-Location) -ChildPath "docs"
$zigDocsPath = Join-Path -Path (Get-Location) -ChildPath "zig-out/docs"

if (Test-Path $zigDocsPath) {
    Write-Host "Copying documentation from '$zigDocsPath' to '$docsPath'..."
    # Create the destination directory if it doesn't exist
    if (-not (Test-Path $docsPath)) {
        New-Item -ItemType Directory -Path $docsPath | Out-Null
    }
    # Copy all contents recursively
    Copy-Item -Path "$zigDocsPath\*" -Destination $docsPath -Recurse -Force
} else {
    Write-Warning "WARNING: Documentation source path '$zigDocsPath' not found. Skipping docs copy."
}

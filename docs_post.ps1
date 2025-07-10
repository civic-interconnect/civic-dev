<#
.SCRIPTNAME
    post_docs.ps1

.SYNOPSIS
Post-processing script for Civic Dev Zig-generated docs.

- Adjusts paths for local + GitHub Pages use.
- Removes problematic styles.
- Ensures sources.tar loads from relative path.
#>

Write-Host "Running post_docs.ps1 ..."

$indexPath = Join-Path -Path "." -ChildPath "docs\index.html"
$mainJsPath = Join-Path -Path "." -ChildPath "docs\main.js"

# --- Patch docs/index.html ---

if (Test-Path $indexPath) {
    Write-Host "Patching $indexPath ..."

    $content = Get-Content $indexPath -Raw

    # Change <script src="main.js"> to ./main.js
    $content = $content -replace '<script src="main\.js">', '<script src="./main.js">'

    # Remove box-shadow-color style rule entirely
    $content = $content -replace 'box-shadow-color:[^;"]*;', ''

    # Change box-shadow rule:
    # box-shadow: inset 0 -1px 0;
    # → box-shadow: inset 0 -1px 0 #c6cbd1;
    $content = $content -replace 'box-shadow:\s*inset 0 -1px 0;', 'box-shadow: inset 0 -1px 0 #c6cbd1;'

    # Add dynamic <base> tag logic at top of body
    if ($content -notmatch 'Running in local mode') {
        $baseScript = @"
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
"@

        # Insert right after opening <body>
        $content = $content -replace '(<body[^>]*>)', "`$1`n$baseScript"
    }

    Set-Content -Path $indexPath -Value $content -Encoding UTF8
    Write-Host "Updated $indexPath"
} else {
    Write-Warning "$indexPath not found"
}

# --- Patch docs/main.js ---

if (Test-Path $mainJsPath) {
    Write-Host "Patching $mainJsPath ..."

    $content = Get-Content $mainJsPath -Raw

    # Replace fetch("sources.tar") → fetch("./sources.tar")
    $content = $content -replace 'fetch\("sources\.tar"\)', 'fetch("./sources.tar")'

    Set-Content -Path $mainJsPath -Value $content -Encoding UTF8
    Write-Host "Updated $mainJsPath"
} else {
    Write-Warning "$mainJsPath not found"
}

Write-Host "post_docs.ps1 finished."

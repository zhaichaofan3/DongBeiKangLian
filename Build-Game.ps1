$ErrorActionPreference = 'Stop'
$engine = & (Join-Path $PSScriptRoot 'tools\Find-Godot.ps1')
$project = Join-Path $PSScriptRoot 'GodotProject'
$release = Join-Path $PSScriptRoot 'Release'
New-Item -ItemType Directory -Path $release -Force | Out-Null
# --import waits for worker imports and exits on its own.
& $engine --headless --path $project --import
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
$runtime = Join-Path (Split-Path -Parent $engine) ((Split-Path -Leaf $engine) -replace '_console(?=\.exe$)', '')
if (-not (Test-Path -LiteralPath $runtime)) { throw 'The standard Godot runtime is missing.' }
$pendingPack = Join-Path $release 'FenghuoEcho.pending.pck'
$finalPack = Join-Path $release 'FenghuoEcho.pck'
try {
    & $engine --headless --path $project --export-pack 'Windows Portable' $pendingPack
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $pendingPack) -or (Get-Item -LiteralPath $pendingPack).Length -eq 0) {
        throw 'Resource pack export failed. The previous release pack is unchanged.'
    }
    if (Test-Path -LiteralPath $finalPack) {
        [IO.File]::Replace($pendingPack, $finalPack, [System.Management.Automation.Language.NullString]::Value)
    } else {
        [IO.File]::Move($pendingPack, $finalPack)
    }
} finally {
    if (Test-Path -LiteralPath $pendingPack) { Remove-Item -LiteralPath $pendingPack }
}
$pendingValidation = [ordered]@{
    passed = $false
    status = 'validation_pending'
    created_at = [DateTimeOffset]::Now.ToString('o')
    pack_sha256 = (Get-FileHash -LiteralPath $finalPack).Hash.ToLowerInvariant()
    note = 'This pack was rebuilt. Previous validation does not apply; run package checks and record their results.'
}
$pendingValidation | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $release 'release_validation.json') -Encoding utf8
$releaseRuntime = Join-Path $release 'FenghuoEcho.exe'
if (-not (Test-Path -LiteralPath $releaseRuntime) -or (Get-FileHash -LiteralPath $runtime).Hash -ne (Get-FileHash -LiteralPath $releaseRuntime).Hash) {
    Copy-Item -LiteralPath $runtime -Destination $releaseRuntime -Force
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'licenses\GODOT_LICENSE.txt'),(Join-Path $PSScriptRoot 'licenses\GODOT_COPYRIGHT.txt') -Destination $release -Force
Copy-Item -LiteralPath (Join-Path $project 'ASSET_SOURCES.md'),(Join-Path $project 'README.md'),(Join-Path $project 'VERIFICATION.md'),(Join-Path $project 'KNOWN_ISSUES.md') -Destination $release -Force
$sums = Get-ChildItem -LiteralPath $release -Recurse -File | Where-Object {
    $_.Name -ne 'SHA256SUMS.txt' -and [IO.Path]::GetRelativePath($release, $_.FullName) -notlike 'Distributions\*'
} | Sort-Object FullName | ForEach-Object {
    (Get-FileHash -LiteralPath $_.FullName).Hash.ToLowerInvariant() + '  ' + [IO.Path]::GetRelativePath($release, $_.FullName).Replace('\', '/')
}
$sums | Set-Content -LiteralPath (Join-Path $release 'SHA256SUMS.txt') -Encoding utf8
Write-Output (Join-Path $release 'FenghuoEcho.exe')

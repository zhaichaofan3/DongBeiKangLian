$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$report = Join-Path $root 'docs\courtyard_revision_20261016'

function Read-Regression([string]$batch) {
    $directory = Join-Path $root "docs\validation\courtyard-$batch"
    $logs = @(Get-ChildItem -LiteralPath $directory -Recurse -Filter '*.log')
    if ($logs.Count -ne 31) { throw "Expected 31 $batch regression logs, found $($logs.Count)." }
    $results = foreach ($file in $logs) {
        $content = Get-Content -LiteralPath $file.FullName -Raw
        $marker = @($content -split "`n" | Where-Object { $_ -match '^[A-Z0-9 ]+(?:RESULT: [0-9]+/[0-9]+ passed|: PASS)' }) | Select-Object -Last 1
        if (-not $marker -or $content -match '(?m)^(SCRIPT ERROR|ERROR|FAIL):') {
            throw "Incomplete or failed validation: $($file.FullName)"
        }
        $relative = [IO.Path]::GetRelativePath($directory, $file.FullName)
        $destination = Join-Path $report "$batch\$relative"
        New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
        [ordered]@{ name = $relative.Replace('\', '/'); result = $marker.Trim(); sha256 = (Get-FileHash -LiteralPath $file.FullName).Hash.ToLowerInvariant() }
    }
    return [ordered]@{ groups = $results.Count; passed = $true; results = @($results) }
}

$source = Read-Regression 'source'
$release = Read-Regression 'release'
$sourceNames = @($source.results | ForEach-Object { $_.name })
$releaseNames = @($release.results | ForEach-Object { $_.name.Replace('integration.log', 'smoke.log') })
if (Compare-Object $sourceNames $releaseNames) { throw 'Source and release check groups differ.' }

$baseline = Get-Content (Join-Path $root 'docs\maintenance\repository-20261016\protected-files.json') -Raw | ConvertFrom-Json
$protected = @($baseline | Where-Object { $_.path -match '^GodotProject/assets/(audio|first_person)/' -or $_.path -eq 'GodotProject/scripts/fp_hands.gd' })
foreach ($file in $protected) {
    if ((Get-FileHash -LiteralPath (Join-Path $root $file.path)).Hash.ToLowerInvariant() -ne $file.sha256) {
        throw "Protected asset changed: $($file.path)"
    }
}

$captures = foreach ($name in @('street-standing', 'street-crouched', 'courtyard-lean', 'opening-village', 'settings-bindings')) {
    $path = Join-Path $root "docs\validation\courtyard-release-render\$name.png"
    if (-not (Test-Path -LiteralPath $path)) { throw "Missing release capture: $name" }
    Copy-Item -LiteralPath $path -Destination (Join-Path $report "$name.png") -Force
    [ordered]@{ file = "$name.png"; sha256 = (Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant() }
}
foreach ($name in @('run.log', 'presentation.json')) {
    Copy-Item -LiteralPath (Join-Path $root "docs\validation\courtyard-release-render\$name") -Destination (Join-Path $report "render-$name") -Force
}
$presentation = Get-Content (Join-Path $report 'render-presentation.json') -Raw | ConvertFrom-Json
if (-not $presentation.passed) { throw 'Release presentation failed.' }
$smallPresentation = Get-Content (Join-Path $root 'docs\validation\courtyard-release-render-960\presentation.json') -Raw | ConvertFrom-Json
if (-not $smallPresentation.passed) { throw 'Small-window release presentation failed.' }
Copy-Item -LiteralPath (Join-Path $root 'docs\validation\courtyard-release-render-960\run.log') -Destination (Join-Path $report 'render-960.log') -Force
$worldRender = Get-Content (Join-Path $root 'docs\validation\courtyard-release-world\validation.json') -Raw | ConvertFrom-Json
if (-not $worldRender.passed) { throw 'Rendered world revision failed.' }
Copy-Item -LiteralPath (Join-Path $root 'docs\validation\courtyard-release-world\run.log') -Destination (Join-Path $report 'render-world.log') -Force
foreach ($name in @('telegraph', 'ferry')) {
    $path = Join-Path $root "docs\validation\courtyard-release-world\$name.png"
    Copy-Item -LiteralPath $path -Destination (Join-Path $report "$name.png") -Force
    $captures += [ordered]@{ file = "$name.png"; sha256 = (Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant() }
}
$renderCombat = Join-Path $root 'docs\validation\courtyard-release-render\combat-route.log'
$combatContent = Get-Content -LiteralPath $renderCombat -Raw
if ($combatContent -notmatch 'ACTIVE COMBAT ROUTE: PASS' -or $combatContent -match '(?m)^(SCRIPT ERROR|ERROR):') { throw 'Rendered release combat failed.' }
Copy-Item -LiteralPath $renderCombat -Destination (Join-Path $report 'render-combat-route.log') -Force

$record = [ordered]@{
    version = '0.7.1-rc1'
    revision = '20261016-courtyard-controls'
    created_at = [DateTimeOffset]::Now.ToString('o')
    passed = $true
    source = $source
    release = $release
    presentation = $presentation
    small_presentation = $smallPresentation
    rendered_world = $worldRender
    rendered_combat = ($combatContent -split "`n" | Where-Object { $_ -match '^ACTIVE COMBAT ROUTE:' } | Select-Object -Last 1).Trim()
    protected_files = $protected.Count
    protected_changes = 0
    captures = @($captures)
    pack_sha256 = (Get-FileHash -LiteralPath (Join-Path $root 'Release\FenghuoEcho.pck')).Hash.ToLowerInvariant()
    limitations = @('Automatic aim does not assess human difficulty.', 'Continuous art, acting, audio listening and other hardware remain pending.')
}
$record | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $report 'final-validation.json') -Encoding utf8
$record | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Join-Path $root 'Release\release_validation.json') -Encoding utf8
foreach ($name in @('README.md', 'KNOWN_ISSUES.md', 'VERIFICATION.md')) {
    Copy-Item -LiteralPath (Join-Path $root "GodotProject\$name") -Destination (Join-Path $root "Release\$name") -Force
}
Copy-Item -LiteralPath (Join-Path $report 'release-notes.md') -Destination (Join-Path $root 'Release\RELEASE_NOTES.md') -Force
$releaseRoot = Join-Path $root 'Release'
$sums = Get-ChildItem -LiteralPath $releaseRoot -Recurse -File | Where-Object { $_.Name -ne 'SHA256SUMS.txt' -and $_.FullName -notlike "$releaseRoot\Validation\*" } | Sort-Object FullName | ForEach-Object {
    (Get-FileHash -LiteralPath $_.FullName).Hash.ToLowerInvariant() + '  ' + [IO.Path]::GetRelativePath($releaseRoot, $_.FullName).Replace('\', '/')
}
$sums | Set-Content -LiteralPath (Join-Path $releaseRoot 'SHA256SUMS.txt') -Encoding utf8
Write-Output "Recorded source/release 31 groups, $($protected.Count) protected files and final release checksums."

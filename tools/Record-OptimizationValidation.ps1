$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$inputRoot = Join-Path $root 'docs\validation\optimization-20261016'
$report = Join-Path $root 'docs\optimization_20261016'
New-Item -ItemType Directory -Path $report -Force | Out-Null

function Read-Regression([string]$batch) {
    $directory = Join-Path $inputRoot $batch
    $logs = @(Get-ChildItem -LiteralPath $directory -Recurse -Filter '*.log' | Where-Object { $_.Name -notlike '*retry*' } | Sort-Object FullName)
    $expected = if ($batch -eq 'source') { 32 } else { 7 }
    if ($logs.Count -ne $expected) { throw "Expected $expected $batch regression logs, found $($logs.Count)." }
    $results = foreach ($file in $logs) {
        $content = Get-Content -LiteralPath $file.FullName -Raw
        $marker = @($content -split "`n" | Where-Object { $_ -match '^[A-Z0-9 ]+(?:RESULT: ([0-9]+)/\1 passed|: PASS)' }) | Select-Object -Last 1
        if (-not $marker -or $content -match '(?m)^(SCRIPT ERROR|ERROR|FAIL):') { throw "Failed or incomplete check: $($file.FullName)" }
        $relative = [IO.Path]::GetRelativePath($directory, $file.FullName)
        $destination = Join-Path $report "$batch\$relative"
        New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
        [ordered]@{ name = $relative.Replace('\', '/'); result = $marker.Trim(); sha256 = (Get-FileHash -LiteralPath $file.FullName).Hash.ToLowerInvariant() }
    }
    return [ordered]@{ groups = $results.Count; passed = $true; results = @($results) }
}

function Read-Evidence([string]$relative, [string]$destination) {
    $path = Join-Path $inputRoot $relative
    $data = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    Copy-Item -LiteralPath $path -Destination (Join-Path $report $destination) -Force
    return $data
}

$source = Read-Regression 'source'
$release = Read-Regression 'release'
$sourceNames = @($source.results | ForEach-Object { $_.name })
$releaseNames = @($release.results | ForEach-Object { $_.name.Replace('integration.log', 'smoke.log') })
$expectedRelease = @('smoke.log','linear-route.log','courtyard-controls.log','river-journey.log','first-level-rebuild.log','settlement-revision.log','user-expansion.log')
$normalizedRelease = @($releaseNames | ForEach-Object { $_.Replace('courtyard-controls.log','opening-checks/courtyard_controls/run.log').Replace('river-journey.log','opening-checks/river_journey/run.log').Replace('first-level-rebuild.log','opening-checks/first_level_rebuild/run.log').Replace('settlement-revision.log','opening-checks/settlement_revision/run.log').Replace('user-expansion.log','opening-checks/user_expansion/run.log') })
if (@($normalizedRelease | Where-Object { $_ -notin $sourceNames }).Count) { throw 'Package checks differ from their source counterparts.' }
if (Compare-Object ($releaseNames | Sort-Object) ($expectedRelease | Sort-Object)) { throw 'Targeted package checks incomplete.' }

$navigation = Read-Evidence 'release-navigation.json' 'navigation.json'
if (-not $navigation.passed -or $navigation.reachable_cells -ne 79589 -or $navigation.reachable_sha256 -ne 'bf6c80496a4ce18b9ea367c8041bf4c5aa3cc68887e509a3e9974dfed7906980') { throw 'Reachable navigation graph changed.' }
$renderQuality = Read-Evidence 'release-render-quality\validation.json' 'render-quality.json'
if (-not $renderQuality.passed -or -not $renderQuality.instance_bounds_checked -or $renderQuality.checks -ne 39) { throw 'Rendered quality checks failed.' }
$renderWorld = Read-Evidence 'release-world\validation.json' 'render-world.json'
if (-not $renderWorld.passed -or $renderWorld.checks -ne 54) { throw 'Rendered world checks failed.' }
$balanced = Read-Evidence 'release-balanced\performance.json' 'balanced-cameras.json'
$high = Read-Evidence 'release-high\performance.json' 'high-cameras.json'
foreach ($cameraData in @($balanced, $high)) {
    if (-not $cameraData.measurement_valid -or $cameraData.rows.Count -ne 8 -or $cameraData.version -ne '0.7.2-rc1' -or $cameraData.resolution[0] -ne 1920 -or $cameraData.resolution[1] -ne 1080 -or $cameraData.render_scale_3d -ne 1) { throw 'Camera measurements invalid.' }
}
if ($balanced.quality -ne 1 -or $high.quality -ne 2) { throw 'Camera quality presets differ from the requested runs.' }
$combat = Read-Evidence 'release-combat.json' 'combat-performance.json'
if (-not $combat.measurement_valid -or -not $combat.route_passed -or $combat.version -ne '0.7.2-rc1' -or $combat.player_shots_observed -lt 1 -or $combat.enemy_shots_observed -lt 1) { throw 'Real-time package combat measurement failed.' }

$baseline = Get-Content (Join-Path $root 'docs\maintenance\repository-20261016\protected-files.json') -Raw | ConvertFrom-Json
$protected = @($baseline | Where-Object { $_.path -match '^GodotProject/assets/(audio|first_person)/' -or $_.path -eq 'GodotProject/scripts/fp_hands.gd' })
foreach ($file in $protected) {
    if ((Get-FileHash -LiteralPath (Join-Path $root $file.path)).Hash.ToLowerInvariant() -ne $file.sha256) { throw "Protected asset changed: $($file.path)" }
}

foreach ($item in @(
    @('baseline-navigation.json','baseline-navigation.json'),
    @('baseline-combat.json','baseline-combat-performance.json'),
    @('repeat-baseline\performance.json','baseline-cameras.json')
)) { Copy-Item -LiteralPath (Join-Path $inputRoot $item[0]) -Destination (Join-Path $report $item[1]) -Force }
foreach ($name in @('release-navigation','release-render-quality','release-world','release-balanced','release-high','release-combat')) {
    $path = Join-Path $inputRoot "$name.log"
    $content = Get-Content -LiteralPath $path -Raw
    if ($content -match '(?m)^(SCRIPT ERROR|ERROR|FAIL):') { throw "Failure in final rendered log: $name" }
    Copy-Item -LiteralPath $path -Destination (Join-Path $report "$name.log") -Force
}

$captures = foreach ($name in @('forest_contact','forest_approach','village_street','river')) {
    $path = Join-Path $inputRoot "release-high\$name.png"
    Copy-Item -LiteralPath $path -Destination (Join-Path $report "$name.png") -Force
    [ordered]@{ file = "$name.png"; quality = 'high'; sha256 = (Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant() }
}
$record = [ordered]@{
    version = '0.7.2-rc1'
    revision = '20261016-performance-quality'
    created_at = [DateTimeOffset]::Now.ToString('o')
    passed = $true
    source = $source
    release = $release
    navigation = $navigation
    rendered_quality = $renderQuality
    rendered_world = $renderWorld
    cameras = [ordered]@{ balanced_valid = $balanced.measurement_valid; high_valid = $high.measurement_valid; balanced_unfocused_frames = $balanced.unfocused_frames; high_unfocused_frames = $high.unfocused_frames }
    rendered_combat = $combat
    protected_files = $protected.Count
    protected_changes = 0
    captures = @($captures)
    baseline_pack_sha256 = 'cb08eea5f35ea686d422d1781e1ce8759d99f407741b24c14db7b61447e0852b'
    pack_sha256 = (Get-FileHash -LiteralPath (Join-Path $root 'Release\FenghuoEcho.pck')).Hash.ToLowerInvariant()
    limitations = @('Camera FPS changes vary by view and session; no universal improvement percentage.', 'Navigation and scenery startup costs remain before launch.', 'Automatic aim does not assess human difficulty.', 'Continuous art, acting, audio listening and other hardware remain pending.')
}
$record | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $report 'final-validation.json') -Encoding utf8
$record | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath (Join-Path $root 'Release\release_validation.json') -Encoding utf8
foreach ($name in @('README.md','KNOWN_ISSUES.md','VERIFICATION.md')) {
    Copy-Item -LiteralPath (Join-Path $root "GodotProject\$name") -Destination (Join-Path $root "Release\$name") -Force
}
Copy-Item -LiteralPath (Join-Path $report 'release-notes.md') -Destination (Join-Path $root 'Release\RELEASE_NOTES.md') -Force
$releaseEvidence = Join-Path $root 'Release\Validation\optimization_20261016'
New-Item -ItemType Directory -Path $releaseEvidence -Force | Out-Null
Get-ChildItem -LiteralPath $report -File | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $releaseEvidence -Force }
$releaseRoot = Join-Path $root 'Release'
$sums = Get-ChildItem -LiteralPath $releaseRoot -Recurse -File | Where-Object { $_.Name -ne 'SHA256SUMS.txt' } | Sort-Object FullName | ForEach-Object {
    (Get-FileHash -LiteralPath $_.FullName).Hash.ToLowerInvariant() + '  ' + [IO.Path]::GetRelativePath($releaseRoot, $_.FullName).Replace('\', '/')
}
$sums | Set-Content -LiteralPath (Join-Path $releaseRoot 'SHA256SUMS.txt') -Encoding utf8
Write-Output "Recorded 32 source groups, 7 targeted package groups, 39 quality/54 world rendered checks, navigation fingerprint, real-time combat and $($protected.Count) protected files."

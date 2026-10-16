$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$inputRoot = Join-Path $root 'docs\validation\optimization-20261016'
$report = Join-Path $root 'docs\optimization_20261016'
$packBuiltAt = (Get-Item -LiteralPath (Join-Path $root 'Release\FenghuoEcho.pck')).LastWriteTimeUtc
New-Item -ItemType Directory -Path $report -Force | Out-Null

function Read-Regression([string]$batch) {
    $directory = Join-Path $inputRoot $batch
    $logs = @(Get-ChildItem -LiteralPath $directory -Recurse -Filter '*.log' | Where-Object { $_.Name -notlike '*retry*' } | Sort-Object FullName)
    $expected = if ($batch -eq 'final-source') { 33 } else { 9 }
    if ($logs.Count -ne $expected) { throw "Expected $expected $batch regression logs, found $($logs.Count)." }
    $results = foreach ($file in $logs) {
        if ($batch -eq 'final-release' -and $file.LastWriteTimeUtc -lt $packBuiltAt) { throw "Package log predates this build: $($file.FullName)" }
        $content = Get-Content -LiteralPath $file.FullName -Raw
        $marker = @($content -split "`n" | Where-Object { $_ -match '^[A-Z0-9 ]+(?:RESULT: ([0-9]+)/\1 passed|: PASS)' }) | Select-Object -Last 1
        if (-not $marker -or $content -match '(?m)^(SCRIPT ERROR|ERROR|FAIL):') { throw "Failed or incomplete check: $($file.FullName)" }
        $relative = [IO.Path]::GetRelativePath($directory, $file.FullName)
        $destination = Join-Path $report "$($batch.Replace('final-', ''))\$relative"
        New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
        [ordered]@{ name = $relative.Replace('\', '/'); result = $marker.Trim(); sha256 = (Get-FileHash -LiteralPath $file.FullName).Hash.ToLowerInvariant() }
    }
    return [ordered]@{ groups = $results.Count; passed = $true; results = @($results) }
}

function Read-Evidence([string]$relative, [string]$destination) {
    $path = Join-Path $inputRoot $relative
    if ($relative.StartsWith('release-') -and (Get-Item -LiteralPath $path).LastWriteTimeUtc -lt $packBuiltAt) { throw "Evidence predates this build: $relative" }
    $data = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    Copy-Item -LiteralPath $path -Destination (Join-Path $report $destination) -Force
    return $data
}

$source = Read-Regression 'final-source'
$release = Read-Regression 'final-release'
$sourceNames = @($source.results | ForEach-Object { $_.name })
$releaseNames = @($release.results | ForEach-Object { $_.name })
$expectedRelease = @('smoke.log','linear_route.log','visual_motion.log','courtyard_controls.log','river_journey.log','first_level_rebuild.log','settlement_revision.log','user_expansion.log','surface_loading.log')
$normalizedRelease = @($releaseNames | ForEach-Object {
    if ($_ -eq 'linear_route.log') { 'linear-route.log' }
    elseif ($_ -eq 'visual_motion.log') { 'visual-motion.log' }
    elseif ($_ -eq 'smoke.log') { $_ }
    else { 'opening-checks/' + $_.Replace('.log', '') + '/run.log' }
})
if (@($normalizedRelease | Where-Object { $_ -notin $sourceNames }).Count) { throw 'Package checks differ from their source counterparts.' }
if (Compare-Object ($releaseNames | Sort-Object) ($expectedRelease | Sort-Object)) { throw 'Targeted package checks incomplete.' }

$navigation = Read-Evidence 'release-navigation.json' 'navigation.json'
$sourceNavigation = Read-Evidence 'final-source-navigation.json' 'source-navigation.json'
$navigationDelta = Read-Evidence 'navigation-delta.json' 'navigation-delta.json'
if (-not $navigation.passed -or -not $sourceNavigation.passed -or $navigation.reachable_sha256 -ne $sourceNavigation.reachable_sha256 -or -not $navigationDelta.passed) { throw 'Package navigation differs from the audited source graph.' }
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
$arrival = Read-Evidence 'release-arrival.json' 'arrival-performance.json'
if (-not $arrival.passed -or -not $arrival.rendered -or $arrival.physics_engine -ne 'Jolt Physics') { throw 'Rendered arrival check failed.' }
$loading = Read-Evidence 'release-surface-loading/validation.json' 'surface-loading.json'
if (-not $loading.passed -or -not $loading.rendered -or $loading.checks -ne 31) { throw 'Rendered terrain/loading checks failed.' }

$baseline = Get-Content (Join-Path $root 'docs\maintenance\repository-20261016\protected-files.json') -Raw | ConvertFrom-Json
$protected = @($baseline | Where-Object { $_.path -match '^GodotProject/assets/(audio|first_person)/' })
foreach ($file in $protected) {
    if ((Get-FileHash -LiteralPath (Join-Path $root $file.path)).Hash.ToLowerInvariant() -ne $file.sha256) { throw "Protected asset changed: $($file.path)" }
}

foreach ($item in @(
    @('baseline-navigation.json','baseline-navigation.json'),
    @('baseline-combat.json','baseline-combat-performance.json'),
    @('repeat-baseline\performance.json','baseline-cameras.json')
)) { Copy-Item -LiteralPath (Join-Path $inputRoot $item[0]) -Destination (Join-Path $report $item[1]) -Force }
foreach ($name in @('release-navigation','release-render-quality','release-world','release-balanced','release-high','release-combat','release-arrival','release-surface-loading')) {
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
foreach ($name in @('forest-village-bend','ferry-surface','rifle-support','reload-39','reload-60')) {
    $path = Join-Path $inputRoot "release-surface-loading/$name.png"
    Copy-Item -LiteralPath $path -Destination (Join-Path $report "$name.png") -Force
    $captures += [ordered]@{ file = "$name.png"; quality = 'balanced'; sha256 = (Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant() }
}
Copy-Item -LiteralPath (Join-Path $inputRoot 'source-first-level-exit.log') -Destination (Join-Path $report 'source-first-level-exit.log') -Force
Copy-Item -LiteralPath (Join-Path $inputRoot 'final-build.log') -Destination (Join-Path $report 'build.log') -Force
$record = [ordered]@{
    version = '0.7.2-rc1'
    revision = '20261016-performance-quality'
    created_at = [DateTimeOffset]::Now.ToString('o')
    passed = $true
    source = $source
    release = $release
    navigation = $navigation
    navigation_delta = $navigationDelta
    rendered_quality = $renderQuality
    rendered_world = $renderWorld
    cameras = [ordered]@{ balanced_valid = $balanced.measurement_valid; high_valid = $high.measurement_valid; balanced_unfocused_frames = $balanced.unfocused_frames; high_unfocused_frames = $high.unfocused_frames }
    rendered_combat = $combat
    rendered_arrival = $arrival
    rendered_surface_loading = $loading
    protected_files = $protected.Count
    protected_changes = 0
    captures = @($captures)
    baseline_pack_sha256 = 'cb08eea5f35ea686d422d1781e1ce8759d99f407741b24c14db7b61447e0852b'
    pack_sha256 = (Get-FileHash -LiteralPath (Join-Path $root 'Release\FenghuoEcho.pck')).Hash.ToLowerInvariant()
    limitations = @('Camera FPS changes vary by view and session; no universal improvement percentage.', 'Navigation and scenery startup costs remain before launch.', 'One 635ms ferry-area gameplay frame remains in the final combat sample; its cause is not yet isolated.', 'Automatic aim does not assess human difficulty.', 'Continuous art, acting, audio listening and other hardware remain pending.')
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
Write-Output "Recorded 33 source groups, 9 targeted package groups, 39 quality/54 world/31 surface-loading rendered checks, audited navigation, real-time combat and $($protected.Count) protected assets."

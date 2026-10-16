param([string]$OutputDirectory = 'docs/validation/optimization-20261016')

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$engine = & (Join-Path $PSScriptRoot 'Find-Godot.ps1')
$pack = Join-Path $root 'Release/FenghuoEcho.pck'
$output = Join-Path $root $OutputDirectory
New-Item -ItemType Directory -Path $output -Force | Out-Null
$checks = @(
    @('render_quality', 'release-render-quality', 'FENGHUO_RENDER_QUALITY_EVIDENCE', 'RENDER QUALITY: PASS'),
    @('world_revision', 'release-world', 'FENGHUO_WORLD_EVIDENCE', 'WORLD REVISION: PASS'),
    @('surface_loading', 'release-surface-loading', 'FENGHUO_SURFACE_LOADING_OUTPUT', 'SURFACE LOADING: PASS'),
    @('arrival_budget', 'release-arrival.json', 'FENGHUO_ARRIVAL_OUTPUT', 'ARRIVAL BUDGET:'),
    @('navigation_budget', 'release-navigation.json', 'FENGHUO_NAVIGATION_OUTPUT', 'NAVIGATION BUDGET:'),
    @('optimization_views', 'release-balanced', 'FENGHUO_OPTIMIZATION_OUTPUT', 'OPTIMIZATION VIEWS: PASS', '1'),
    @('optimization_views', 'release-high', 'FENGHUO_OPTIMIZATION_OUTPUT', 'OPTIMIZATION VIEWS: PASS', '2'),
    @('combat_route', 'release-combat.json', 'FENGHUO_COMBAT_PERFORMANCE_OUTPUT', 'ACTIVE COMBAT ROUTE: PASS')
)
$managed = @('FENGHUO_NAVIGATION_REFERENCE','FENGHUO_NAVIGATION_MASK_OUTPUT','FENGHUO_SURFACE_NO_SHADOW','FENGHUO_OPTIMIZATION_QUALITY') + @($checks | ForEach-Object { $_[2] })
$previous = @{}
foreach ($name in $managed) {
    $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    [Environment]::SetEnvironmentVariable($name, $null, 'Process')
}
Push-Location ([IO.Path]::GetTempPath())
try {
    foreach ($check in $checks) {
        $name = $check[0]
        $destination = Join-Path $output $check[1]
        $logPath = Join-Path $output (($check[1] -replace '\.json$', '') + '.log')
        [Environment]::SetEnvironmentVariable($check[2], $destination, 'Process')
        if ($name -eq 'navigation_budget') {
            $env:FENGHUO_NAVIGATION_REFERENCE = Join-Path $output 'final-source-navigation.json'
        }
        if ($name -eq 'optimization_views') { $env:FENGHUO_OPTIMIZATION_QUALITY = $check[4] }
        $fixture = Join-Path $root "GodotProject/tests/$name.gd"
        & $engine --path ([IO.Path]::GetTempPath()) --main-pack $pack --resolution 1920x1080 --script $fixture -- --qa 2>&1 | Tee-Object -FilePath $logPath
        $exitCode = $LASTEXITCODE
        [Environment]::SetEnvironmentVariable($check[2], $null, 'Process')
        $content = Get-Content -LiteralPath $logPath -Raw
        if ($exitCode -ne 0 -or $content -notmatch [regex]::Escape($check[3]) -or $content -match '(?m)^(SCRIPT ERROR|ERROR|FAIL):') {
            throw "Rendered package check failed: $name ($exitCode)"
        }
    }
} finally {
    Pop-Location
    foreach ($name in $managed) { [Environment]::SetEnvironmentVariable($name, $previous[$name], 'Process') }
}
Write-Output 'Eight rendered package checks completed at native 1080p, without fixed simulation speed.'

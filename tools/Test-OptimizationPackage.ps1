param(
    [string]$OutputDirectory = 'docs/validation/optimization-20261016/final-release',
    [string]$StartAt = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$engine = & (Join-Path $PSScriptRoot 'Find-Godot.ps1')
$pack = Join-Path $root 'Release/FenghuoEcho.pck'
$output = Join-Path $root $OutputDirectory
New-Item -ItemType Directory -Path $output -Force | Out-Null
$checks = @(
    @('smoke','SMOKE RESULT:', ''),
    @('linear_route','LINEAR ROUTE RESULT:', ''),
    @('visual_motion','VISUAL MOTION RESULT:', ''),
    @('courtyard_controls','COURTYARD CONTROLS: PASS', 'FENGHUO_COURTYARD_EVIDENCE'),
    @('river_journey','RIVER JOURNEY: PASS', 'FENGHUO_RIVER_EVIDENCE'),
    @('first_level_rebuild','FIRST LEVEL REBUILD: PASS', 'FENGHUO_EXPANSION_EVIDENCE'),
    @('settlement_revision','SETTLEMENT REVISION: PASS', 'FENGHUO_EXPANSION_EVIDENCE'),
    @('user_expansion','USER EXPANSION: PASS', 'FENGHUO_EXPANSION_EVIDENCE'),
    @('surface_loading','SURFACE LOADING: PASS', 'FENGHUO_SURFACE_LOADING_OUTPUT')
)
if ($StartAt -and $StartAt -notin @($checks | ForEach-Object { $_[0] })) { throw "Unknown package check: $StartAt" }
$started = -not $StartAt
Push-Location ([IO.Path]::GetTempPath())
try {
    foreach ($check in $checks) {
        $name = $check[0]
        if (-not $started -and $name -eq $StartAt) { $started = $true }
        if (-not $started) { continue }
        $logPath = Join-Path $output "$name.log"
        $previous = if ($check[2]) { [Environment]::GetEnvironmentVariable($check[2], 'Process') }
        try {
            if ($check[2]) {
                $evidence = Join-Path $output $name
                New-Item -ItemType Directory -Path $evidence -Force | Out-Null
                [Environment]::SetEnvironmentVariable($check[2], $evidence, 'Process')
            }
            $fixture = Join-Path $root "GodotProject/tests/$name.gd"
            & $engine --headless --path ([IO.Path]::GetTempPath()) --main-pack $pack --fixed-fps 60 --script $fixture -- --qa 2>&1 | Tee-Object -FilePath $logPath
            $exitCode = $LASTEXITCODE
            $content = Get-Content -LiteralPath $logPath -Raw
            if ($exitCode -ne 0 -or $content -notmatch [regex]::Escape($check[1]) -or $content -match '(?m)^(SCRIPT ERROR|ERROR|FAIL):') { throw "Package check failed: $name ($exitCode)" }
        } finally {
            if ($check[2]) { [Environment]::SetEnvironmentVariable($check[2], $previous, 'Process') }
        }
    }
} finally { Pop-Location }
Write-Output 'Nine targeted independent package groups passed, including complete console shutdown output.'

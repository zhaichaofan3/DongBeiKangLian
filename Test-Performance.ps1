param(
    [switch]$Release,
    [string]$Pack,
    [ValidateSet('performance', 'balanced', 'quality')][string]$Quality = 'balanced',
    [ValidatePattern('^\d+x\d+$')][string]$Resolution = '1920x1080',
    [ValidatePattern('^[a-zA-Z0-9_-]+$')][string]$Label = 'current'
)
$ErrorActionPreference = 'Stop'
$project = Join-Path $PSScriptRoot 'GodotProject'
$engine = & (Join-Path $PSScriptRoot 'tools\Find-Godot.ps1')
$reportDir = Join-Path $PSScriptRoot 'docs\performance'
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
$report = Join-Path $reportDir "$Label-$Quality-$Resolution.json"
$log = Join-Path $project "benchmark-$Label-$Quality.log"
$engineArgs = @('--path', $project)
$workingDir = $project
if ($Release -or $Pack) {
    $workingDir = [IO.Path]::GetTempPath()
    $engineArgs = @()
    if ($Pack) {
        $resolvedPack = (Resolve-Path -LiteralPath $Pack).Path
        $engineArgs += @('--main-pack', $resolvedPack)
    } else {
        $engine = Join-Path $PSScriptRoot 'Release\FenghuoEcho.exe'
    }
}
$engineArgs += @('--resolution', $Resolution, '--disable-vsync', '--log-file', $log, '--script', (Join-Path $project 'tests\performance.gd'), '--', '--qa')
$previousOutput = $env:FENGHUO_BENCHMARK_OUTPUT
$previousQuality = $env:FENGHUO_BENCHMARK_QUALITY
try {
    $env:FENGHUO_BENCHMARK_OUTPUT = $report
    $env:FENGHUO_BENCHMARK_QUALITY = @{performance=0;balanced=1;quality=2}[$Quality]
    if (Test-Path -LiteralPath $report) { Remove-Item -LiteralPath $report }
    $quotedArgs = $engineArgs | ForEach-Object { '"' + $_ + '"' }
    $process = Start-Process -FilePath $engine -ArgumentList $quotedArgs -WorkingDirectory $workingDir -WindowStyle Hidden -PassThru
    if (-not $process.WaitForExit(60000)) { $process.Kill(); throw 'Performance capture timed out.' }
    $process.WaitForExit()
    $logText = Get-Content -LiteralPath $log -Raw
    if ($process.ExitCode -ne 0 -or $logText -match '(?m)^(SCRIPT ERROR|ERROR):' -or $logText -notmatch 'PERFORMANCE RESULT: PASS' -or -not (Test-Path -LiteralPath $report)) {
        Write-Output $logText
        throw 'Performance capture failed.'
    }
    (Get-Content -LiteralPath $report -Raw | ConvertFrom-Json).views | Format-Table view,mean_fps,mean_frame_ms,p99_frame_ms,mean_draw_calls
    Write-Output $report
} finally {
    $env:FENGHUO_BENCHMARK_OUTPUT = $previousOutput
    $env:FENGHUO_BENCHMARK_QUALITY = $previousQuality
}

param(
    [switch]$Release,
    [ValidatePattern('^[a-zA-Z0-9_-]+$')][string]$Label = 'v04'
)
$ErrorActionPreference = 'Stop'
$project = Join-Path $PSScriptRoot 'GodotProject'
$reportDir = Join-Path $PSScriptRoot 'docs\performance'
New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
$kind = if ($Release) { 'release' } else { 'source' }
$report = Join-Path $reportDir "$Label-combat-$kind-1920x1080.json"
$log = Join-Path $reportDir "$Label-combat-$kind.log"
$gameArgs = @('--path', $project)
$workingDir = $project
if ($Release) {
    $engine = Join-Path $PSScriptRoot 'Release\FenghuoEcho.exe'
    $gameArgs = @()
    $workingDir = [IO.Path]::GetTempPath()
} else {
    $engine = & (Join-Path $PSScriptRoot 'tools\Find-Godot.ps1')
}
if (-not (Test-Path -LiteralPath $engine -PathType Leaf)) { throw "Game executable not found: $engine" }
$previousOutput = $env:FENGHUO_COMBAT_PERFORMANCE_OUTPUT
$process = $null
try {
    $env:FENGHUO_COMBAT_PERFORMANCE_OUTPUT = $report
    if (Test-Path -LiteralPath $report) { Remove-Item -LiteralPath $report }
    if (Test-Path -LiteralPath $log) { Remove-Item -LiteralPath $log }
    $gameArgs += @('--resolution', '1920x1080', '--windowed', '--disable-vsync', '--log-file', $log, '--script', (Join-Path $project 'tests\combat_route.gd'), '--', '--qa')
    $quotedArgs = $gameArgs | ForEach-Object { '"' + $_ + '"' }
    $process = Start-Process -FilePath $engine -ArgumentList $quotedArgs -WorkingDirectory $workingDir -WindowStyle Hidden -PassThru
    $deadline = [DateTime]::UtcNow.AddSeconds(180)
    while (-not $process.WaitForExit(1000)) {
        if ([DateTime]::UtcNow -gt $deadline) { throw 'Active combat performance run timed out.' }
    }
    $process.WaitForExit()
    $resultText = if (Test-Path -LiteralPath $log) { Get-Content -LiteralPath $log -Raw } else { '' }
    if ($process.ExitCode -ne 0 -or $resultText -match '(?m)^(SCRIPT ERROR|ERROR):' -or $resultText -notmatch 'ACTIVE COMBAT ROUTE: PASS' -or $resultText -notmatch 'COMBAT PERFORMANCE RESULT:' -or -not (Test-Path -LiteralPath $report)) {
        Write-Output $resultText
        throw 'Active combat performance validation failed.'
    }
    $reportText = Get-Content -LiteralPath $report -Raw
    $result = $reportText | ConvertFrom-Json
    if ($result.measurement_valid -ne $true -or $result.route_passed -ne $true -or
        ($result.resolution -join 'x') -ne '1920x1080' -or ($result.window_resolution -join 'x') -ne '1920x1080' -or
        $result.render_scale_3d -ne 1 -or $result.time_scale -ne 1 -or $result.vsync -ne $false -or $result.fps_limit -ne 0 -or
        $result.active_route_frames.frames -lt 30 -or $result.active_route_frames.seconds_sampled -lt 5 -or
        $result.recent_firing_frames.frames -lt 10 -or $result.recent_firing_frames.seconds_sampled -lt 0.5 -or $result.player_shots_observed -lt 1) {
        Write-Output $reportText
        throw 'Active combat performance report failed resolution, runtime settings or sample validation.'
    }
    if ($result.enemy_shots_observed -eq 0 -or $result.two_sided_recent_firing_frames.frames -eq 0) {
        Write-Warning 'This route includes real player firing but no observed two-sided exchange; do not describe it as a sustained enemy firefight.'
    }
    Write-Output $reportText
} finally {
    try {
        if ($null -ne $process) {
            try {
                if (-not $process.HasExited) {
                    $process.Kill()
                    [void]$process.WaitForExit(10000)
                }
            } finally {
                $process.Dispose()
            }
        }
    } finally {
        $env:FENGHUO_COMBAT_PERFORMANCE_OUTPUT = $previousOutput
    }
}

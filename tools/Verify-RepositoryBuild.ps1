$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
$report = Join-Path $workspace 'docs/maintenance/repository-20261016'
$previousEngine = $env:GODOT_EXE
try {
    $env:GODOT_EXE = & (Join-Path $PSScriptRoot 'Find-Godot.ps1')
    & (Join-Path $workspace 'Build-Game.ps1') *> (Join-Path $report 'build.log')
    $log = Join-Path $report 'release-smoke.log'
    $test = Join-Path $workspace 'GodotProject/tests/smoke.gd'
    $arguments = @('--headless', '--fixed-fps', '60', '--script', $test, '--log-file', $log, '--', '--qa') |
        ForEach-Object { '"' + $_ + '"' }
    $process = Start-Process -FilePath (Join-Path $workspace 'Release/FenghuoEcho.exe') -ArgumentList $arguments `
        -WorkingDirectory ([IO.Path]::GetTempPath()) -WindowStyle Hidden -PassThru
    if (-not $process.WaitForExit(120000)) {
        $process.Kill()
        throw 'Release smoke check timed out.'
    }
    $process.WaitForExit()
    $text = Get-Content -LiteralPath $log -Raw
    if ($process.ExitCode -ne 0 -or $text -match '(?m)^(SCRIPT ERROR|ERROR):' -or $text -notmatch 'SMOKE RESULT: 108/108 passed') {
        throw 'Release smoke check failed; inspect release-smoke.log.'
    }
    Write-Output 'Portable build and independent release smoke check passed (108/108).'
} finally {
    $env:GODOT_EXE = $previousEngine
}

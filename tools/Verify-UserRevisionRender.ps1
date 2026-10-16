param([switch]$Release)
$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $workspaceRoot 'GodotProject'
$evidenceRoot = Join-Path $workspaceRoot 'docs\user-revision-20261015'
$engine = if ($Release) { Join-Path $workspaceRoot 'Release\FenghuoEcho.exe' } else { & (Join-Path $PSScriptRoot 'Find-Godot.ps1') }
$workingDirectory = if ($Release) { [IO.Path]::GetTempPath() } else { $workspaceRoot }
$oldEvidence = $env:FENGHUO_REVISION_EVIDENCE
try {
    foreach ($width in @(1280, 960)) {
        $height = if ($width -eq 1280) { 720 } else { 540 }
        $name = if ($Release) { "release-render-$width" } else { "render-$width" }
        $env:FENGHUO_REVISION_EVIDENCE = Join-Path $evidenceRoot $name
        $log = Join-Path $evidenceRoot "$name.log"
        $arguments = @('--fixed-fps', '60', '--resolution', "${width}x${height}", '--log-file', $log, '--script', (Join-Path $projectPath 'tests\user_revision_20261015.gd'), '--', '--qa')
        if (-not $Release) { $arguments = @('--path', $projectPath) + $arguments }
        $quoted = $arguments | ForEach-Object { '"' + $_ + '"' }
        $process = Start-Process -FilePath $engine -ArgumentList $quoted -WorkingDirectory $workingDirectory -WindowStyle Hidden -PassThru
        if (-not $process.WaitForExit(60000)) { $process.Kill(); throw "Render timeout: $name" }
        $process.WaitForExit()
        $content = Get-Content -LiteralPath $log -Raw
        if ($process.ExitCode -ne 0 -or $content -match '(?m)^(ERROR:|SCRIPT ERROR:|FAIL:)' -or $content -notmatch 'USER REVISION: PASS') { throw "Render failed: $log" }
        Write-Output "$name verified"
    }
} finally {
    $env:FENGHUO_REVISION_EVIDENCE = $oldEvidence
}

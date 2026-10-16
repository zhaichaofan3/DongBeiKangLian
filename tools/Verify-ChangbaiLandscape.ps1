param([switch]$Release, [switch]$Headless)
$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $workspaceRoot 'GodotProject'
$evidenceRoot = Join-Path $workspaceRoot 'docs\level\S23\changbai-20261015'
$engine = if ($Release) { Join-Path $workspaceRoot 'Release\FenghuoEcho.exe' } else { & (Join-Path $PSScriptRoot 'Find-Godot.ps1') }
$workingDirectory = if ($Release) { [IO.Path]::GetTempPath() } else { $workspaceRoot }
$oldEvidence = $env:FENGHUO_CHANGBAI_EVIDENCE
try {
    foreach ($width in $(if ($Headless) { @(1280) } else { @(1280, 960) })) {
        $height = if ($width -eq 1280) { 720 } else { 540 }
        $name = $(if ($Release) { 'release' } else { 'source' }) + $(if ($Headless) { '-headless' } else { "-render-$width" })
        $env:FENGHUO_CHANGBAI_EVIDENCE = Join-Path $evidenceRoot $name
        New-Item -ItemType Directory -Path $env:FENGHUO_CHANGBAI_EVIDENCE -Force | Out-Null
        $log = Join-Path $evidenceRoot "$name.log"
        $arguments = @('--resolution', "${width}x${height}", '--log-file', $log, '--script', (Join-Path $projectPath 'tests\changbai_landscape.gd'), '--', '--qa')
        if ($Headless) { $arguments = @('--headless') + $arguments }
        if (-not $Release) { $arguments = @('--path', $projectPath) + $arguments }
        $quoted = $arguments | ForEach-Object { '"' + $_ + '"' }
        $process = Start-Process -FilePath $engine -ArgumentList $quoted -WorkingDirectory $workingDirectory -WindowStyle Hidden -PassThru
        if (-not $process.WaitForExit(60000)) { $process.Kill(); throw "Validation timeout: $name" }
        $process.WaitForExit()
        $content = Get-Content -LiteralPath $log -Raw
        if ($process.ExitCode -ne 0 -or $content -match '(?m)^(ERROR:|SCRIPT ERROR:|FAIL:)' -or $content -notmatch 'CHANGBAI LANDSCAPE: PASS') { throw "Validation failed: $log" }
        Write-Output "$name verified"
    }
} finally {
    $env:FENGHUO_CHANGBAI_EVIDENCE = $oldEvidence
}

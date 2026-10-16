param([switch]$Release, [switch]$Headless, [string]$EvidenceRoot = '')
$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $workspaceRoot 'GodotProject'
$engine = if ($Release) { Join-Path $workspaceRoot 'Release\FenghuoEcho.exe' } else { & (Join-Path $PSScriptRoot 'Find-Godot.ps1') }
$previous = $env:FENGHUO_POLISH_EVIDENCE
if (-not $EvidenceRoot) { $EvidenceRoot = Join-Path $workspaceRoot 'docs\user-polish-20261015' }
try {
    foreach ($width in $(if ($Headless) { @(1280) } else { @(1280,960) })) {
        $height = if ($width -eq 1280) { 720 } else { 540 }
        $name = $(if ($Release) { 'release' } else { 'source' }) + $(if ($Headless) { '-headless' } else { "-render-$width" })
        $env:FENGHUO_POLISH_EVIDENCE = Join-Path $EvidenceRoot $name
        New-Item -ItemType Directory -Path $env:FENGHUO_POLISH_EVIDENCE -Force | Out-Null
        $log = Join-Path $env:FENGHUO_POLISH_EVIDENCE 'run.log'
        $arguments = @('--resolution', "${width}x${height}", '--fixed-fps', '60', '--log-file', $log, '--script', (Join-Path $projectPath 'tests\polish_revision.gd'), '--', '--qa')
        if ($Headless) { $arguments = @('--headless') + $arguments }
        if (-not $Release) { $arguments = @('--path', $projectPath) + $arguments }
        $quoted = $arguments | ForEach-Object { '"' + $_ + '"' }
        $process = Start-Process -FilePath $engine -ArgumentList $quoted -WorkingDirectory ([IO.Path]::GetTempPath()) -WindowStyle Hidden -PassThru
        if (-not $process.WaitForExit(60000)) { $process.Kill(); throw "Validation timeout: $name" }
        $process.WaitForExit()
        $content = Get-Content -LiteralPath $log -Raw
        if ($process.ExitCode -ne 0 -or $content -match '(?m)^(ERROR:|SCRIPT ERROR:|FAIL:)' -or -not $content.Contains('POLISH REVISION: PASS')) { throw "Validation failed: $log" }
        Write-Output "$name verified"
    }
} finally {
    $env:FENGHUO_POLISH_EVIDENCE = $previous
}

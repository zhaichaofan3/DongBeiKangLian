param(
    [switch]$Capture,
    [switch]$Live,
    [string]$EvidenceDirectory
)
$ErrorActionPreference = 'Stop'
if (-not $EvidenceDirectory) {
    $EvidenceDirectory = Join-Path $PSScriptRoot ('docs\narrative\S07\checks-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
}
$EvidenceDirectory = [IO.Path]::GetFullPath($EvidenceDirectory)
New-Item -ItemType Directory -Force -Path $EvidenceDirectory | Out-Null
$openingEngine = & (Join-Path $PSScriptRoot 'tools\Find-Godot.ps1')
$openingProject = Join-Path $PSScriptRoot 'GodotProject'
$openingLog = Join-Path $EvidenceDirectory 'runtime.log'
if (Test-Path -LiteralPath $openingLog) { throw 'Use a fresh evidence directory; existing logs are preserved.' }
$previousEvidence = $env:FENGHUO_OPENING_EVIDENCE
try {
    $env:FENGHUO_OPENING_EVIDENCE = $EvidenceDirectory
    $openingScript = if ($Live) { 'res://tests/opening_live.gd' } else { 'res://tests/opening.gd' }
    $openingArgs = @('--path', $openingProject, '--fixed-fps', '60', '--resolution', '1280x720', '--script', $openingScript, '--log-file', $openingLog)
    if (-not $Capture) { $openingArgs += '--headless' }
    $openingArgs += @('--', '--qa')
    $quotedArgs = $openingArgs | ForEach-Object { '"' + $_ + '"' }
    $openingProcess = Start-Process -FilePath $openingEngine -ArgumentList $quotedArgs -WorkingDirectory $openingProject -WindowStyle Hidden -PassThru
    # Poll in short windows so a slow rendered run does not block all progress.
    $deadline = [DateTime]::UtcNow.AddSeconds(240)
    while (-not $openingProcess.WaitForExit(1000)) {
        if ([DateTime]::UtcNow -gt $deadline) {
            $openingProcess.Kill()
            throw 'Opening validation timed out; partial evidence remains in the output directory.'
        }
    }
    $openingProcess.WaitForExit()
    $openingText = Get-Content -LiteralPath $openingLog -Raw
    if ($openingProcess.ExitCode -ne 0 -or $openingText -match '(?m)^(SCRIPT ERROR|ERROR):') { throw "Opening check failed: $openingLog" }
    $reportName = if ($Live) { 'live_playback.json' } else { 'runtime_validation.json' }
    $report = Get-Content -Raw (Join-Path $EvidenceDirectory $reportName) | ConvertFrom-Json
    if (-not $report.all_passed) { throw "Opening report failed: $EvidenceDirectory" }
    Write-Output $openingText
    Write-Output "Evidence: $EvidenceDirectory"
} finally {
    $env:FENGHUO_OPENING_EVIDENCE = $previousEvidence
}

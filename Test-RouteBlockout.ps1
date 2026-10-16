param([ValidateSet('direct','full','skip')][string]$Case='direct',[switch]$Capture,[string]$EvidenceDirectory)
$ErrorActionPreference='Stop'
if (-not $EvidenceDirectory) { $EvidenceDirectory=Join-Path $PSScriptRoot ('docs\level\S09\'+$Case+'-'+(Get-Date -Format 'yyyyMMdd-HHmmss')) }
$EvidenceDirectory=[IO.Path]::GetFullPath($EvidenceDirectory)
New-Item -ItemType Directory -Force -Path $EvidenceDirectory | Out-Null
$routeLog=Join-Path $EvidenceDirectory 'runtime.log'
if (Test-Path -LiteralPath $routeLog) { throw 'Use a new evidence directory to preserve previous runs.' }
$routeEngine=& (Join-Path $PSScriptRoot 'tools\Find-Godot.ps1')
$previousEvidence=$env:FENGHUO_S09_EVIDENCE
$previousCase=$env:FENGHUO_S09_CASE
try {
    $env:FENGHUO_S09_EVIDENCE=$EvidenceDirectory
    $env:FENGHUO_S09_CASE=$Case
    $routeArgs=@('--path',(Join-Path $PSScriptRoot 'GodotProject'),'--fixed-fps','60','--resolution','1280x720','--script','res://tests/s09_route.gd','--log-file',$routeLog)
    if (-not $Capture) { $routeArgs+='--headless' }
    $routeArgs+=@('--','--qa')
    $quotedArgs=$routeArgs | ForEach-Object { '"'+$_+'"' }
    $routeProcess=Start-Process -FilePath $routeEngine -ArgumentList $quotedArgs -WindowStyle Hidden -PassThru
    $deadline=[DateTime]::UtcNow.AddSeconds(240)
    while (-not $routeProcess.WaitForExit(1000)) {
        if ([DateTime]::UtcNow -gt $deadline) { $routeProcess.Kill(); throw 'Route test timed out; partial evidence retained.' }
    }
    $routeText=Get-Content -Raw -LiteralPath $routeLog
    Write-Output $routeText
    if ($routeProcess.ExitCode -ne 0 -or $routeText -match '(?m)^(SCRIPT ERROR|ERROR):') { throw "Route test failed: $routeLog" }
    $report=Get-Content -Raw (Join-Path $EvidenceDirectory 'route.json') | ConvertFrom-Json
    if (-not $report.all_passed) { throw 'Route assertions failed.' }
} finally {
    $env:FENGHUO_S09_EVIDENCE=$previousEvidence
    $env:FENGHUO_S09_CASE=$previousCase
}

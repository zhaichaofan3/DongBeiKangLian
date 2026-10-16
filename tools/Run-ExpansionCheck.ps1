param(
    [string]$Test = 'user_expansion',
    [string]$OutputDirectory = 'docs/expansion_20261015/source-initial',
    [switch]$Release,
    [switch]$Render,
    [string]$Resolution = '1280x720',
    [ValidateRange(10,1800)][int]$TimeoutSeconds = 120
)
$ErrorActionPreference = 'Stop'
$workspace = Split-Path -Parent $PSScriptRoot
$evidenceDir = [IO.Path]::GetFullPath((Join-Path $workspace $OutputDirectory))
[IO.Directory]::CreateDirectory($evidenceDir) | Out-Null
$engine = if ($Release) { Join-Path $workspace 'Release/FenghuoEcho.exe' } else { & (Join-Path $PSScriptRoot 'Find-Godot.ps1') }
$gameArgs = @('--fixed-fps','60','--script',(Join-Path $workspace "GodotProject/tests/$Test.gd"),'--log-file',(Join-Path $evidenceDir 'run.log'))
if (-not $Release) { $gameArgs += @('--path',(Join-Path $workspace 'GodotProject')) }
if ($Render) { $gameArgs += @('--resolution',$Resolution) } else { $gameArgs += '--headless' }
$gameArgs += @('--','--qa')
$oldEvidence = $env:FENGHUO_EXPANSION_EVIDENCE
try {
    $env:FENGHUO_EXPANSION_EVIDENCE = $evidenceDir
    $process = Start-Process -FilePath $engine -ArgumentList ($gameArgs | ForEach-Object { '"' + $_ + '"' }) -WorkingDirectory ([IO.Path]::GetTempPath()) -WindowStyle Hidden -PassThru
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill()
        throw "Expansion check timed out: $Test"
    }
    $process.WaitForExit()
    $log = Get-Content -LiteralPath (Join-Path $evidenceDir 'run.log') -Raw
    $log
    if ($process.ExitCode -ne 0 -or $log -match '(?m)^(SCRIPT ERROR|ERROR):') { throw "Expansion check failed: $Test ($($process.ExitCode))" }
} finally {
    $env:FENGHUO_EXPANSION_EVIDENCE = $oldEvidence
}

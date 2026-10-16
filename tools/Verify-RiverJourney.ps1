param([switch]$Release,[switch]$Headless,[string]$EvidenceRoot='docs/river_journey_20261016/source')
$ErrorActionPreference='Stop'
$workspace=Split-Path -Parent $PSScriptRoot
$project=Join-Path $workspace 'GodotProject'
$evidence=[IO.Path]::GetFullPath((Join-Path $workspace $EvidenceRoot))
New-Item -ItemType Directory -Path $evidence -Force|Out-Null
$engine=if($Release){Join-Path $workspace 'Release/FenghuoEcho.exe'}else{& (Join-Path $PSScriptRoot 'Find-Godot.ps1')}
$gameArgs=if($Release){@()}else{@('--path',$project)}
if($Headless){$gameArgs+='--headless'}else{$gameArgs+=@('--resolution','1280x720')}
$gameArgs+=@('--fixed-fps','60','--log-file',(Join-Path $evidence 'run.log'),'--script',(Join-Path $project 'tests/river_journey.gd'),'--','--qa')
$previous=$env:FENGHUO_RIVER_EVIDENCE
try{
    $env:FENGHUO_RIVER_EVIDENCE=$evidence
    $arguments=$gameArgs|ForEach-Object{'"'+$_+'"'}
    $process=Start-Process -FilePath $engine -ArgumentList $arguments -WorkingDirectory ([IO.Path]::GetTempPath()) -WindowStyle Hidden -PassThru
    if(-not $process.WaitForExit(240000)){$process.Kill();throw 'River journey validation timed out.'}
    $process.WaitForExit()
    $log=Get-Content (Join-Path $evidence 'run.log') -Raw
    if($process.ExitCode -ne 0 -or $log -match '(?m)^(SCRIPT ERROR|ERROR):' -or $log -notmatch 'RIVER JOURNEY: PASS'){Write-Output $log;throw 'River journey validation failed.'}
    Get-Content (Join-Path $evidence 'validation.json') -Raw
}finally{$env:FENGHUO_RIVER_EVIDENCE=$previous}

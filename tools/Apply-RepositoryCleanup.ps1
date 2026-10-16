param([Parameter(Mandatory=$true)][string]$PlanPath)
$ErrorActionPreference='Stop'
$workspace=[IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot)).TrimEnd('\')
$plan=Get-Content -LiteralPath $PlanPath -Raw | ConvertFrom-Json
$logPath=Join-Path $workspace 'docs/maintenance/repository-20261016/deletions.jsonl'
foreach($entry in $plan.items){
    $target=[IO.Path]::GetFullPath((Join-Path $workspace $entry.path))
    if(-not $target.StartsWith($workspace+'\',[StringComparison]::OrdinalIgnoreCase)){
        throw "Cleanup target leaves the workspace: $target"
    }
    if($entry.path -match '(^|[\\/])\.\.([\\/]|$)' -or $entry.path -match '^GodotProject[\\/]assets'){
        throw "Protected cleanup target: $target"
    }
    if(-not(Test-Path -LiteralPath $target)){continue}
    $item=Get-Item -LiteralPath $target -Force
    if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw "Unexpected link target: $target"}
    if($item.PSIsContainer){Remove-Item -LiteralPath $target -Recurse -Force}else{Remove-Item -LiteralPath $target -Force}
    if(Test-Path -LiteralPath $target){throw "Cleanup did not remove: $target"}
    [ordered]@{time=[DateTimeOffset]::Now.ToString('o');path=$entry.path;bytes=$entry.bytes;reason=$entry.reason;removed=$true} |
        ConvertTo-Json -Compress | Add-Content -LiteralPath $logPath -Encoding utf8
}
Write-Output 'All planned cleanup targets removed; operations recorded.'

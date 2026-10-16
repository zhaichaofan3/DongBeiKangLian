param([switch]$Editor)
$ErrorActionPreference = 'Stop'
$engine = & (Join-Path $PSScriptRoot 'tools\Find-Godot.ps1')
$project = Join-Path $PSScriptRoot 'GodotProject'
$arguments = @('--path', ('"{0}"' -f $project))
if ($Editor) { $arguments += '--editor' }
Start-Process -FilePath $engine -ArgumentList $arguments -WorkingDirectory $project -WindowStyle Hidden

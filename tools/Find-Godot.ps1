$ErrorActionPreference = 'Stop'
function Confirm-GodotVersion([string]$Path) {
    $version = & $Path --version
    if ($LASTEXITCODE -ne 0 -or $version -notmatch '^4\.7\.2(?:\.|$)') {
        throw 'This project requires Godot 4.7.2. Set GODOT_EXE to that version.'
    }
    return $Path
}
if ($env:GODOT_EXE) {
    if (-not (Test-Path -LiteralPath $env:GODOT_EXE -PathType Leaf)) {
        throw 'GODOT_EXE must point to the Godot 4.7.2 console executable.'
    }
    return Confirm-GodotVersion ([IO.Path]::GetFullPath($env:GODOT_EXE))
}
$localEngine = Join-Path $PSScriptRoot 'Godot-4.7.2\Godot_v4.7.2-stable_win64_console.exe'
if (Test-Path -LiteralPath $localEngine) {
    return Confirm-GodotVersion $localEngine
}
$packageRoot = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages'
foreach ($name in @('godot4_console.exe', 'godot4.exe', 'godot.exe')) {
    $command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { return Confirm-GodotVersion $command.Source }
}
$installed = Get-ChildItem -LiteralPath $packageRoot -Filter '*console.exe' -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like 'Godot_v4.7.2*' } |
    Select-Object -First 1
if ($null -eq $installed) {
    throw 'Godot 4.7.2 was not found. Install the official engine and set GODOT_EXE to its console executable.'
}
return Confirm-GodotVersion $installed.FullName

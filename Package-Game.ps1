param(
    [string]$IsccPath = $env:ISCC_EXE,
    [string]$ChineseLanguage = '',
    [string]$OutputDirectory = 'Release/Distributions'
)

$ErrorActionPreference = 'Stop'
if (-not $IsccPath) {
    $localCompiler = Join-Path $PSScriptRoot 'tools/downloads/InnoSetup/ISCC.exe'
    $command = Get-Command ISCC.exe -ErrorAction SilentlyContinue
    if (Test-Path -LiteralPath $localCompiler) { $IsccPath = $localCompiler }
    elseif ($command) { $IsccPath = $command.Source }
    else { throw 'Install Inno Setup 6, then pass -IsccPath or set ISCC_EXE. See docs/DEVELOPMENT.md.' }
}
if (-not $ChineseLanguage) {
    $ChineseLanguage = Join-Path $PSScriptRoot 'tools/installer/ChineseSimplified.isl'
}
& python (Join-Path $PSScriptRoot 'tools/package_game.py') --iscc $IsccPath --language $ChineseLanguage --output $OutputDirectory
if ($LASTEXITCODE -ne 0) { throw 'Player distribution packaging failed.' }

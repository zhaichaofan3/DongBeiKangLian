param([switch]$Release, [switch]$Headless)
$ErrorActionPreference = 'Stop'
$workspaceRoot = Split-Path -Parent $PSScriptRoot
$projectPath = Join-Path $workspaceRoot 'GodotProject'
$engine = if ($Release) { Join-Path $workspaceRoot 'Release\FenghuoEcho.exe' } else { & (Join-Path $PSScriptRoot 'Find-Godot.ps1') }
$workingDirectory = if ($Release) { [IO.Path]::GetTempPath() } else { $workspaceRoot }
$checks = @(
    @('straight_charge', 'FENGHUO_STRAIGHT_CHARGE_EVIDENCE', 'docs\level\S19\straight-charge-20261015', 'STRAIGHT CHARGE: PASS'),
    @('dialogue_motion', 'FENGHUO_DIALOGUE_MOTION_EVIDENCE', 'docs\level\S24\natural-dialogue-20261015', 'DIALOGUE MOTION: PASS')
)
foreach ($check in $checks) {
    $previous = [Environment]::GetEnvironmentVariable($check[1], 'Process')
    try {
        foreach ($width in $(if ($Headless) { @(1280) } else { @(1280,960) })) {
            $height = if ($width -eq 1280) { 720 } else { 540 }
            $name = $(if ($Release) { 'release' } else { 'source' }) + $(if ($Headless) { '-headless' } else { "-render-$width" })
            $evidence = Join-Path (Join-Path $workspaceRoot $check[2]) $name
            New-Item -ItemType Directory -Path $evidence -Force | Out-Null
            [Environment]::SetEnvironmentVariable($check[1], $evidence, 'Process')
            $log = Join-Path $evidence 'run.log'
            $arguments = @('--resolution', "${width}x${height}", '--fixed-fps', '60', '--log-file', $log, '--script', (Join-Path $projectPath "tests\$($check[0]).gd"), '--', '--qa')
            if ($Headless) { $arguments = @('--headless') + $arguments }
            if (-not $Release) { $arguments = @('--path', $projectPath) + $arguments }
            $quoted = $arguments | ForEach-Object { '"' + $_ + '"' }
            $process = Start-Process -FilePath $engine -ArgumentList $quoted -WorkingDirectory $workingDirectory -WindowStyle Hidden -PassThru
            if (-not $process.WaitForExit(60000)) { $process.Kill(); throw "Validation timeout: $name $($check[0])" }
            $process.WaitForExit()
            $content = Get-Content -LiteralPath $log -Raw
            if ($process.ExitCode -ne 0 -or $content -match '(?m)^(ERROR:|SCRIPT ERROR:|FAIL:)' -or -not $content.Contains($check[3])) { throw "Validation failed: $log" }
            Write-Output "$name $($check[0]) verified"
        }
    } finally {
        [Environment]::SetEnvironmentVariable($check[1], $previous, 'Process')
    }
}

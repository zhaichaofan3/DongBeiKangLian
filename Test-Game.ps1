param(
    [switch]$Release,
    [switch]$Capture,
    [string]$OutputDirectory = '',
    [switch]$OnlyOpeningChecks,
    [string]$StartAt = ''
)

$ErrorActionPreference = 'Stop'
$project = Join-Path $PSScriptRoot 'GodotProject'
$releaseDir = Join-Path $PSScriptRoot 'Release'
$logDir = Join-Path $PSScriptRoot 'docs\validation\source'
$baseArgs = @('--path', $project)
$workingDir = $project
if ($Release) {
    $engine = Join-Path $releaseDir 'FenghuoEcho.exe'
    $pack = Join-Path $releaseDir 'FenghuoEcho.pck'
    if (-not (Test-Path -LiteralPath $engine) -or -not (Test-Path -LiteralPath $pack)) {
        throw 'Run Build-Game.ps1 before testing the release.'
    }
    # Launch outside the source project. res:// must resolve to the shipped pack.
    $baseArgs = @()
    $workingDir = [IO.Path]::GetTempPath()
    $logDir = Join-Path $PSScriptRoot 'docs\validation\release'
} else {
    $engine = & (Join-Path $PSScriptRoot 'tools\Find-Godot.ps1')
}

if ($OutputDirectory) { $logDir = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot $OutputDirectory)) }
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

function Invoke-GameCheck {
    param([string[]]$GameArgs, [string]$LogPath, [int]$TimeoutSeconds = 120)
    if (Test-Path -LiteralPath $LogPath) { Remove-Item -LiteralPath $LogPath }
    $quotedArgs = (@('--log-file', $LogPath) + $GameArgs) | ForEach-Object { '"' + $_ + '"' }
    $process = Start-Process -FilePath $engine -ArgumentList $quotedArgs -WorkingDirectory $workingDir -WindowStyle Hidden -PassThru
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill()
        throw "Game validation timed out. See $LogPath"
    }
    $process.WaitForExit()
    $log = if (Test-Path -LiteralPath $LogPath) { Get-Content -LiteralPath $LogPath -Raw } else { '' }
    Write-Output $log
    if ($process.ExitCode -ne 0 -or $log -match '(?m)^(SCRIPT ERROR|ERROR):') {
        throw "Game validation failed (exit $($process.ExitCode)). See $LogPath"
    }
}

if (-not $OnlyOpeningChecks) {
$smokeLog = Join-Path $logDir $(if ($Release) { 'integration.log' } else { 'smoke.log' })
# Arguments after the separator belong to the game, not Godot.
Invoke-GameCheck -GameArgs ($baseArgs + @('--headless', '--fixed-fps', '60', '--script', (Join-Path $project 'tests\smoke.gd'), '--', '--qa')) -LogPath $smokeLog
if (-not (Select-String -LiteralPath $smokeLog -Pattern 'SMOKE RESULT: ([1-9][0-9]*)/\1 passed' -Quiet)) {
    throw 'Smoke test completion marker missing.'
}
$combatLog = Join-Path $logDir 'combat-route.log'
$linearLog = Join-Path $logDir 'linear-route.log'
Invoke-GameCheck -GameArgs ($baseArgs + @('--headless', '--fixed-fps', '60', '--script', (Join-Path $project 'tests\linear_route.gd'), '--', '--qa')) -LogPath $linearLog
if (-not (Select-String -LiteralPath $linearLog -Pattern 'LINEAR ROUTE RESULT: ([1-9][0-9]*)/\1 passed' -Quiet)) {
    throw 'Linear route test completion marker missing.'
}
Invoke-GameCheck -GameArgs ($baseArgs + @('--headless', '--fixed-fps', '60', '--script', (Join-Path $project 'tests\combat_route.gd'), '--', '--qa')) -LogPath $combatLog -TimeoutSeconds 600
if (-not (Select-String -LiteralPath $combatLog -Pattern 'ACTIVE COMBAT ROUTE: PASS' -Quiet)) {
    throw 'Combat test completion marker missing.'
}
$motionLog = Join-Path $logDir 'visual-motion.log'
Invoke-GameCheck -GameArgs ($baseArgs + @('--headless', '--fixed-fps', '60', '--script', (Join-Path $project 'tests\visual_motion.gd'), '--', '--qa')) -LogPath $motionLog
if (-not (Select-String -LiteralPath $motionLog -Pattern 'VISUAL MOTION RESULT: ([1-9][0-9]*)/\1 passed' -Quiet)) {
    throw 'Visual motion test completion marker missing.'
}
$storyLog = Join-Path $logDir 'story-moments.log'
Invoke-GameCheck -GameArgs ($baseArgs + @('--headless', '--fixed-fps', '60', '--script', (Join-Path $project 'tests\story_moments.gd'), '--', '--qa')) -LogPath $storyLog
if (-not (Select-String -LiteralPath $storyLog -Pattern 'STORY MOMENTS RESULT: ([1-9][0-9]*)/\1 passed' -Quiet)) {
    throw 'Story moment test completion marker missing.'
}
$characterLog = Join-Path $logDir 'character-model.log'
Invoke-GameCheck -GameArgs ($baseArgs + @('--headless', '--fixed-fps', '60', '--script', (Join-Path $project 'tests\character_model.gd'), '--', '--qa')) -LogPath $characterLog
if (-not (Select-String -LiteralPath $characterLog -Pattern 'CHARACTER MODEL RESULT: ([1-9][0-9]*)/\1 passed' -Quiet)) {
    throw 'Character model test completion marker missing.'
}
}

# These controllers live outside the PCK on release runs; all res:// game assets
# still resolve exclusively to the shipped pack, launched outside the project.
$openingChecks = @(
	@('render_quality.gd','FENGHUO_RENDER_QUALITY_EVIDENCE','RENDER QUALITY: PASS'),
	@('courtyard_controls.gd','FENGHUO_COURTYARD_EVIDENCE','COURTYARD CONTROLS: PASS'),
	@('world_revision.gd','FENGHUO_WORLD_EVIDENCE','WORLD REVISION: PASS'),
	@('river_journey.gd','FENGHUO_RIVER_EVIDENCE','RIVER JOURNEY: PASS'),
	@('first_level_rebuild.gd','FENGHUO_EXPANSION_EVIDENCE','FIRST LEVEL REBUILD: PASS'),
	@('settlement_revision.gd','FENGHUO_EXPANSION_EVIDENCE','SETTLEMENT REVISION: PASS'),
	@('linear_boundaries.gd','FENGHUO_BOUNDARY_EVIDENCE','LINEAR BOUNDARIES: PASS'),
    @('user_expansion.gd','FENGHUO_EXPANSION_EVIDENCE','USER EXPANSION: PASS'),
    @('polish_revision.gd','FENGHUO_POLISH_EVIDENCE','POLISH REVISION: PASS'),
    @('straight_charge.gd','FENGHUO_STRAIGHT_CHARGE_EVIDENCE','STRAIGHT CHARGE: PASS'),
    @('dialogue_motion.gd','FENGHUO_DIALOGUE_MOTION_EVIDENCE','DIALOGUE MOTION: PASS'),
    @('user_revision_20261015.gd','FENGHUO_REVISION_EVIDENCE','USER REVISION: PASS'),
    @('audio_settings.gd','FENGHUO_AUDIO_SETTINGS_EVIDENCE','AUDIO SETTINGS: PASS'),
    @('user_sfx_20261015.gd','FENGHUO_SFX_EVIDENCE','USER SFX RESULT: PASS'),
    @('bayonet_encounter.gd','FENGHUO_BAYONET_EVIDENCE','BAYONET ENCOUNTER: PASS'),
    @('user_audio_20261015.gd','FENGHUO_USER_AUDIO_EVIDENCE','USER AUDIO: PASS'),
    @('s30_audio_mix.gd','FENGHUO_S30_EVIDENCE','S30 AUDIO MIX: PASS'),
    @('changbai_landscape.gd','FENGHUO_CHANGBAI_EVIDENCE','CHANGBAI LANDSCAPE: PASS'),
    @('s22_tianchi_access.gd','FENGHUO_S22_EVIDENCE','S22 TIANCHI ACCESS: PASS'),
    @('s25_handoff.gd','FENGHUO_S25_EVIDENCE','S25 HANDOFF: PASS'),
    @('s31_voice_integration.gd','FENGHUO_S31_EVIDENCE','S31 VOICE INTEGRATION: PASS'),
    @('s32_history_formal.gd','FENGHUO_S32_EVIDENCE','S32 HISTORY FORMAL: PASS'),
    @('s33_task_formal.gd','FENGHUO_S33_EVIDENCE','S33 TASK FORMAL: PASS'),
    @('s34_state_matrix.gd','FENGHUO_S34_EVIDENCE','S34 STATE MATRIX: PASS'),
    @('opening.gd','FENGHUO_OPENING_EVIDENCE','OPENING RESULT: 41/41 passed'),
    @('s36_departure_review.gd','FENGHUO_DEPARTURE_EVIDENCE','S36 DEPARTURE: PASS')
)
if ($StartAt -and $StartAt -notin ($openingChecks | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_[0]) })) { throw "Unknown check: $StartAt" }
$startReached = -not $StartAt
foreach ($check in $openingChecks) {
    $checkName = [IO.Path]::GetFileNameWithoutExtension($check[0])
    if (-not $startReached) {
        if ($checkName -ne $StartAt) { continue }
        $startReached = $true
    }
    $evidenceDir = Join-Path $logDir "opening-checks\$checkName"
    New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null
    $oldEvidence = [Environment]::GetEnvironmentVariable($check[1], 'Process')
    try {
        [Environment]::SetEnvironmentVariable($check[1], $evidenceDir, 'Process')
        $checkLog = Join-Path $evidenceDir 'run.log'
        Invoke-GameCheck -GameArgs ($baseArgs + @('--headless','--fixed-fps','60','--script',(Join-Path $project "tests\$($check[0])"),'--','--qa')) -LogPath $checkLog
        if (-not (Select-String -LiteralPath $checkLog -Pattern $check[2] -SimpleMatch -Quiet)) {
            throw "Opening validation completion marker missing: $checkName"
        }
    } finally {
        [Environment]::SetEnvironmentVariable($check[1], $oldEvidence, 'Process')
    }
}

if ($Capture) {
    $previousCaptureDir = $env:FENGHUO_CAPTURE_DIR
    try {
        foreach ($resolution in @('1280x720', '960x540')) {
            $env:FENGHUO_CAPTURE_DIR = Join-Path $logDir "verification-captures\$resolution"
            New-Item -ItemType Directory -Path $env:FENGHUO_CAPTURE_DIR -Force | Out-Null
            $names = @('title', 'settings', 'conversation', 'yard', 'office', 'rescue', 'journal', 'river')
            foreach ($name in $names) {
                $imagePath = Join-Path $env:FENGHUO_CAPTURE_DIR "$name.png"
                if (Test-Path -LiteralPath $imagePath) { Remove-Item -LiteralPath $imagePath }
            }
            Invoke-GameCheck -GameArgs ($baseArgs + @('--resolution', $resolution, '--', '--capture', '--qa')) -LogPath (Join-Path $logDir "render-$resolution.log")
            foreach ($name in $names) {
                $imagePath = Join-Path $env:FENGHUO_CAPTURE_DIR "$name.png"
                if (-not (Test-Path -LiteralPath $imagePath) -or (Get-Item -LiteralPath $imagePath).Length -eq 0) {
                    throw "Capture missing: $imagePath"
                }
            }
        }
    } finally {
        $env:FENGHUO_CAPTURE_DIR = $previousCaptureDir
    }
    $previousCharacterDir = $env:FENGHUO_CHARACTER_CAPTURE_DIR
    try {
        $env:FENGHUO_CHARACTER_CAPTURE_DIR = Join-Path $logDir 'character-captures'
        New-Item -ItemType Directory -Path $env:FENGHUO_CHARACTER_CAPTURE_DIR -Force | Out-Null
        Invoke-GameCheck -GameArgs ($baseArgs + @('--resolution', '1280x720', '--fixed-fps', '60', '--script', (Join-Path $project 'tests\character_model.gd'), '--', '--qa')) -LogPath (Join-Path $logDir 'character-render.log')
        if (-not (Select-String -LiteralPath (Join-Path $logDir 'character-render.log') -Pattern 'CHARACTER MODEL RESULT: ([1-9][0-9]*)/\1 passed' -Quiet)) {
            throw 'Character capture completion marker missing.'
        }
    } finally {
        $env:FENGHUO_CHARACTER_CAPTURE_DIR = $previousCharacterDir
    }
}

Write-Output $(if ($OnlyOpeningChecks -or $StartAt) { 'Selected game checks passed.' } else { 'All game checks passed.' })

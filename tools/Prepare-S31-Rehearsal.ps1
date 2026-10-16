param([int]$Limit = 0)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root 'AssetLibrary\audio\S31_20261015'
$raw = Join-Path $out 'raw'
New-Item -ItemType Directory -Force -Path $raw | Out-Null
Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$data = Get-Content (Join-Path $root 'GodotProject\assets\opening\opening.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$available = @($synth.GetInstalledVoices() | Where-Object Enabled | ForEach-Object { $_.VoiceInfo.Name })
if ('Microsoft Kangkang' -notin $available) { throw 'Required local Chinese rehearsal voice is unavailable; no substitute is silently selected.' }
$records = @()
$format = New-Object System.Speech.AudioFormat.SpeechAudioFormatInfo(48000, [System.Speech.AudioFormat.AudioBitsPerSample]::Sixteen, [System.Speech.AudioFormat.AudioChannel]::Mono)
try {
    foreach ($part in @('A','B')) {
        foreach ($cue in $data.cues.$part) {
            if ($Limit -gt 0 -and $records.Count -ge $Limit) { break }
            $rate = if ($part -eq 'A') { -1 } elseif ($cue.speaker -eq 'player') { 1 } else { 0 }
            $voiceName = 'Microsoft Kangkang'
            $path = Join-Path $raw ($cue.id + '.wav')
            $metaPath = Join-Path $raw ($cue.id + '.json')
            $expected = [ordered]@{ id=$cue.id; part=$part; text=$cue.text; voice=$voiceName; rate=$rate; volume=100; method='Windows System.Speech offline synthesis'; status='temporary_rehearsal_not_final_voice'; pronunciation_review='pending' }
            if (Test-Path -LiteralPath $path) {
                if (-not (Test-Path -LiteralPath $metaPath)) { throw "Unrecorded partial audio exists: $path. Preserve it before regeneration." }
                $old = Get-Content -LiteralPath $metaPath -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($old.text -cne $cue.text -or $old.voice -ne $voiceName -or $old.rate -ne $rate) { throw "Existing take differs from request: $path. Use a new take directory." }
            } else {
                $synth.SelectVoice($voiceName)
                $synth.Rate = $rate
                $synth.Volume = 100
                $synth.SetOutputToWaveFile($path,$format)
                $synth.Speak([string]$cue.text)
                $synth.SetOutputToNull()
                $expected | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $metaPath -Encoding UTF8
            }
            $records += $expected
            [ordered]@{ status='temporary_rehearsal_in_progress'; installed_voices=$available; records=$records } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $out 'synthesis.json') -Encoding UTF8
            Write-Output "Prepared $($cue.id) (temporary synthesis)"
        }
    }
} finally {
    $synth.Dispose()
}
$total = $data.cues.A.Count + $data.cues.B.Count
$status = if ($records.Count -eq $total) { 'temporary_rehearsal_generated' } else { 'temporary_rehearsal_in_progress' }
[ordered]@{ status=$status; installed_voices=$available; records=$records } | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $out 'synthesis.json') -Encoding UTF8

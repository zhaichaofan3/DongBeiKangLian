"""Apply the user's later two-take replacement without losing earlier originals."""
import array
import json
import math
from pathlib import Path
import shutil
import subprocess

from integrate_user_dialogue_20261015 import ROOT, GAME, OPENING, sha, write

ARCHIVE = ROOT / 'AssetLibrary/audio/dialogue_retake_20261015'
DOC = ROOT / 'docs/audio/dialogue_retake_20261015'
SOURCES = {
    'B5-L06': Path('C:/Users/Administrator/Downloads/绕电报房北侧，到渡⼝。你掩护，他解缆。.mp3'),
    'B6-L01': Path('C:/Users/Administrator/Downloads/先去⽊棚，林师傅能帮你。我守住回⼭的路。.mp3'),
}


def main():
    ARCHIVE.mkdir(parents=True, exist_ok=True)
    DOC.mkdir(parents=True, exist_ok=True)
    opening = json.loads(OPENING.read_text(encoding='utf-8-sig'))
    manifest = json.loads((GAME / 'manifest.json').read_text(encoding='utf-8-sig'))
    records = []
    for cue in opening['cues']['B']:
        if cue['id'] not in SOURCES:
            continue
        source = SOURCES[cue['id']]
        probe = json.loads(subprocess.check_output([
            'ffprobe', '-v', 'error', '-show_entries',
            'format=duration:stream=sample_rate,channels,codec_name', '-of', 'json', str(source)
        ]))
        raw = subprocess.check_output([
            'ffmpeg', '-v', 'error', '-i', str(source), '-f', 's16le', '-ac', '1', '-ar', '24000', '-'
        ])
        samples = array.array('h', raw)
        peak = max(abs(v) for v in samples) / 32768
        rms = math.sqrt(sum(v * v for v in samples) / len(samples)) / 32768
        assert 0.01 < peak < 1 and rms > 0.001, source
        archived = ARCHIVE / f'{cue["id"]}.mp3'
        if archived.exists():
            assert sha(archived) == sha(source), archived
        else:
            shutil.copy2(source, archived)
        prior = dict(manifest['clips'][cue['id']])
        target = GAME / f'{cue["id"]}.mp3'
        shutil.copy2(source, target)
        assert sha(target) == sha(archived) == sha(source)
        duration = float(probe['format']['duration'])
        manifest['clips'][cue['id']].update(sha256=sha(target), duration_seconds=duration,
                                           source_revision='user_later_downloads_replacement')
        cue.update(recorded_duration_ms=math.ceil(duration * 1000),
                   end_ms=max(cue['end_ms'], cue['start_ms'] + math.ceil(duration * 1000)))
        records.append(dict(cue_id=cue['id'], text=cue['text'], source_path=str(source),
            archive=archived.relative_to(ROOT).as_posix(), sha256=sha(source),
            previous_selection=prior, duration_seconds=duration, streams=probe['streams'],
            peak_dbfs=20 * math.log10(peak), rms_dbfs=20 * math.log10(rms),
            decode='complete_pcm_decode_passed', processing='none_exact_mp3_copy'))
    for cue, following in zip(opening['cues']['B'], opening['cues']['B'][1:]):
        assert cue['end_ms'] < following['start_ms'], cue['id']
    write(GAME / 'manifest.json', manifest)
    write(OPENING, opening)
    write(ARCHIVE / 'manifest.json', dict(source='user_later_downloads_replacement', originals=records,
          previous_originals='AssetLibrary/audio/dialogue_20261015/manifest.json'))
    write(DOC / 'import-validation.json', dict(passed=True, active_clips=8, silent_cues=6,
          replacement_count=2, originals=records, runtime_manifest=manifest,
          initial_import='docs/audio/dialogue_20261015/import-validation.json'))
    write(DOC / 'dialogue-timing.json', opening['cues']['B'])
    print(json.dumps(dict(replaced=list(SOURCES), decoded=True, originals_preserved=True)))


if __name__ == '__main__':
    main()

"""Preserve supplied takes and map only recorded dialogue into the opening."""
import array
import hashlib
import json
import math
from pathlib import Path
import shutil
import subprocess
import unicodedata

ROOT = Path(__file__).resolve().parents[1]
MUSIC = Path('C:/Users/Administrator/Music')
ARCHIVE = ROOT / 'AssetLibrary/audio/dialogue_20261015'
GAME = ROOT / 'GodotProject/assets/audio/user_dialogue_20261015'
DOC = ROOT / 'docs/audio/dialogue_20261015'
OPENING = ROOT / 'GodotProject/assets/opening/opening.json'
IDS = ['B1-L01', 'B2-L02', 'B3-L01', 'B5-L01', 'B5-L03', 'B5-L04', 'B5-L06', 'B6-L01']


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def normalized_text(value):
    return unicodedata.normalize('NFKC', value).replace('\u2ed8', '\u9752').rstrip('\u3002.')


def main():
    opening = json.loads(OPENING.read_text(encoding='utf-8-sig'))
    for folder in [ARCHIVE, GAME, DOC]:
        folder.mkdir(parents=True, exist_ok=True)
    originals = []
    clips = {}
    inputs = list(MUSIC.glob('*.mp3'))
    for cue in opening['cues']['B']:
        if cue['id'] not in IDS:
            cue['audio_source'] = None
            cue['voice_status'] = 'silent_pending_recording'
            continue
        takes = []
        for path in inputs:
            if normalized_text(path.stem.removesuffix(' (2)')) == normalized_text(cue['text']):
                takes.append(path)
        assert takes, cue['id']
        chosen = next((p for p in takes if p.stem.endswith(' (2)')), takes[0])
        for index, source in enumerate(sorted(takes), 1):
            probe = json.loads(subprocess.check_output([
                'ffprobe', '-v', 'error', '-show_entries',
                'format=duration:stream=sample_rate,channels,codec_name', '-of', 'json', str(source)
            ]))
            raw = subprocess.check_output([
                'ffmpeg', '-v', 'error', '-i', str(source), '-f', 's16le',
                '-ac', '1', '-ar', '24000', '-'
            ])
            samples = array.array('h', raw)
            peak = max(abs(v) for v in samples) / 32768
            rms = math.sqrt(sum(v * v for v in samples) / len(samples)) / 32768
            assert peak > 0.01 and peak < 1 and rms > 0.001, source
            archived = ARCHIVE / f'{cue["id"]}-take-{index:02}.mp3'
            if archived.exists():
                assert sha(archived) == sha(source), archived
            else:
                shutil.copy2(source, archived)
            record = dict(cue_id=cue['id'], text=cue['text'], source_path=str(source),
                          archive=archived.relative_to(ROOT).as_posix(), sha256=sha(source),
                          duration_seconds=float(probe['format']['duration']),
                          sample_rate=24000, channels=1, peak_dbfs=20 * math.log10(peak),
                          rms_dbfs=20 * math.log10(rms), selected=source == chosen,
                          decode='complete_pcm_decode_passed', processing='none_exact_mp3_copy')
            originals.append(record)
            if source == chosen:
                target = GAME / f'{cue["id"]}.mp3'
                shutil.copy2(source, target)
                assert sha(target) == record['sha256']
                clips[cue['id']] = dict(path='res://' + target.relative_to(ROOT / 'GodotProject').as_posix(),
                                       sha256=record['sha256'], duration_seconds=record['duration_seconds'])
        cue['audio_source'] = clips[cue['id']]['path']
        cue['voice_status'] = 'user_supplied_recording'
        cue['recorded_duration_ms'] = math.ceil(clips[cue['id']]['duration_seconds'] * 1000)
        cue['end_ms'] = max(cue['end_ms'], cue['start_ms'] + cue['recorded_duration_ms'])
    for cue, following in zip(opening['cues']['B'], opening['cues']['B'][1:]):
        assert cue['end_ms'] < following['start_ms'], cue['id']
    assert len(originals) == 9 and len(clips) == 8
    manifest = dict(schema_version=1, source='user_supplied_20261015',
                    missing_dialogue='silent_with_subtitles_no_synthetic_fallback', clips=clips)
    write(GAME / 'manifest.json', manifest)
    write(ARCHIVE / 'manifest.json', dict(originals=originals, runtime_manifest=manifest,
          duplicate_choice='B6-L01 uses the supplied (2) take; both originals preserved'))
    opening['audio_20261015']['task_voice'] = 'eight_user_recordings_missing_lines_silent'
    opening['formal_assets']['task_prologue']['dialogue'] = 'eight_user_recordings_six_silent_subtitle_cues'
    write(OPENING, opening)
    write(DOC / 'import-validation.json', dict(passed=True, original_count=9, active_clips=8,
          silent_cues=[c['id'] for c in opening['cues']['B'] if c['id'] not in clips],
          preserved_timeline_ms=opening['durations_ms'], originals=originals))
    write(DOC / 'dialogue-timing.json', opening['cues']['B'])
    print(json.dumps(dict(originals=9, active_clips=8, silent_cues=6, all_decoded=True)))


if __name__ == '__main__':
    main()

"""One-time authored edit; reads the preserved pre-integration checkpoint, never new state."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / 'WorkBackups/20261015-104907-S32-in_progress-7eb863/files/GodotProject/assets/opening/opening.json'
d = json.loads(BASE.read_text(encoding='utf-8-sig'))
# Preserve original wording; only the supplied recording adds two sentences.
times = [(400,5740),(5740,7740),(7740,11740),(11740,15740),(15740,18740),
         (18740,21740),(21740,23740),(23740,25740),(25740,27740),(27740,32740),
         (32740,35740),(35740,38740),(38740,41740),(41740,46740),(46740,53740)]
for cue, (start, end) in zip(d['cues']['A'], times):
    cue.update(voice_start_ms=start, voice_end_ms=end, subtitle_start_ms=start,
               subtitle_end_ms=end, speech_duration_ms=end-start, pause_after_ms=0,
               audio_source='opening_history_20261015.mp3', timing_method='ASR aligned; listening review pending')
for i, text, lines, start, end in [
    (16, '这一刻，历史与现实交响。', ['这一刻，历史与现实交响。'], 53740,58740),
    (17, '共同把时光瞬间拉回到那个铁血交织的时代。', ['共同把时光瞬间拉回到', '那个铁血交织的时代。'],58740,65740)]:
    d['cues']['A'].append(dict(id=f'N{i:02}',segment='A6',text=text,lines=lines,
        voice_start_ms=start,voice_end_ms=end,subtitle_start_ms=start,subtitle_end_ms=end,
        speech_duration_ms=end-start,pause_after_ms=0,audio_source='opening_history_20261015.mp3',
        timing_method='ASR aligned; listening review pending',source='User-added recording text'))
schedule = [('A-01',0,11740),('A-04',11740,18740),('A-06',18740,21740),
            ('A-07',21740,23740),('A-08',23740,27740),('A-10',27740,32740),
            ('A-11',32740,37740),('A-14',37740,41740),('A-15',41740,46740),('A-16',46740,53740)]
old = {shot['id']:shot for shot in d['shots']}
shots = []
for shot_id, start, end in schedule:
    shot = old[shot_id]
    shot.update(start_ms=start,end_ms=end)
    shots.append(shot)
shots.append(dict(id='A-18',part='A',segment='A6',title='历史与现实 · 林场长镜头',
    start_ms=53740,end_ms=68180,camera_from=[20,15,91],camera_to=[47,17,69],
    look_at=[34,2.5,57],look_at_to=[53,3,39],fov=62,actors=[],
    production_status='integrated_pending_acceptance_s32',
    purpose='新增两句共用14.44秒连续滑动全景，沿已有房屋、木料棚与电报房展示，标题在同镜头叠入。'))
d['shots'] = shots + [s for s in d['shots'] if s['part']=='B']
d['durations_ms'] = dict(A=68180,B=80100,total=148280)
for event in d['events']:
    if event['id']=='A_SUBTITLE_END': event.update(start_ms=65740,end_ms=65740,text='清除新增N17')
    if event['id']=='A_TITLE': event.update(start_ms=65740,end_ms=68180)
d['audio_20261015'] = dict(history='res://assets/audio/opening_history_20261015.mp3',
    global_music='res://assets/audio/global_war_music.ogg',history_contains_music=True,
    history_duration_seconds=68.179625,global_music_during_history=False,
    history_voice='user_supplied_full_mix',task_voice='temporary_synthetic',listening='pending')
d['formal_assets']['history']['voice']='user_supplied_full_mix_20261015'
d['formal_assets']['history']['music']='embedded_in_history_global_suppressed'
d['formal_assets']['task_prologue']['music']='user_global_20261015'
(ROOT/'GodotProject/assets/opening/opening.json').write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
out=ROOT/'docs/audio/user_20261015'
out.mkdir(parents=True,exist_ok=True)
(out/'timeline.json').write_text(json.dumps(dict(durations_ms=d['durations_ms'],cues=d['cues']['A'],shots=shots),ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def stamp(ms):
    s,m=divmod(ms,1000); minutes,s=divmod(s,60)
    return f'00:{minutes:02}:{s:02},{m:03}'
(out/'history.srt').write_text('\n\n'.join(f"{i}\n{stamp(c['subtitle_start_ms'])} --> {stamp(c['subtitle_end_ms'])}\n"+'\n'.join(c['lines']) for i,c in enumerate(d['cues']['A'],1))+'\n',encoding='utf-8')
print('History: 11 shots, 17 cues, 68.18 seconds; B unchanged.')

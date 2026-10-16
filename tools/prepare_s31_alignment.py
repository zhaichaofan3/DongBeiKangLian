"""Measure temporary SAPI takes and export non-destructive timing proposals."""
from pathlib import Path
import hashlib
import html
import json
import math
import subprocess
import wave
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'AssetLibrary/audio/S31_20261015'
DOC=ROOT/'docs/audio/S31'
RATE=48000


def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def write(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')


def decode(path):
    p=subprocess.run(['ffmpeg','-nostdin','-v','error','-i',str(path),'-ar',str(RATE),'-ac','1','-f','f32le','-'],capture_output=True,check=True)
    return np.frombuffer(p.stdout,dtype='<f4').astype(np.float64)


def wav(path,a):
    path.parent.mkdir(parents=True,exist_ok=True)
    assert np.isfinite(a).all() and np.abs(a).max()<1
    with wave.open(str(path),'wb') as w:
        w.setnchannels(1);w.setframerate(RATE);w.setsampwidth(2);w.writeframes(np.rint(a*32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg','-nostdin','-v','error','-i',str(path),'-f','null','-'],capture_output=True,check=True)
    return dict(path=path.relative_to(ROOT).as_posix(),sha256=sha(path),duration_ms=round(len(a)*1000/RATE),decode_ok=True,
                peak_dbfs=round(float(20*np.log10(max(np.abs(a).max(),1e-12))),2))


def stamp(ms,sep=','):
    seconds,milli=divmod(round(ms),1000);minutes,seconds=divmod(seconds,60);hours,minutes=divmod(minutes,60)
    return f'{hours:02}:{minutes:02}:{seconds:02}{sep}{milli:03}'


def main():
    opening=read(ROOT/'GodotProject/assets/opening/opening.json')
    definitions=read(OUT/'synthesis.json')['records']
    assert len(definitions)==29
    original=(ROOT/'docs/narrative/S04/narration_original.txt').read_text(encoding='utf-8-sig').strip()
    assert ''.join(c['text'] for c in opening['cues']['A'])==original
    canonical=hashlib.sha256(original.encode('utf-8')).hexdigest()
    assert canonical==read(ROOT/'docs/narrative/S04/narration_timeline.json')['canonical_sha256']
    records=[];parts={};timeline={};audio_data={}
    names={'narrator':'旁白','player':'沈砚','scout':'姜岚'}
    for part in ['A','B']:
        shift=0;adjusted=[]
        for cue in opening['cues'][part]:
            meta=next(x for x in definitions if x['id']==cue['id'])
            assert meta['text']==cue['text']
            raw=OUT/'raw'/(cue['id']+'.wav');a=decode(raw)
            # Remove only leading/trailing digital silence, keeping 40/100ms handles.
            active=np.flatnonzero(np.abs(a)>10**(-60/20))
            assert len(active)>0
            lo=max(0,int(active[0])-round(.04*RATE));hi=min(len(a),int(active[-1])+round(.1*RATE)+1)
            b=a[lo:hi].copy();n=min(144,len(b)//4)
            b[:n]*=np.linspace(0,1,n);b[-n:]*=np.linspace(1,0,n)
            gain=min(10**(-20/20)/max(np.sqrt(np.mean(b*b)),1e-12),10**(-6/20)/max(np.abs(b).max(),1e-12));b*=gain
            output=wav(OUT/'samples'/(cue['id']+'.wav'),b)
            start=int(cue['voice_start_ms'] if part=='A' else cue['start_ms'])
            end=int(cue['voice_end_ms'] if part=='A' else cue['end_ms'])
            duration=math.ceil(len(b)*1000/RATE)
            extra=max(0,duration+100-(end-start))
            speaker=cue.get('speaker','narrator')
            rec=dict(id=cue['id'],part=part,segment=cue['segment'],speaker=speaker,speaker_name=names[speaker],text=cue['text'],
                     voice=meta['voice'],rate=meta['rate'],raw_path=raw.relative_to(ROOT).as_posix(),raw_sha256=sha(raw),
                     raw_duration_ms=round(len(a)*1000/RATE),crop_start_ms=round(lo*1000/RATE,3),crop_end_ms=round(hi*1000/RATE,3),
                     gain=float(gain),edits='只裁首尾近静音，3ms边缘淡化，RMS目标-20dBFS且峰值<=-6dBFS；未加速或改写',
                     original_start_ms=start,original_end_ms=end,proposed_start_ms=start+shift,
                     proposed_voice_end_ms=start+shift+duration,required_extra_ms=extra,
                     subtitle_end_ms=start+shift+max(end-start,duration+100),audio=output,
                     status='temporary_synthetic_rehearsal',pronunciation_and_acting_review='pending',runtime_integrated=False)
            shift+=extra
            adjusted.append(rec);records.append(rec);audio_data[cue['id']]=b
        total=opening['durations_ms'][part]+shift
        mix=np.zeros(round(total*RATE/1000))
        for rec in adjusted:
            b=audio_data[rec['id']];offset=round(rec['proposed_start_ms']*RATE/1000)
            assert offset+len(b)<=len(mix)
            mix[offset:offset+len(b)]+=b
        assert all(a['subtitle_end_ms']<=b['proposed_start_ms'] for a,b in zip(adjusted,adjusted[1:]))
        result=wav(OUT/f'{part}-temporary-rehearsal.wav',mix)
        parts[part]=dict(original_duration_ms=opening['durations_ms'][part],proposed_duration_ms=total,extra_ms=shift,audio=result)
        timeline[part]=adjusted
        srt=[];vtt=['WEBVTT','']
        for i,rec in enumerate(adjusted,1):
            text=rec['text'] if part=='A' else rec['speaker_name']+'：'+rec['text']
            srt += [str(i),f"{stamp(rec['proposed_start_ms'])} --> {stamp(rec['subtitle_end_ms'])}",text,'']
            vtt += [str(i),f"{stamp(rec['proposed_start_ms'],'.')} --> {stamp(rec['subtitle_end_ms'],'.')}",text,'']
        (OUT/f'{part}-rehearsal.srt').write_text('\n'.join(srt),encoding='utf-8')
        (OUT/f'{part}-rehearsal.vtt').write_text('\n'.join(vtt),encoding='utf-8')
    write(OUT/'alignment.json',dict(status='proposal_only_not_runtime_timing',canonical_utf8_sha256=canonical,parts=parts,cues=records))
    write(DOC/'technical-validation.json',dict(cues=29,decoded=29,aggregate_tracks_decoded=2,input_text_verbatim=True,
          original_narration_sha256=canonical,non_overlapping_subtitles=True,
          overlong_cues=[r['id'] for r in records if r['required_extra_ms']>0],parts=parts,
          pronunciation_verification='pending_actual_listening',runtime_integrated=False))
    cards=[]
    for rec in records:
        note=f"需延长 {rec['required_extra_ms']}ms" if rec['required_extra_ms'] else '当前窗口可容纳'
        cards.append(f'<article><h3>{rec["id"]} · {rec["speaker_name"]}</h3><p>{html.escape(rec["text"])}</p><audio controls preload="none" src="samples/{rec["id"]}.wav"></audio><p class="meta">原窗口 {(rec["original_end_ms"]-rec["original_start_ms"])/1000:.2f}s · 样本 {rec["audio"]["duration_ms"]/1000:.2f}s · {note}</p></article>')
    embeds=''.join(f'<section><h2>{"历史旁白" if part=="A" else "任务对白"} · 临时合成排演</h2><audio id="{part}" controls preload="metadata" src="{part}-temporary-rehearsal.wav"></audio><p id="caption-{part}" class="caption">播放时显示对应字幕</p><p class="meta">排演 {parts[part]["proposed_duration_ms"]/1000:.2f}秒 · <a href="{part}-rehearsal.srt">字幕文件</a></p></section>' for part in ['A','B'])
    page='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>S31 临时语音排演</title>
<style>body{max-width:1080px;margin:40px auto;padding:0 24px;background:#132129;color:#f1f5f7;font:17px/1.7 system-ui}h1{font-size:34px}.meta{font-size:14px;color:#b2c6cf}audio{width:100%}section,article{background:#20343e;border-radius:14px;padding:20px;margin:18px 0}.caption{min-height:65px;font-size:22px;color:#f3d89b}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:18px}article{margin:0}h3{margin-top:0}a{color:#93d9db}</style>
<h1>S31 · 临时语音与字幕排演</h1><p>这是本机中文合成朗读，用于核对节奏、字幕和停顿。尚未经听审，不能代表最终演员表演。两位人物暂用同一系统声线、不同语速；角色声音区别尚未完成。</p>
<p>旁白完整保留指定原文。过长句子按实际长度顺延排演时间，不截断语音；正式游戏时间轴尚未改变。</p>'''+embeds+'<h2>逐句对照</h2><main>'+''.join(cards)+'</main><script>const cues='+json.dumps(timeline,ensure_ascii=False).replace('</','<\/')+''';
for(const part of ['A','B']){const a=document.getElementById(part);a.ontimeupdate=()=>{const ms=a.currentTime*1000,c=cues[part].find(c=>ms>=c.proposed_start_ms&&ms<c.subtitle_end_ms);document.getElementById('caption-'+part).textContent=c?(part==='B'?c.speaker_name+'：':'')+c.text:'（留白）'}}
document.addEventListener('play',e=>{if(e.target.tagName==='AUDIO')document.querySelectorAll('audio').forEach(a=>{if(a!==e.target)a.pause()})},true);</script></html>'''
    (OUT/'index.html').write_text(page,encoding='utf-8')
    review=['# S31 临时合成语音与字幕准备','', '所有语音仅为临时排演，未接入正式工程。来源是本机Windows System.Speech / Microsoft Kangkang；非演员录音，不模仿任何现实人物。', '',
            '固定旁白15句、任务对白14句，输入文本逐字核对通过。旁白原文SHA-256：'+canonical, '',
            '逐句原始WAV、生成参数在raw/与synthesis.json，剪辑与排演对照在alignment.json。离线试听页提供两段完整排演和逐句试听，字幕SRT/VTT与排演样本同步。', '',
            '| 段落 | 原时间 | 排演时间 | 增量 |','|---|---|---|---|']
    for p,r in parts.items():review.append(f"| {p} | {r['original_duration_ms']/1000:.2f}s | {r['proposed_duration_ms']/1000:.2f}s | {r['extra_ms']/1000:.2f}s |")
    review+=['','## 下一步','', '实际试听合成语音的发音、停顿和语气，选择继续使用明确标注的合成方案或替换演员录音；随后才能决定正式时间轴。',
             '当前保留原镜头、表演、字幕及爆炸节拍；不把临时朗读当作最终配音。若采用较长语音，需要同时重排镜头、动作、音乐和字幕，不能只改字幕结束时间。',
             '技术验证仅证明29段与两段合成文件可解码、输入文本一致且排演字幕不重叠。不能证明实际发音正确或艺术表演合适。']
    (DOC/'rehearsal-review.md').write_text('\n'.join(review)+'\n',encoding='utf-8')
    print(json.dumps({'cues':len(records),'parts':parts,'overlong':[r['id'] for r in records if r['required_extra_ms']]},ensure_ascii=True))


if __name__=='__main__':main()

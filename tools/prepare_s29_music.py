"""Download attributed music candidates and make offline listening comparisons."""
from pathlib import Path
import datetime
import hashlib
import html
import json
import os
import re
import subprocess
import urllib.request
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'AssetLibrary/audio/S29_20261015'
DOC = ROOT/'docs/audio/S29'
RATE = 48000
TRACKS = [
    dict(id='solemn-war', title='To Be Tacribian', author='Eliot Corley from ChaosIsHarmony',
         source_url='https://opengameart.org/content/solemn-war-music',
         download_url='https://opengameart.org/sites/default/files/To%20Be%20Tacribian_0.ogg',
         license='CC-BY-3.0', license_url='https://creativecommons.org/licenses/by/3.0/',
         file='To Be Tacribian.ogg', purpose='行军／历史序章',
         reason='作者描述为战前行军或庄重回想；时代与民族风格是否合适须试听，不能仅凭标签确认。',
         attribution='To Be Tacribian — Eliot Corley from ChaosIsHarmony (CC BY 3.0)'),
    dict(id='stealth', title='Stealth in the Woods', author='Lisboa',
         source_url='https://opengameart.org/content/stealth-music',
         download_url='https://opengameart.org/sites/default/files/Stealth%20in%20the%20Woods_0.mp3',
         license='CC0-1.0', license_url='https://creativecommons.org/publicdomain/zero/1.0/',
         existing='AssetLibrary/audio/stealth-music/originals/Stealth in the Woods_0.mp3',
         file='Stealth in the Woods_0.mp3', purpose='林场探索／潜行',
         reason='复用已下载原曲；作者称可循环，实际循环听感仍需确认。',
         attribution='Stealth in the Woods — Lisboa (CC0)'),
    dict(id='battle', title='Battle Theme A', author='cynicmusic',
         source_url='https://opengameart.org/content/battle-theme-a',
         download_url='https://opengameart.org/sites/default/files/battleThemeA.mp3',
         license='CC0-1.0', license_url='https://creativecommons.org/publicdomain/zero/1.0/',
         file='battleThemeA.mp3', purpose='实际交火／撤离压力',
         reason='作者描述为弦乐与铜管的战斗主题；检查是否过于游戏化、是否盖过枪声及对白。',
         attribution='Battle Theme A — cynicmusic.com / pixelsphere.org (CC0)'),
    dict(id='peaceful', title='Peaceful Intro', author='Eric Matyas',
         source_url='https://opengameart.org/content/peaceful-intro-looping',
         download_url='https://opengameart.org/sites/default/files/peaceful_intro_0.ogg',
         license='CC-BY-3.0', license_url='https://creativecommons.org/licenses/by/3.0/',
         file='peaceful_intro_0.ogg', purpose='天池谈话／休整',
         reason='作者描述为安静钢琴短循环；谈话背景候选，优先测试低音量下是否干扰语音。',
         attribution='"Peaceful Intro" by Eric Matyas — www.soundimage.org (CC BY 3.0)'),
    dict(id='solemn-opening', title='Solemn (Opening)', author='İlker Yalçıner (onemansymphony)',
         source_url='https://opengameart.org/content/solemn-opening',
         download_url='https://opengameart.org/sites/default/files/Solemn%20%28Opening%29_0.mp3',
         license='CC-BY-4.0', license_url='https://creativecommons.org/licenses/by/4.0/',
         file='Solemn (Opening)_0.mp3', purpose='结尾／历史收束',
         reason='钢琴与弦乐背景，含人声与合成器；需检查低落或悬疑气质是否偏离坚韧的结尾。',
         attribution='Composer: İlker Yalçıner (ilkeryalciner.com) — Solemn (Opening), CC BY 4.0'),
]


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def request(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent':'Mozilla/5.0 (GameMake asset research)'}),timeout=25)


def decode(path):
    p=subprocess.run(['ffmpeg','-nostdin','-v','error','-i',str(path),'-ar',str(RATE),'-ac','2','-f','f32le','-'],capture_output=True,check=True)
    a=np.frombuffer(p.stdout,dtype='<f4').reshape(-1,2).astype(np.float64)
    assert len(a)>0 and np.isfinite(a).all()
    return a


def fade(a,seconds=.6):
    a=a.copy();n=min(len(a)//2,round(seconds*RATE))
    t=np.linspace(0,1,n)[:,None];a[:n]*=t;a[-n:]*=t[::-1]
    return a


def wav(path,a):
    path.parent.mkdir(parents=True,exist_ok=True)
    assert np.abs(a).max()<1
    with wave.open(str(path),'wb') as w:
        w.setnchannels(2);w.setsampwidth(2);w.setframerate(RATE);w.writeframes(np.rint(a*32767).astype('<i2').tobytes())
    subprocess.run(['ffmpeg','-nostdin','-v','error','-i',str(path),'-f','null','-'],capture_output=True,check=True)
    return dict(path=path.relative_to(ROOT).as_posix(),sha256=sha(path),duration_seconds=round(len(a)/RATE,6),
                peak_dbfs=round(float(20*np.log10(max(np.abs(a).max(),1e-12))),2),
                rms_dbfs=round(float(20*np.log10(max(np.sqrt(np.mean(a*a)),1e-12))),2),decode_ok=True)


def main():
    (OUT/'originals').mkdir(parents=True,exist_ok=True)
    (OUT/'licenses').mkdir(exist_ok=True)
    records=[];montage=[];cursor=0;timeline=[]
    for definition in TRACKS:
        rec=dict(definition,listening_status='pending_human_listening',integrated_in_game=False)
        try:
            original=ROOT/rec['existing'] if 'existing' in rec else OUT/'originals'/rec['file']
            if not original.exists():
                # Exclusive temporary file: interrupted downloads are retained for evidence.
                partial=original.with_name(original.name+'.partial-'+datetime.datetime.now().strftime('%H%M%S'))
                with request(rec['download_url']) as response, partial.open('xb') as target:
                    total=0
                    while data:=response.read(1024*1024):
                        total+=len(data)
                        if total>100*1024*1024:raise ValueError('Download exceeds 100 MiB')
                        target.write(data)
                partial.rename(original)
            rec['original_path']=original.relative_to(ROOT).as_posix()
            rec['bytes']=original.stat().st_size;rec['sha256']=sha(original)
            license_path=OUT/'licenses'/(rec['license']+'.html')
            if not license_path.exists():
                with request(rec['license_url']) as response:license_path.write_bytes(response.read())
            a=decode(original);duration=len(a)/RATE
            rec.update(status='original_decoded',duration_seconds=round(duration,6),sample_rate=RATE,channels=2)
            rec['original_decode_peak_dbfs']=round(float(20*np.log10(max(np.abs(a).max(),1e-12))),2)
            # Common comparison loudness only; final mix levels are intentionally undecided.
            gain=min(10**(-24/20)/max(np.sqrt(np.mean(a*a)),1e-12),10**(-6/20)/max(np.abs(a).max(),1e-12))
            rec['audition_gain']=float(gain);a*=gain
            rec['processing']='试听版48kHz双声道；整曲RMS目标-24dBFS、峰值上限-6dBFS；片段首尾600ms淡化；不是正式混音'
            points=[0, round(max(0,duration-20)*.45,3), round(max(0,duration-20)*.85,3)]
            rec['excerpts']=[]
            for i,start in enumerate(points):
                clip=fade(a[round(start*RATE):round((start+20)*RATE)])
                item=wav(OUT/'samples'/f"{rec['id']}-{i+1}.wav",clip)
                item.update(source_start_seconds=start,source_end_seconds=round(start+len(clip)/RATE,6),
                            purpose=['开头','中部参考点','后部参考点'][i],musical_phrase_review='pending')
                rec['excerpts'].append(item)
                if i==0:
                    short=fade(clip[:16*RATE]);montage.extend([short,np.zeros((RATE,2))])
                    timeline.append(dict(id=rec['id'],title=rec['title'],start_seconds=round(cursor,3),end_seconds=round(cursor+len(short)/RATE,3)))
                    cursor+=len(short)/RATE+1
            # Author-declared loops only; provide wrap preview without silently manufacturing seamless music.
            if rec['id'] in ['stealth','peaceful']:
                join=np.concatenate((a[-4*RATE:],a[:4*RATE]))
                rec['loop_review']=wav(OUT/'samples'/f"{rec['id']}-seam.wav",fade(join,.1))
                rec['loop_review'].update(boundary_at_preview_seconds=4,declared_by_author=True,
                     decoded_boundary_delta=float(np.max(np.abs(a[-1]-a[0]))),verdict='pending_human_listening')
            else:
                rec['loop_review']={'declared_by_author':False,'verdict':'not_confirmed','proposed_use':'一次性片段淡入淡出；不直接设循环'}
            rec['status']='candidate_prepared'
        except Exception as exc:
            rec.update(status='failed',error=str(exc))
        records.append(rec)
        write(OUT/'manifest.json',{'records':records,'status':'work_in_progress'})
        print(json.dumps({'id':rec['id'],'status':rec['status'],'error':rec.get('error')},ensure_ascii=True),flush=True)
    summary=wav(OUT/'music-summary.wav',np.concatenate(montage)) if montage else None
    write(DOC/'audition-timeline.json',timeline)
    write(OUT/'manifest.json',{'records':records,'status':'technical_preparation_complete_listening_pending','summary':summary})
    write(DOC/'technical-validation.json',{'passed':sum(r['status']=='candidate_prepared' for r in records),'total':len(records),
         'new_downloads':sum('existing' not in r and r['status']=='candidate_prepared' for r in records),
         'reused_downloads':sum('existing' in r for r in records),'preview_decode_checks':sum(len(r.get('excerpts',[]))+(1 if r.get('loop_review',{}).get('decode_ok') else 0) for r in records),
         'subjective_listening':'pending','runtime_integration':False,'summary':summary})
    cards=[]
    for rec in records:
        if rec['status']!='candidate_prepared':continue
        controls=''.join(f'<p>{x["purpose"]} · 原曲 {x["source_start_seconds"]:.1f}–{x["source_end_seconds"]:.1f} 秒</p><audio controls preload="none" src="samples/{Path(x["path"]).name}"></audio>' for x in rec['excerpts'])
        if rec['loop_review'].get('decode_ok'):
            controls+=f'<p>循环接缝对照 · 第4秒为拼接点</p><audio controls preload="none" src="samples/{rec["id"]}-seam.wav"></audio>'
        original_link=Path(os.path.relpath(ROOT/rec['original_path'], OUT))
        cards.append(f'<article><h2>{html.escape(rec["title"])}</h2><b>{rec["purpose"]}</b><p>{html.escape(rec["reason"])}</p>{controls}<p class="meta">{html.escape(rec["attribution"])}<br>原曲 {rec["duration_seconds"]:.1f} 秒 · <a href="{rec["source_url"]}">来源</a> · <a href="{rec["license_url"]}">许可</a></p><a href="{html.escape(original_link.as_posix(),quote=True)}">打开完整原曲</a><p><label>听后结论 <select data-id="{rec["id"]}"><option value="pending">尚未试听</option><option value="accept">适合拟定用途</option><option value="revise">需要剪辑调整</option><option value="reserve">备用或不合适</option></select></label></p><input data-note="{rec["id"]}" placeholder="听后备注" aria-label="{html.escape(rec["title"],quote=True)}听后备注"></article>')
    page='''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>S29 音乐试听</title>
<style>body{max-width:1060px;margin:40px auto;padding:0 24px;background:#111c23;color:#edf4f5;font:17px/1.7 system-ui}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:20px}article{background:#1b2d36;padding:22px;border-radius:14px}h1{font-size:36px}h2{font-size:22px}.meta{font-size:14px;color:#b2c5ce}audio,input{width:100%;margin:8px 0}a{color:#91d8cf}select,input,button{background:#edf4f5;color:#132a31;border:0;border-radius:5px;padding:8px;box-sizing:border-box}button{margin:12px 0 24px;cursor:pointer}</style>
<h1>S29 · 配乐候选试听</h1><p>5首候选对应行军、探索、战斗、谈话和结尾。每首有开头、中部和后部片段，循环曲另附接缝对照。</p>
<p>本页是选材比较，尚未接入正式游戏。标注的用途来自创作意图和作者说明，是否合适仍由实际试听决定。</p>
<h2>85秒顺序预览</h2><audio controls preload="metadata" src="music-summary.wav"></audio><p>每首16秒，曲间留1秒。顺序与卡片一致。</p>
<button id="export">保存听后记录</button><main>'''+''.join(cards)+'''</main><script>
const key='gamemake-s29-audition-v1';let results={};try{results=JSON.parse(localStorage.getItem(key)||'{}')}catch{};
const controls=[...document.querySelectorAll('select,input')];for(const el of controls){const id=el.dataset.id||el.dataset.note,field=el.tagName==='SELECT'?'decision':'note';el.value=results[id]?.[field]||(field==='decision'?'pending':'');el.onchange=()=>{results[id]??={};results[id][field]=el.value;try{localStorage.setItem(key,JSON.stringify(results))}catch{}}}
document.addEventListener('play',e=>{if(e.target.tagName==='AUDIO')document.querySelectorAll('audio').forEach(a=>{if(a!==e.target)a.pause()})},true);
document.getElementById('export').onclick=()=>{controls.forEach(e=>e.onchange());const blob=new Blob([JSON.stringify({step:'S29',reviewer:'human',time:new Date().toISOString(),results},null,2)],{type:'application/json'});const url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download='S29-listening-review.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000)};</script></html>'''
    (OUT/'index.html').write_text(page,encoding='utf-8')
    credits=['# S29 配乐来源与修改','', '所有曲目尚未接入游戏。试听派生保留原作者许可；作者不代表认可本项目。','']
    for rec in records:
        credits += [f'## {rec["title"]}', '',rec['attribution'],f'来源：{rec["source_url"]}',f'许可：{rec["license_url"]}',f'用途候选：{rec["purpose"]}',rec['reason'],
                    rec.get('processing','尚未加工'),'原曲与SHA-256、所有剪辑时点和增益见manifest.json。','']
    (OUT/'CREDITS.md').write_text('\n'.join(credits)+'\n',encoding='utf-8')


if __name__=='__main__':main()

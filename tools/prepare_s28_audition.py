"""Build offline S28 candidates; technical analysis is NOT a listening verdict."""
from pathlib import Path
import hashlib
import html
import json
import subprocess
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / 'AssetLibrary/audio'
OUT = LIB / 'S28_20261015'
DOC = ROOT / 'docs/audio/S28'
RATE = 48000


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def decode(path):
    raw = subprocess.run(['ffmpeg', '-nostdin', '-v', 'error', '-i', str(path),
                          '-f', 'f32le', '-ar', str(RATE), '-ac', '1', '-'],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype='<f4').astype(np.float64)


def edges(a, fade_in=.003, fade_out=.06):
    a = a.copy()
    for n, tail in [(min(len(a)//2, round(RATE*fade_in)), False),
                    (min(len(a)//2, round(RATE*fade_out)), True)]:
        if n > 1:
            curve = np.linspace(0, 1, n)
            if tail:
                a[-n:] *= curve[::-1]
            else:
                a[:n] *= curve
    return a


def loop(a, seconds=.5):
    n = min(round(seconds*RATE), len(a)//4)
    t = np.linspace(0, 1, n)
    return edges(np.concatenate((a[n:-n], a[-n:]*(1-t)+a[:n]*t)), .002, .002)


def save_wav(path, a):
    path.parent.mkdir(parents=True, exist_ok=True)
    assert np.isfinite(a).all() and len(a) > 0 and np.max(np.abs(a)) < 1
    pcm = np.rint(a*32767).astype('<i2')
    with wave.open(str(path), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())
    subprocess.run(['ffmpeg', '-nostdin', '-v', 'error', '-i', str(path), '-f', 'null', '-'],
                   capture_output=True, check=True)
    return {'decode_ok': True, 'sample_rate': RATE, 'channels': 1,
            'duration_seconds': round(len(a)/RATE, 6), 'peak_dbfs': round(20*np.log10(max(np.abs(a).max(), 1e-12)), 2),
            'rms_dbfs': round(20*np.log10(max(np.sqrt(np.mean(a*a)), 1e-12)), 2),
            'clipped_samples': int(np.sum(np.abs(pcm.astype(np.int32)) >= 32767)),
            'boundary_difference_pcm': abs(int(pcm[-1])-int(pcm[0])),
            'bytes': path.stat().st_size, 'sha256': digest(path)}


def main():
    ready = {Path(x['path']).name: x for x in read(LIB/'ready_to_import.json')}
    assets = {x['id']: x for x in read(LIB/'manifest.json')['assets']}
    downloads = {x['id']: x for x in read(OUT/'downloads.json')}
    records, samples = [], []

    def add(ident, label, group, source, provenance, reason, use='候选', peak=-9, looping=False, echo=False, clip=None):
        a = decode(source)
        edits = ['解码为48kHz单声道PCM16试听版；不覆盖原文件']
        if clip:
            # Select the first measurable event, retaining 30ms lead and a fixed window.
            indexes = np.flatnonzero(np.abs(a) > max(.01, np.abs(a).max()*.15))
            start = max(0, int(indexes[0])-1440) if len(indexes) else 0
            a = a[start:start+int(clip*RATE)]
            edits.append(f'能量阈值切片 {start/RATE:.6f}s 起、{len(a)/RATE:.6f}s 长；是否完整单次动作仍须听审')
        if echo:
            dry = a.copy()
            a = np.pad(a, (0, int(.48*RATE)))
            for delay, gain in [(.17, .30), (.31, .15), (.48, .07)]:
                offset = round(delay*RATE)
                a[offset:offset+len(dry)] += dry*gain
            edits.append('派生回声：170/310/480ms，增益0.30/0.15/0.07；非独立实录')
        a = loop(a) if looping else edges(a)
        gain = 10**(peak/20)/max(np.abs(a).max(), 1e-12)
        if looping:
            gain = min(gain, 10**(-25/20)/max(np.sqrt(np.mean(a*a)), 1e-12))
        a *= gain
        edits += ['500ms首尾交叉淡化及2ms端点淡化' if looping else '3ms淡入、60ms淡出', f'线性增益 {gain:.8f}；峰值上限{peak}dBFS']
        path = OUT/'samples'/f'{ident}.wav'
        result = save_wav(path, a)
        record = dict(id=ident, label=label, category=group, source_path=source.relative_to(ROOT).as_posix(),
                      source_sha256=digest(source), provenance=provenance,
                      path=path.relative_to(ROOT).as_posix(), edits=edits, loop=looping,
                      recommendation=use, reason=reason, listening_status='pending_human_listening',
                      integrated_in_game=False, technical=result)
        records.append(record)
        # Two repeats for loops, modest quiet gap between candidates, no autoplay.
        preview = a[:RATE*5]
        samples.append(np.concatenate((preview, np.zeros(RATE//2))))

    def prepared(name, ident, label, group, reason, **kw):
        p = ready[name]
        add(ident, label, group, LIB/p['path'], p, reason, **kw)

    prepared('arisaka_near_01.wav', 'rifle-near-1', '步枪近声 01', '枪声', '现用枪声的原准备版；.30-06元数据，仅为音色参考')
    prepared('arisaka_near_02.wav', 'rifle-near-2', '步枪近声 02', '枪声', '同来源变体，降低单一录音重复感')
    prepared('1911_near_01.wav', 'pistol-reference', '手枪音色参考', '枪声', '1911录音，不是C96实录；仅比较爆音与机械感', use='改造候选')
    prepared('arisaka_mid_01.wav', 'rifle-mid-dry', '中远距枪声原尾音', '回声', '先比较实录自然尾音，避免额外回声过密')
    prepared('arisaka_mid_01.wav', 'rifle-mid-echo', '中远距枪声加回声', '回声', '与上一项A/B对比；回声可能遮挡下一发，听审后择一', echo=True, use='改造候选')
    for surface, label in [('grass', '草土'), ('wood', '木板'), ('gravel', '碎石'), ('snow', '雪地')]:
        for i in [1, 2]:
            prepared(f'step_{surface}_{i:02}.wav', f'step-{surface}-{i}', f'{label}脚步 {i}', '脚步',
                     f'{label}材质候选；地表识别与落脚时序留S30', peak=-14)
    for name, label in [('forest', '林间风声'), ('mountains', '高地环境')]:
        prepared(f'amb_{name}.ogg', f'wind-{name}', label, '林风', '交叉淡化循环；接缝量测不代表循环听感通过', peak=-12, looping=True)
    q = assets['q009s-weapon-sounds']
    add('explosion-q009', '爆炸 Q009', '爆炸', LIB/'q009s-weapon-sounds/extracted/q009-sounds/q009/explosion.ogg',
        {k:q[k] for k in ['id','title','author','source_url','license','license_url','notes']}, '既有库中完整爆炸，风格化补充层；不是历史炮弹实录')
    for ident, label, reason, use in [('rumble','爆炸低频层','短促低频候选，可与爆炸主体比较，不先做叠加结论','候选'),
                                     ('retro-explosion','复古爆炸备用','作者明确用于复古游戏；写实战争方向不优先','备用')]:
        p = downloads[ident]
        add(ident, label, '爆炸', ROOT/p['path'], p, reason, use=use)
    for asset, name, ident, label, duration in [
        ('handling-guns','extracted/Gary Guns/Gary Guns/30-06_bolt.wav','bolt','枪机动作',1.1),
        ('cloth-swing-sounds','originals/cloth_sounds.wav','cloth','布料动作',.65)]:
        p = assets[asset]
        add(ident,label,'动作',LIB/asset/name,{k:p[k] for k in ['id','title','author','source_url','license','license_url','notes']},
            '从连续素材按首个可测事件切片；实际动作完整性须试听确认',clip=duration,peak=-16)
    montage = save_wav(OUT/'audition-summary.wav', np.concatenate(samples))
    timeline, cursor = [], 0.0
    for rec, sample in zip(records, samples):
        timeline.append({'id': rec['id'], 'label':rec['label'], 'start_seconds':round(cursor, 3), 'end_seconds':round(cursor+len(sample)/RATE-.5, 3)})
        cursor += len(sample)/RATE
    write(OUT/'selection.json', {'status':'technical_preparation_complete_listening_pending','records':records})
    write(DOC/'audition-timeline.json', timeline)
    write(DOC/'technical-validation.json', {'passed':len(records), 'total':len(records), 'method':'重新解码每份样本；幅度、端点与来源校验；无主观试听',
         'loop_samples': [r['id'] for r in records if r['loop']], 'montage':montage,
         'all_no_clipping':all(r['technical']['clipped_samples']==0 for r in records),
         'all_sources_exist':all((ROOT/r['source_path']).is_file() for r in records), 'subjective_listening':'pending'})
    cards = []
    for rec in records:
        p = rec['provenance']
        cards.append(f'''<article><h2>{html.escape(rec['label'])} <small>{rec['category']}</small></h2>
<p>{html.escape(rec['reason'])}</p><audio controls preload="none" {'loop' if rec['loop'] else ''} src="samples/{rec['id']}.wav"></audio>
<p class="meta">{rec['technical']['duration_seconds']:.2f} 秒 · {html.escape(p['author'])} · {p['license']} · 建议：{rec['recommendation']}</p>
<p><a href="{html.escape(p['source_url'],quote=True)}">原作者来源</a></p>
<label>听后结论 <select data-id="{rec['id']}"><option value="pending">尚未试听</option value="accept">可用</option><option value="revise">需要调整</option><option value="reserve">备用</option></select></label>
<input data-note="{rec['id']}" aria-label="{html.escape(rec['label'])}听后备注" placeholder="例如：尾音太长、低频太重、脚步太亮"></article>''')
    page = '''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>S28 音效试听</title>
<style>body{max-width:1040px;margin:40px auto;padding:0 24px;background:#101a21;color:#edf4f5;font:17px/1.7 system-ui}h1{font-size:36px}small,.meta{color:#acc0c9;font-size:14px}main{display:grid;grid-template-columns:repeat(auto-fit,minmax(300px,1fr));gap:18px}article{background:#1a2933;padding:20px;border-radius:14px}h2{font-size:21px;margin:0}audio,input{width:100%;margin:10px 0}select,input,button{background:#edf4f5;color:#14232b;padding:8px;border:0;border-radius:5px;box-sizing:border-box}a{color:#90d6dc}button{cursor:pointer;margin:10px 0 24px}</style>
<h1>S28 · 音效试听</h1><p>枪声、回声、林风、脚步、爆炸和动作。先将设备音量调到舒适水平，逐条播放比较；环境样本会循环。</p>
<p>本批20项已通过文件检查，听感尚待确认。这里的样本还没有接入正式游戏。可以填写听后结论并导出，记录会保存在下载目录。</p>
<h2>42秒顺序预览</h2><audio controls preload="metadata" src="audition-summary.wav"></audio><p>顺序与下列卡片一致；长声音取前5秒，项目间留半秒。</p>
<button id="export">保存听后记录</button><main>''' + ''.join(cards) + '''</main>
<script>const key='gamemake-s28-audition-v1';let old={};try{old=JSON.parse(localStorage.getItem(key)||'{}')}catch{};
const controls=[...document.querySelectorAll('select,input')];for(const e of controls){const id=e.dataset.id||e.dataset.note;const field=e.tagName==='SELECT'?'decision':'note';e.value=old[id]?.[field]|| (field==='decision'?'pending':'');e.onchange=()=>{old[id]??={};old[id][field]=e.value;try{localStorage.setItem(key,JSON.stringify(old))}catch{}}}
document.addEventListener('play',e=>{if(e.target.tagName==='AUDIO')document.querySelectorAll('audio').forEach(a=>{if(a!==e.target)a.pause()})},true);
document.getElementById('export').onclick=()=>{controls.forEach(e=>e.onchange());const blob=new Blob([JSON.stringify({step:'S28',reviewer:'human',time:new Date().toISOString(),results:old},null,2)],{type:'application/json'});const url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download='S28-listening-review.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000)};</script></html>'''
    (OUT/'index.html').write_text(page, encoding='utf-8')
    rows = ['| 项目 | 类别 | 建议 | 理由 |','|---|---|---|---|']
    rows += [f"| {r['label']} | {r['category']} | {r['recommendation']}，待听审 | {r['reason']} |" for r in records]
    (DOC/'selection-review.md').write_text('# S28 音效技术整理与待试听清单\n\n'
        '2026-10-15。20项样本完整解码通过、无样点削波；两项环境循环首尾差为0。未做主观试听，也未接入正式游戏。\n\n'
        '试听入口：`AssetLibrary/audio/S28_20261015/index.html`。逐项来源、原文件SHA-256、修改参数和测量在同目录 `selection.json`。\n\n'
        '新下载2项，已有库复用18项（含同源派生），不等于20份独立来源。网络失败：explosion-sound页面404，见network-probes.json。\n\n'
        + '\n'.join(rows) + '\n\n'
        '## 验收边界与续接\n\n当前工具只能读取和分析音频文件，不能提供主观听觉判断。峰值、波形、成功播放均不等于听感通过。'
        'S28保持进行中，等待实际试听结论；S30正式接入依赖该结论。手动连续制作期间，可先做S29下载与候选准备等独立工作，不能据此跳过S28验收。\n', encoding='utf-8')
    print(json.dumps({'samples':len(records),'montage_seconds':montage['duration_seconds'],'listening':'pending'},ensure_ascii=False))


if __name__ == '__main__':
    main()

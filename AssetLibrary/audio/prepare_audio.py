from pathlib import Path
import json,subprocess,hashlib,csv
ROOT=Path(r'C:\GameMake\AssetLibrary\audio'); m=json.loads((ROOT/'manifest.json').read_text(encoding='utf-8')); idx=json.loads((ROOT/'audio_validation.json').read_text(encoding='utf-8')); out=ROOT/'ready_to_import';out.mkdir(exist_ok=True)
assets={a['id']:a for a in m['assets']};ready=[]
for a in m['assets']:
 a['files']=[f for f in a['files'] if f.get('role')!='derived_ready_to_import']
def get(aid,name):return next(x for x in idx if x['asset_id']==aid and Path(x['path']).name==name)
def make(source,name,category,start=None,duration=None,channels=1,ogg=False,note=''):
 src=ROOT/source['path'];dst=out/category/(name+('.ogg' if ogg else '.wav'));dst.parent.mkdir(parents=True,exist_ok=True)
 cmd=['ffmpeg','-hide_banner','-nostdin','-v','error','-y','-i',str(src)]
 if start is not None:cmd+=['-ss',str(start)]
 if duration is not None:cmd+=['-t',str(duration)]
 cmd+=['-ar','48000','-ac',str(channels),'-map_metadata','-1']
 if category=='weapons':cmd+=['-af','volume=-3dB,afade=t=out:st='+str(round(duration-0.08,6))+':d=0.08']
 cmd+=['-c:a','libvorbis','-q:a','5'] if ogg else ['-c:a','pcm_s16le']
 cmd+=[str(dst)];subprocess.run(cmd,check=True,capture_output=True)
 p=subprocess.run(['ffprobe','-v','error','-show_entries','format=duration:stream=codec_name,sample_rate,channels','-of','json',str(dst)],capture_output=True,text=True,check=True);meta=json.loads(p.stdout)
 check=subprocess.run(['ffmpeg','-nostdin','-v','error','-i',str(dst),'-f','null','-'],capture_output=True,text=True,check=True)
 a=assets[source['asset_id']];origin=next(f for f in a['files'] if f['path']==source['path'])
 rec={'path':dst.relative_to(ROOT).as_posix(),'source_path':source['path'],'source_asset_id':a['id'],'source_url':a['source_url'],'download_url':origin['download_url'],'author':a['author'],'license':a['license'],'license_url':a['license_url'],'sha256':hashlib.sha256(dst.read_bytes()).hexdigest(),'bytes':dst.stat().st_size,'start_seconds':start,'duration_seconds':float(meta['format']['duration']),'sample_rate':48000,'channels':channels,'format':meta['streams'][0]['codec_name'],'decode_ok':True,'notes':note+' Converted to 48kHz; original untouched. Gun clips use -3dB gain and 80ms tail fade; auditory/mix review pending.' if category=='weapons' else note+' Converted to 48kHz; original untouched. Auditory/mix review pending.'}
 ready.append(rec)
 a['files'].append({'path':rec['path'],'download_url':rec['download_url'],'bytes':rec['bytes'],'sha256':rec['sha256'],'role':'derived_ready_to_import','source_path':source['path'],'modification':rec['notes']})
weapons=[('E_25P.wav','arisaka_near',[.513917,4.020125],2.55),('E_18P.wav','arisaka_mid',[.349479,4.47649],3.0),('M_21P.wav','mosin_near',[1.023781,5.00975,9.145615,14.127208],2.4),('M_26P.wav','mosin_mid',[1.127698,6.094646,10.732667],3.0),('A_42P.wav','1911_near',[.931448,4.99149],2.5),('B_24P.wav','1917_near',[1.298062,6.721104],3.0)]
for fname,label,starts,dur in weapons:
 for i,start in enumerate(starts,1):make(get('the-free-firearm-sound-library',fname),f'{label}_{i:02d}','weapons',start,dur,note='Single event cut from real firearm recording. Arisaka source metadata specifies .30-06; use as tonal reference, not verified original service ammunition.' if 'arisaka'in label else 'Single event cut from real firearm recording.')
for surface in ['grass','wood','gravel']:
 rows=sorted([x for x in idx if x['asset_id']=='footsteps-on-different-surfaces' and ('/'+surface+'/')in x['path']],key=lambda x:x['path'])[:6]
 for i,row in enumerate(rows,1):make(row,f'step_{surface}_{i:02d}','footsteps')
for i,row in enumerate([x for x in idx if x['asset_id']=='42-snow-and-gravel-footsteps'][:6],1):make(row,f'step_snow_{i:02d}','footsteps')
for row in [x for x in idx if x['asset_id']=='ambient-mountain-river-wind-and-forest-and-waterfall']:make(row,Path(row['path']).stem,'ambience',channels=row['channels'],ogg=True,note='Original loop suitability still requires listening.')
for aid,filename,label,ogg in [('opening-and-closing-a-map-sounds','snd_use_map.wav','map_open',False),('opening-and-closing-a-map-sounds','snd_close_map.wav','map_close',False),('sfx-circuit-breaker','switch on.wav','switch_on',False),('sfx-circuit-breaker','switch off.wav','switch_off',False),('mysterious-radio-signal','static-radio_0.ogg','radio_morse_static',True),('radio-noise-1','radio_noise_loop.wav','radio_static',True),('generator-loop','loop_generator_1.mp3','generator_loop',True)]:make(get(aid,filename),label,'props',ogg=ogg)
(ROOT/'ready_to_import.json').write_text(json.dumps(ready,ensure_ascii=False,indent=2),encoding='utf-8')
m['prepared_summary']={'derived_audio_files':len(ready),'decode_passed':len(ready),'bytes':sum(x['bytes']for x in ready),'sample_rate':48000,'note':'Additional derivatives of downloaded source files, not new downloaded performances. Mapping in ready_to_import.json.'}
for a in m['assets']:(ROOT/a['id']/'asset.json').write_text(json.dumps(a,ensure_ascii=False,indent=2),encoding='utf-8')
(ROOT/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
with (ROOT/'firearm_catalog.csv').open('w',newline='',encoding='utf-8-sig')as f:
 w=csv.DictWriter(f,fieldnames=['path','duration_seconds','sample_rate','channels','description']);w.writeheader()
 for row in idx:
  if row['asset_id']=='the-free-firearm-sound-library':w.writerow({'path':row['path'],'duration_seconds':row['duration_seconds'],'sample_rate':row['sample_rate'],'channels':row['channels'],'description':row['tags'].get('comment','')})
print(json.dumps(m['prepared_summary']))

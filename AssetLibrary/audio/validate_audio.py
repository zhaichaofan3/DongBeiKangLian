from pathlib import Path
import json,subprocess,concurrent.futures,collections,csv,hashlib
ROOT=Path(r'C:\GameMake\AssetLibrary\audio')
m=json.loads((ROOT/'manifest.json').read_text(encoding='utf-8'))
exts={'.wav','.ogg','.mp3','.flac','.aif','.aiff'}
items=[]
for a in m['assets']:
 for f in a['files']:
  p=ROOT/f['path']
  if f.get('role')!='derived_ready_to_import' and p.suffix.lower() in exts and not p.name.startswith('._') and '__MACOSX' not in p.parts:items.append((a['id'],f))
def probe(item):
 aid,f=item;p=ROOT/f['path'];rec={'asset_id':aid,'path':f['path'],'sha256':f['sha256'],'bytes':f['bytes']}
 try:
  proc=subprocess.run(['ffprobe','-v','error','-show_entries','format=duration:format_tags:stream=codec_name,codec_type,sample_rate,channels,bits_per_sample,bits_per_raw_sample','-of','json',str(p)],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=30,check=True)
  meta=json.loads(proc.stdout);stream=next(s for s in meta.get('streams',[]) if s.get('codec_type')=='audio')
  rec.update({'codec':stream['codec_name'],'sample_rate':int(stream['sample_rate']),'channels':stream['channels'],'duration_seconds':float(meta['format']['duration']),'tags':meta['format'].get('tags',{})})
  dec=subprocess.run(['ffmpeg','-nostdin','-v','error','-i',str(p),'-f','null','-'],stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,text=True,encoding='utf-8',errors='replace',timeout=90)
  rec['decode_ok']=dec.returncode==0
  if dec.stderr.strip():rec['decode_diagnostics']=dec.stderr.strip()[:2000]
 except Exception as e:rec['decode_ok']=False;rec['error']=str(e)
 return rec
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as p:records=list(p.map(probe,items))
(ROOT/'audio_validation.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf-8')
with (ROOT/'audio_index.csv').open('w',encoding='utf-8-sig',newline='') as f:
 fields=['asset_id','path','codec','sample_rate','channels','duration_seconds','bytes','decode_ok','sha256']
 w=csv.DictWriter(f,fieldnames=fields,extrasaction='ignore');w.writeheader();w.writerows(records)
summary={}
for a in m['assets']:
 r=[r for r in records if r['asset_id']==a['id']]
 a['validation']={'audio_file_count':len(r),'decode_passed':sum(x['decode_ok'] for x in r),'sample_rates':sorted({x['sample_rate'] for x in r if 'sample_rate'in x}),'channels':sorted({x['channels'] for x in r if 'channels'in x}),'total_duration_seconds':round(sum(x.get('duration_seconds',0) for x in r),2),'duration_range_seconds':[round(min(x.get('duration_seconds',0) for x in r),3),round(max(x.get('duration_seconds',0) for x in r),3)] if r else [],'method':'ffprobe metadata plus full ffmpeg null decode; no exhaustive auditory review'}
 a['status']='downloaded_extracted_decode_verified' if all(x['decode_ok'] for x in r) and r else 'needs_attention'
 (ROOT/a['id']/'asset.json').write_text(json.dumps(a,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps({'id':a['id'],**a['validation']}),flush=True)
m['validation_summary']={'asset_packs':len(m['assets']),'audio_files':len(records),'decode_passed':sum(r['decode_ok'] for r in records),'unique_exact_hashes':len({r['sha256'] for r in records}),'total_duration_seconds':round(sum(r.get('duration_seconds',0) for r in records),2),'sample_rates':sorted({r['sample_rate'] for r in records if 'sample_rate'in r}),'channels':sorted({r['channels'] for r in records if 'channels'in r}),'total_manifest_file_bytes':sum(f['bytes'] for a in m['assets'] for f in a['files']),'note':'Audio file count excludes macOS resource forks; includes alternate-format takes and multi-take recordings, not unique isolated sound events.'}
(ROOT/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(m['validation_summary']))

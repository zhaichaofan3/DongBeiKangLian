from pathlib import Path
import concurrent.futures,urllib.request,re,json,html,hashlib,zipfile,subprocess,os,urllib.parse,shutil
ROOT=Path(r'C:\GameMake\AssetLibrary\audio'); ROOT.mkdir(parents=True,exist_ok=True)
A=[]
def oga(slug,title,author,lic,notes='',select=None):
 A.append(dict(id=slug,title=title,source_url='https://opengameart.org/content/'+slug,author=author,license=lic,notes=notes,select=select))
def kenney(slug,title,notes):
 A.append(dict(id='kenney-'+slug,title=title,source_url='https://kenney.nl/assets/'+slug,author='Kenney',license='CC0-1.0',notes=notes))
oga('the-free-firearm-sound-library','The Free Firearm Sound Library','Ben Jaszczak; Brian Nelson; Kevin Heras; Matthew Nanney','CC0-1.0','Real firearm prepared SFX. Primary gunshot source; choose bolt-action/period-compatible timbre and synchronize per animation.')
oga('handling-guns','Handling Guns','Gary (fossilrecords.net)','CC-BY-SA-3.0','Includes bolt-action rifle mechanics and dry recordings. Credit Guns by Gary; preserve share-alike for modified audio.')
oga('gun-reload-sounds','Gun reload sounds','SpringySpringo','CC0-1.0','Airsoft recordings; useful mechanical layers, not historically exact rifle handling.')
oga('q009s-weapon-sounds',"Q009 weapon sounds",'Q009','CC-BY-SA-3.0','Gunshots, reloads, shell eject and explosions; stylized supplemental layers.')
oga('ambient-mountain-river-wind-and-forest-and-waterfall','Ambient mountain, river, wind, forest and waterfall','Blender Foundation','CC-BY-3.0','From Yo Frankie; use forest and water loops, check transitions before game import.')
oga('fantozzis-footsteps-grasssand-stone','Fantozzi footsteps grass/sand and stone','Fantozzi; prepared by Iwan Gabovitch (qubodup)','CC0-1.0','12 steps in FLAC and OGG; avoid counting alternate formats as unique performances.')
oga('footsteps-on-different-surfaces','Footsteps on different surfaces','congusbongus and individual contributors listed in included text files','CC-BY-3.0','Seven surface groups including grass/dirt, gravel, water, wood and metal. Preserve per-file credits in included text files.')
oga('42-snow-and-gravel-footsteps','42 snow and gravel footsteps','Corsica_S; extracted by Iwan Gabovitch','CC0-1.0','Snow and gravel useful for northeast outdoor terrain.')
oga('footsteps-leather-cloth-armor','Footsteps leather, cloth, armor','HaelDB','CC0-1.0','Page offers CC0 and OGA-BY 3.0 alternatives; selected CC0. Soft gain, suitable clothing layers.')
oga('cloth-swing-sounds','Cloth swing sounds','Vinrax','CC-BY-3.0','Continuous takes in WAV; slice into individual motion cues before use.',r'\.wav$')
oga('paper-pages-sounds','Paper pages sounds','Vinrax','CC-BY-3.0','WAV contains separate takes divided by click; slice and remove separators.',r'\.wav$')
oga('opening-and-closing-a-map-sounds','Opening and closing a map','Julie Damsgaard / Spring Spring / Spring Enterprises','CC0-1.0','Two ready cues for maps or documents.')
oga('creaky-light-wooden-door','Creaky light wooden door','fractilegames','CC-BY-3.0','Recorded cabinet door; suitable close creak layer.')
oga('door-open-door-close-set','Door open / close set','qubodup','CC0-1.0','Wooden/metal/synthetic doors. Select wood variants for village and telegraph room.')
oga('super-foley-pack','Super Foley Pack','dklon','CC-BY-3.0','Raw multi-take leather, clothing, chest/hand impacts, shuffling and wooden chair sounds; edit before direct event use.')
oga('inventory-sound-effects','Inventory Sound Effects','artisticdude','CC-BY-3.0','Multiple alternative licenses offered; selected CC-BY 3.0. Six material/object interaction cues.')
oga('stealth-music','Stealth in the Woods','Lisboa','CC0-1.0','Loopable stealth music candidate; artistic suitability and loop seams not yet auditioned.')
oga('mysterious-radio-signal','Mysterious Radio Signal','nicStage (2005); Sam Uncle (2017)','CC-BY-3.0','Static and Morse code mixture; ambient radio layer only, not a historically verified message. Original contributor credit retained.')
oga('radio-noise-1','Radio Noise 1','Kresiek The Furry','CC0-1.0','Real recorded radio static; ambience layer.')
oga('sfx-circuit-breaker','SFX Circuit breaker','Cleyton Kauffman','CC0-1.0','On and off switch events.')
oga('generator-loop','Generator loop','YCbCr','CC0-1.0','Low-frequency machinery layer.')
kenney('impact-sounds','Kenney Impact Sounds','130 material impacts; wood/metal/glass layers.')
kenney('rpg-audio','Kenney RPG Audio','Equipment/footstep/object sounds; select only realistic period-compatible sounds.')
license_urls={'CC0-1.0':'https://creativecommons.org/publicdomain/zero/1.0/','CC-BY-3.0':'https://creativecommons.org/licenses/by/3.0/','CC-BY-SA-3.0':'https://creativecommons.org/licenses/by-sa/3.0/'}
UA={'User-Agent':'Mozilla/5.0 (asset research)'}
def fetch(url,path):
 with urllib.request.urlopen(urllib.request.Request(url,headers=UA),timeout=60) as r,path.open('wb') as f:
  total=0
  while b:=r.read(1024*1024):
   total+=len(b)
   if total>350*1024*1024: raise RuntimeError('Individual download exceeds 350 MiB budget')
   f.write(b)
 return path.stat().st_size
def checksum(p):
 h=hashlib.sha256()
 with p.open('rb') as f:
  while b:=f.read(1024*1024):h.update(b)
 return h.hexdigest()
def safe_name(n):
 n=n.replace('\\','/')
 return not(n.startswith('/') or ':' in n or any(x=='..' for x in n.split('/')))
def extract(p,dest):
 dest.mkdir(exist_ok=True)
 if p.suffix.lower()=='.zip':
  with zipfile.ZipFile(p) as z:
   for x in z.infolist():
    norm=x.filename.replace('\\','/')
    if norm.startswith('/') or re.match(r'^[A-Za-z]:',norm) or '..' in norm.split('/'):raise ValueError('Unsafe archive path '+x.filename)
    if (x.external_attr>>16)&0o170000==0o120000:raise ValueError('Symlink in archive')
   if sum(x.file_size for x in z.infolist())>650*1024*1024: raise ValueError('Expanded archive too large')
   for x in z.infolist():
    # Replace Windows-invalid characters in ordinary basenames, never interpret them as streams.
    target=dest.joinpath(*[re.sub(r'[<>:"|?*]', '_', part) for part in x.filename.replace('\\','/').split('/') if part])
    if not target.resolve().is_relative_to(dest.resolve()):raise ValueError('Unsafe resolved ZIP path')
    if x.is_dir():target.mkdir(parents=True,exist_ok=True)
    else:
     target.parent.mkdir(parents=True,exist_ok=True)
     with z.open(x) as src,target.open('wb') as dst:shutil.copyfileobj(src,dst)
 elif p.suffix.lower()=='.7z':
  listing=subprocess.run(['tar','-tf',str(p)],capture_output=True,text=True,errors='replace',check=True).stdout.splitlines()
  if any(not safe_name(n) for n in listing):raise ValueError('Unsafe 7z path')
  details=subprocess.run(['tar','-tvf',str(p)],capture_output=True,text=True,errors='replace',check=True).stdout.splitlines()
  if any(l[:1] not in ['-','d'] for l in details if l.strip()):raise ValueError('Archive contains links or unusual entries')
  subprocess.run(['tar','-xf',str(p),'-C',str(dest)],capture_output=True,text=True,check=True)
 else:return
 # No archived programs are executed.
 for item in dest.rglob('*'):
  if item.is_symlink() or not item.resolve().is_relative_to(dest.resolve()):raise ValueError('Unexpected extracted link')
def collect(a):
 a=a.copy();d=ROOT/a['id'];d.mkdir(exist_ok=True);a['license_url']=license_urls[a['license']];a['files']=[];a['status']='pending'
 try:
  page=d/'source.html';fetch(a['source_url'],page);s=page.read_text(encoding='utf-8')
  txt=html.unescape(re.sub('<[^>]*>',' ',re.sub(r'<script.*?</script>|<style.*?</style>','',s,flags=re.S)));txt=' '.join(txt.split())
  (d/'source.txt').write_text(txt,encoding='utf-8')
  links=[urllib.parse.urljoin(a['source_url'],html.unescape(u)) for u in re.findall(r'''href=['\"]([^'\"]+)''',s)]
  if 'kenney.nl' in a['source_url']:links=[u for u in links if u.endswith('.zip')]
  else:links=[u for u in links if '/sites/default/files/' in u and re.search(r'\.(zip|7z|wav|ogg|mp3|flac)$',u,re.I)]
  if a.get('select'):links=[u for u in links if re.search(a['select'],u,re.I)]
  links=list(dict.fromkeys(links));a.pop('select',None)
  if not links:raise ValueError('No downloadable source asset links')
  originals=d/'originals';originals.mkdir(exist_ok=True)
  for u in links:
   name=Path(urllib.parse.unquote(urllib.parse.urlparse(u).path)).name;p=originals/name
   if not p.exists() or p.stat().st_size==0:fetch(u,p)
   a['files'].append({'path':str(p.relative_to(ROOT)).replace('\\','/'),'download_url':u,'bytes':p.stat().st_size,'sha256':checksum(p),'role':'original_download'})
   if p.suffix.lower() in ['.zip','.7z']:
    dest=d/'extracted'/p.stem;dest.mkdir(parents=True,exist_ok=True);extract(p,dest)
    for ep in sorted(dest.rglob('*')):
     if ep.is_file():a['files'].append({'path':str(ep.relative_to(ROOT)).replace('\\','/'),'download_url':u,'bytes':ep.stat().st_size,'sha256':checksum(ep),'role':'extracted'})
  (d/'LICENSE-SOURCE.txt').write_text(f"Title: {a['title']}\nAuthor: {a['author']}\nLicense: {a['license']}\nLicense URL: {a['license_url']}\nSource: {a['source_url']}\nEvidence: source.html and source.txt\nNotes: {a['notes']}\n",encoding='utf-8')
  a['status']='downloaded_and_extracted'
 except Exception as e:a['status']='needs_attention';a['error']=str(e)
 (d/'asset.json').write_text(json.dumps(a,ensure_ascii=False,indent=2),encoding='utf-8')
 print(json.dumps({'id':a['id'],'status':a['status'],'files':len(a['files']),'bytes':sum(f['bytes'] for f in a['files']),'error':a.get('error')},ensure_ascii=True),flush=True)
 return a
if __name__=='__main__':
 with concurrent.futures.ThreadPoolExecutor(max_workers=5) as pool:assets=list(pool.map(collect,A))
 (ROOT/'manifest.json').write_text(json.dumps({'category':'audio','assets':assets},ensure_ascii=False,indent=2),encoding='utf-8')

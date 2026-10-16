import requests,re,pathlib,json,hashlib,zipfile,time,sys

sys.stdout.reconfigure(encoding="utf8")
BASE=pathlib.Path(__file__).resolve().parent
ITEMS=[("quaternius_ual1","universal-animation-library"),("quaternius_ual2","universal-animation-library-2"),("quaternius_base_characters","universal-base-characters")]
results=[]
for aid,slug in ITEMS:
 d=BASE/aid;d.mkdir(exist_ok=True)
 s=requests.Session();s.headers["User-Agent"]="Mozilla/5.0 (Asset collection for personal game development)"
 u="https://quaternius.itch.io/"+slug
 r=s.get(u,timeout=45);r.raise_for_status();page=r.text;(d/"source.html").write_text(page,encoding="utf8")
 csrf=re.search(r'name="csrf_token" value="([^"]+)',page).group(1)
 r=s.post(u+"/download_url",data={"csrf_token":csrf},timeout=45);r.raise_for_status();dlpage=s.get(r.json()["url"],timeout=45);dlpage.raise_for_status()
 csrf=re.search(r'name="csrf_token" value="([^"]+)',dlpage.text).group(1)
 uploads=[]
 for block in dlpage.text.split('<div class="upload">')[1:]:
  uid=re.search(r'data-upload_id="(\d+)"',block)
  name=re.search(r'<strong[^>]+>([^<]+)</strong>',block)
  if uid and name: uploads.append((uid.group(1),name.group(1)))
 assert uploads, "No freely offered uploads"
 for uid,name in uploads:
  if "Standard" not in name: continue
  # Only files exposed by the normal free download page; no paid upload IDs.
  r=s.post(u+"/file/"+uid,params={"source":"game_download"},data={"csrf_token":csrf},timeout=45);r.raise_for_status();dl=r.json()
  if "url" not in dl: raise RuntimeError(str(dl))
  dest=d/name
  if not dest.exists():
   with s.get(dl["url"],timeout=(30,90),stream=True) as f:
    f.raise_for_status()
    with dest.open("wb") as out:
     for chunk in f.iter_content(1024*1024):out.write(chunk)
  assert zipfile.is_zipfile(dest)
  extracted=d/"files";extracted.mkdir(exist_ok=True)
  with zipfile.ZipFile(dest) as z:
   err=z.testzip();assert err is None,err
   for member in z.infolist():
    target=(extracted/member.filename).resolve()
    assert target.is_relative_to(extracted.resolve()),member.filename
    assert not member.filename.lower().endswith((".exe",".msi",".bat",".cmd",".ps1",".dll")),member.filename
   z.extractall(extracted)
  record={"id":aid,"title":name.removesuffix(".zip"),"source_url":u,"author":"Quaternius","license":"CC0-1.0","license_url":"https://quaternius.com/license.html","files":[{"path":str(dest.relative_to(BASE)).replace("\\","/"),"download_url":u+"/file/"+uid,"bytes":dest.stat().st_size,"sha256":hashlib.sha256(dest.read_bytes()).hexdigest()}],"status":"downloaded_extracted_pending_inspection","notes":["Standard free release. Original archive retained; source webpage retained. Direct CDN URL is ephemeral; download_url records source upload endpoint."]}
  results.append(record);(BASE/"manifest.json").write_text(json.dumps({"category":"characters","assets":results},ensure_ascii=False,indent=2),encoding="utf8")
  print("DONE",aid,dest.stat().st_size,flush=True)
r=requests.get("https://quaternius.com/license.html",timeout=30);r.raise_for_status();(BASE/"quaternius_license.html").write_text(r.text,encoding="utf8")

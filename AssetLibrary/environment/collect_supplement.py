"""Curated OpenGameArt supplements; no downloaded code is executed."""
import concurrent.futures as cf
import hashlib
import json
from pathlib import Path
import sys
import time
import urllib.request
from urllib.parse import unquote,urlparse
import zipfile

ROOT=Path(__file__).resolve().parent
ITEMS=[
 ('dims-arboretum', "Dim's Arboretum", 'Dim', 'CC-BY-3.0', 'https://creativecommons.org/licenses/by/3.0/',
  'https://opengameart.org/sites/default/files/dims_arboretum.zip',
  'Textured mature conifer/tree, vegetation, logs and props. Blender source pack from 2010; inspect packed texture links and convert to glTF. Attribute Dim, source and CC-BY-3.0; identify modifications.'),
 ('jkms-tree-set', "JKM's tree set", 'Julius (JKM)', 'CC-BY-SA-3.0', 'https://creativecommons.org/licenses/by-sa/3.0/',
  'https://opengameart.org/sites/default/files/jkm_trees.zip',
  'Game-oriented mature pine and deciduous trees with alternate skins, originally made for Quake 3. Selected CC-BY-SA-3.0 from offered license choices. Preserve attribution and share-alike for asset derivatives; check transparency, texture resolution and materials. Useful candidate for mid/far forest, not claimed modern AAA quality.'),
 ('birch-tree', 'Birch Tree', 'AnyRPG; derivative of geekygnome Low Poly Tree', 'CC0-1.0', 'https://creativecommons.org/publicdomain/zero/1.0/',
  'https://opengameart.org/sites/default/files/treebirch.blend',
  'Source page states 1294 vertices / 1776 triangles. Blender source with birch bark; inspect leaf alpha and convert to glTF. Semi-realistic stylized foliage, not a scanned tree.'),
 ('medieval-waterpowered-sawmill', 'Medieval Waterpowered Sawmill', 'Daniel Andersson; submitted by hreikin', 'CC0-1.0', 'https://creativecommons.org/publicdomain/zero/1.0/',
  'https://opengameart.org/sites/default/files/75340_WaterPoweredSawmillUpload_blend.zip',
  'Timber sawmill shed and waterwheel, useful lumberyard source. Blender format; community comment reports animation but animation existence/usefulness must be inspected before promising it. Rework medieval foundation/style for Northeast China setting.'),
 ('retro-log-cabin', 'Retro Log Cabin', 'Elegant Crow', 'CC-BY-SA-4.0', 'https://creativecommons.org/licenses/by-sa/4.0/',
  'https://opengameart.org/sites/default/files/log_cabin.zip',
  'Cabin with interior and independent doors/windows, 1K/4K textures per source. Selected standard page license conservatively despite relaxed attribution note. Preserve attribution and share-alike for asset derivatives. Re-material/repaint to match historical setting.'),
 ('log-cabin-dae', 'Log Cabin (DAE)', 'mixxit', 'CC-BY-3.0', 'https://creativecommons.org/licenses/by/3.0/',
  'https://opengameart.org/sites/default/files/logcabin.zip',
  'Log cabin with internal space in Collada DAE. Convert to glTF; check scale, collision, doors, texture paths. Attribute mixxit, source/license and modifications.'),
 ('modular-building-asset-0', 'Nobiax Modular Building Asset', 'Yughues (Nobiax)', 'CC0-1.0', 'https://creativecommons.org/publicdomain/zero/1.0/',
  'https://opengameart.org/sites/default/files/Free%20Nobiax%20modular%20building%20asset.7z',
  'Industrial walls, roof, door/window/pillar modules. Use structural pieces suitable to the period; exclude modern air-conditioning equipment. Check UVs and apply collected PBR materials where needed.'),
]

def collect(item):
    aid,title,author,lic,licurl,url,notes=item
    folder=ROOT/'supplement'/aid;folder.mkdir(parents=True,exist_ok=True)
    target=folder/Path(unquote(urlparse(url).path)).name
    for attempt in range(3):
        try:
            if not target.exists():
                req=urllib.request.Request(url,headers={'User-Agent':'GameMakeAssetResearch/1.0'})
                with urllib.request.urlopen(req,timeout=90) as res,target.with_suffix(target.suffix+'.part').open('wb') as out:
                    while chunk:=res.read(1024*1024):out.write(chunk)
                target.with_suffix(target.suffix+'.part').replace(target)
            raw=target.read_bytes()
            break
        except Exception:
            if attempt==2:raise
            time.sleep(1+attempt)
    a=dict(id='oga_'+aid,title=title,author=author,license=lic,license_url=licurl,
      source_url='https://opengameart.org/content/'+aid,license_evidence='evidence/oga_'+aid+'.html',
      type='3d_model_pack' if target.suffix in ('.zip','.7z') else '3d_model',
      files=[dict(path=target.relative_to(ROOT).as_posix(),download_url=url,bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())],
      status='downloaded_verified',notes=[notes],archive_contents=[])
    unpack=folder/'extracted'
    if target.suffix=='.zip':
        with zipfile.ZipFile(target) as z:
            bad=z.testzip()
            if bad:raise ValueError('ZIP CRC error: '+bad)
            for info in z.infolist():
                dest=(unpack/info.filename).resolve()
                if not dest.is_relative_to(unpack.resolve()):raise ValueError('Unsafe archive path')
                if ((info.external_attr >> 16) & 0o170000)==0o120000:raise ValueError('Archive symlink')
                if not info.is_dir():a['archive_contents'].append({'path':info.filename,'bytes':info.file_size})
            z.extractall(unpack)
        a['notes'].append('ZIP CRC verified and safely extracted; content is data only and has not been executed.')
    elif target.suffix=='.7z':
        sys.path.insert(0,r'C:\GameMake\tools\asset_python')
        import py7zr
        with py7zr.SevenZipFile(target) as z:
            for info in z.list():
                dest=(unpack/info.filename).resolve()
                if not dest.is_relative_to(unpack.resolve()) or info.is_symlink:
                    raise ValueError('Unsafe 7z path/symlink')
                if not info.is_directory:a['archive_contents'].append({'path':info.filename,'bytes':info.uncompressed})
            z.extractall(unpack)
        a['notes'].append('7z structure checked and safely extracted; downloaded content has not been executed.')
    return a

assets=[]
with cf.ThreadPoolExecutor(max_workers=3) as ex:
    for item in ex.map(collect,ITEMS):
        assets.append(item)
        (ROOT/'supplement_manifest.json').write_text(json.dumps({'category':'environment','assets':assets},ensure_ascii=False,indent=2),encoding='utf-8')
        print(item['id'],sum(f['bytes'] for f in item['files']),len(item['archive_contents']),flush=True)
base=json.loads((ROOT/'manifest.json').read_text(encoding='utf-8'))
base['assets']=[a for a in base['assets'] if not a['id'].startswith('oga_')]+assets
(ROOT/'manifest.json').write_text(json.dumps(base,ensure_ascii=False,indent=2),encoding='utf-8')
print('SUPPLEMENT_COMPLETE',len(assets),sum(f['bytes'] for a in assets for f in a['files']))

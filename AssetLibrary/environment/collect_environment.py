"""Download an explicit, curated Poly Haven set using its documented public API.
This locally written script never executes downloaded content.
"""
import concurrent.futures as cf
import hashlib
import json
from pathlib import Path
import sys
import time
import urllib.request
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parent
EVIDENCE = ROOT / 'evidence'
UA = 'GameMakeAssetResearch/1.0 (personal historical FPS prototype)'
MODELS = ['dead_tree_trunk', 'tree_stump_01', 'pine_roots', 'fern_02',
          'rock_moss_set_01', 'rock_07', 'wooden_crate_01', 'old_military_crate',
          'wooden_military_crate', 'wine_barrel_01', 'wooden_bucket_01',
          'wooden_ladder', 'wooden_axe_02', 'handsaw_wood', 'Lantern_01',
          'WoodenTable_01', 'wooden_stool_01', 'wooden_bookshelf_worn',
          'barrel_stove', 'modular_wooden_pier', 'pine_sapling_small',
          'vintage_radio_transceiver']
TEXTURES = ['brown_mud_leaves_01', 'forest_ground_04', 'muddy_tracks',
            'pine_bark', 'japanese_cedar_bark', 'wood_trunk_wall',
            'weathered_brown_planks', 'raw_plank_wall', 'wood_chips',
            'grey_roof_tiles', 'brick_wall_001', 'rusty_metal_04',
            'gravel_road', 'snow_02']
HDRIS = ['kloofendal_overcast_puresky', 'autumn_forest_01']

def request(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers={
        'User-Agent': UA, 'Referer': 'https://polyhaven.com/'}), timeout=90)

def json_get(url, local):
    if local.exists():
        return json.loads(local.read_text(encoding='utf-8-sig'))
    for attempt in range(3):
        try:
            with request(url) as res:
                raw = res.read()
            data = json.loads(raw)
            local.parent.mkdir(parents=True, exist_ok=True)
            local.write_bytes(raw)
            return data
        except Exception:
            if attempt == 2:
                raise
            time.sleep(1 + attempt)

def plan_asset(item):
    kind, aid = item
    cat = json.loads((EVIDENCE / (kind + '_catalog.json')).read_text(encoding='utf-8-sig'))
    meta = cat[aid]
    data = json_get('https://api.polyhaven.com/files/' + aid, EVIDENCE / (aid + '_files.json'))
    (EVIDENCE / (aid + '_metadata.json')).write_text(json.dumps(meta, ensure_ascii=False, indent=2), encoding='utf-8')
    a = dict(id='polyhaven_' + aid, title=meta['name'], source_url='https://polyhaven.com/a/' + aid,
             author=', '.join(meta.get('authors', {})), license='CC0-1.0',
             license_url='https://polyhaven.com/license',
             license_evidence='evidence/polyhaven_license.html',
             metadata_evidence='evidence/' + aid + '_metadata.json',
             file_catalog_evidence='evidence/' + aid + '_files.json',
             type={'models':'3d_model','textures':'pbr_texture_set','hdris':'hdri'}[kind],
             polycount=meta.get('polycount'), files=[], status='planned', notes=[])
    folder = ROOT / kind / aid
    if kind == 'models':
        model = data.get('gltf', {}).get('2k', {}).get('gltf')
        if not model:
            a['status']='unavailable_gltf'
            a['notes']=['2k glTF unavailable; not downloaded.']
            return a
        selected = [(Path(urlparse(model['url']).path).name, model)] + list(model.get('include', {}).items())
        a['notes']=['glTF 2.0 with all API-listed buffers and textures. Godot supports glTF import; collision, LOD, placement and material tuning remain.']
        if meta.get('polycount',0) > 100000:
            a['notes'].append('High polygon source asset: decimation/LOD or baking is required before dense realtime placement.')
        if aid in ('wooden_military_crate','old_military_crate'):
            a['notes'].append('Check and repaint printed labels/markings for the 1930s Northeast China setting.')
        if aid == 'pine_sapling_small':
            a['notes'].append('Small sapling; does not replace a mature forest tree set. Need mature pine/birch models and wind setup.')
        if aid == 'vintage_radio_transceiver':
            a['notes'].append('WW2-style field radio: useful for the telegraph room; specific model/year and army markings need historical review or repainting.')
    elif kind == 'textures':
        selected=[]
        for channel in ['Diffuse','nor_gl','Rough','AO','Metal','Displacement']:
            variants=data.get(channel,{}).get('2k',{})
            chosen=variants.get('jpg') or variants.get('png')
            if chosen:
                selected.append((Path(urlparse(chosen['url']).path).name,chosen))
        a['notes']=['2k PBR maps; OpenGL normal selected for Godot. Albedo uses sRGB; roughness, normal, AO and height are data maps. Map scale and material assignment remain.']
    else:
        chosen=data.get('hdri',{}).get('2k',{}).get('hdr')
        if not chosen:
            chosen=data.get('hdri',{}).get('2k',{}).get('exr')
        selected=[(Path(urlparse(chosen['url']).path).name,chosen)]
        a['notes']=['2k HDR environment; import into Godot PanoramaSkyMaterial and tune exposure. Forest panorama is lighting/reference, not playable geometry.']
    for rel,f in selected:
        target=(folder/rel).resolve()
        if not target.is_relative_to(ROOT.resolve()):
            raise ValueError('Unsafe server path')
        a['files'].append(dict(path=target.relative_to(ROOT).as_posix(), download_url=f['url'],
                               expected_bytes=f['size'], expected_md5=f.get('md5')))
    return a

def download_file(f):
    path=ROOT/f['path']
    path.parent.mkdir(parents=True,exist_ok=True)
    for attempt in range(3):
        try:
            if not path.exists() or path.stat().st_size != f['expected_bytes']:
                with request(f['download_url']) as response, path.with_suffix(path.suffix+'.part').open('wb') as out:
                    while chunk:=response.read(1024*1024):
                        out.write(chunk)
                path.with_suffix(path.suffix+'.part').replace(path)
            raw=path.read_bytes()
            if len(raw)!=f['expected_bytes']:
                raise ValueError(f'Expected {f["expected_bytes"]}, got {len(raw)} bytes')
            md5=hashlib.md5(raw).hexdigest()
            if f.get('expected_md5') and md5 != f['expected_md5']:
                raise ValueError('Provider MD5 mismatch')
            f.update(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest(),status='downloaded_verified')
            return f
        except Exception as e:
            if attempt==2:
                f.update(status='download_failed',error=str(e))
                return f
            time.sleep(1+attempt)

def main():
    if '--plan' in sys.argv:
        items=[(kind,a) for kind,ids in [('models',MODELS),('textures',TEXTURES),('hdris',HDRIS)] for a in ids]
        assets=[]
        with cf.ThreadPoolExecutor(max_workers=3) as ex:
            for a in ex.map(plan_asset,items):
                assets.append(a)
                print(a['id'],a['status'],len(a['files']),sum(f['expected_bytes'] for f in a['files']),flush=True)
        (ROOT/'download_plan.json').write_text(json.dumps({'category':'environment','assets':assets},ensure_ascii=False,indent=2),encoding='utf-8')
        print('TOTAL_BYTES',sum(f['expected_bytes'] for a in assets for f in a['files']))
    elif '--download' in sys.argv:
        data=json.loads((ROOT/'download_plan.json').read_text(encoding='utf-8'))
        for a in data['assets']:
            with cf.ThreadPoolExecutor(max_workers=3) as ex:
                a['files']=list(ex.map(download_file,a['files']))
            if a['files']:
                a['status']='downloaded_verified' if all(f['status']=='downloaded_verified' for f in a['files']) else 'incomplete'
            (ROOT/'manifest.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
            print(a['id'],a['status'],sum(f.get('bytes',0) for f in a['files']),flush=True)
        print('COMPLETE',len(data['assets']),sum(f.get('bytes',0) for a in data['assets'] for f in a['files']))

if __name__=='__main__':
    main()

"""Copy only selected environment sources into the playable prototype."""
import hashlib
import json
from pathlib import Path
import shutil

source=Path(__file__).resolve().parent
dest=Path(r'C:\GameMake\GodotProject\assets\environment')
models=['dead_tree_trunk','tree_stump_01','rock_moss_set_01','wooden_crate_01',
        'wine_barrel_01','Lantern_01','WoodenTable_01','wooden_axe_02',
        'vintage_radio_transceiver','wooden_bucket_01','fern_02','pine_sapling_small']
textures=['brown_mud_leaves_01','forest_ground_04','muddy_tracks','weathered_brown_planks',
          'brick_wall_001','grey_roof_tiles','pine_bark','rusty_metal_04']
manifest=json.loads((source/'manifest.json').read_text(encoding='utf-8'))
selected=[]
for a in manifest['assets']:
    aid=a['id'].removeprefix('polyhaven_')
    if aid not in models+textures+['kloofendal_overcast_puresky']:
        continue
    entry={k:a[k] for k in ['id','title','author','source_url','license','license_url']}
    entry['files']=[]
    for f in a['files']:
        if aid in textures and not any(t in Path(f['path']).name for t in ['_diff_2k.jpg','_diffuse_2k.jpg','_nor_gl_2k.jpg','_rough_2k.jpg']):
            continue
        target=dest/f['path']
        target.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(source/f['path'],target)
        entry['files'].append({'source_library_path':f['path'],'game_path':target.relative_to(dest.parent.parent).as_posix(),
                               'bytes':target.stat().st_size,'sha256':hashlib.sha256(target.read_bytes()).hexdigest()})
    selected.append(entry)
dest.mkdir(parents=True,exist_ok=True)
(dest/'sources.json').write_text(json.dumps({'category':'environment_v04','assets':selected},ensure_ascii=False,indent=2),encoding='utf-8')
shutil.copy2(source/'evidence/CC0-1.0.txt',dest/'CC0-1.0.txt')
print('ASSETS',len(selected),'FILES',sum(len(a['files']) for a in selected),'BYTES',sum(f['bytes'] for a in selected for f in a['files']))

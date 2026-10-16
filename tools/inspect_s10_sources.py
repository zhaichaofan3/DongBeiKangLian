import bpy, json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'docs/level/S10'
OUT.mkdir(parents=True,exist_ok=True)
BATCH=ROOT/'AssetLibrary/environment/china_northeast_20261013/models'
SOURCES={
 'D01': BATCH/'log_cabin_scene/log_cabin_scene.glb',
 'D02': ROOT/'AssetLibrary/environment/supplement/retro-log-cabin/extracted/log_cabin/log_cabin.fbx',
 'D03': BATCH/'warehouse/warehouse.glb',
 'D04': BATCH/'modular_factory_facade/modular_factory_facade_2k.gltf',
 'D05': ROOT/'AssetLibrary/environment/supplement/medieval-waterpowered-sawmill/extracted/WaterPoweredSawmillUpload.blend'}
result={}
for key,path in SOURCES.items():
 bpy.ops.wm.read_factory_settings(use_empty=True)
 if path.suffix=='.blend': bpy.ops.wm.open_mainfile(filepath=str(path))
 elif path.suffix=='.fbx': bpy.ops.import_scene.fbx(filepath=str(path))
 else: bpy.ops.import_scene.gltf(filepath=str(path))
 objects=[]
 for ob in bpy.context.scene.objects:
  if ob.type!='MESH': continue
  pts=[ob.matrix_world@Vector(c) for c in ob.bound_box]
  lo=[min(p[i] for p in pts) for i in range(3)]
  hi=[max(p[i] for p in pts) for i in range(3)]
  objects.append(dict(name=ob.name,low=lo,high=hi,dimensions=[hi[i]-lo[i] for i in range(3)],triangles=sum(len(p.vertices)-2 for p in ob.data.polygons),materials=[s.material.name if s.material else '' for s in ob.material_slots]))
 result[key]=dict(source=path.relative_to(ROOT).as_posix(),objects=objects,images=[dict(name=i.name,path=i.filepath,packed=bool(i.packed_file),size=list(i.size)) for i in bpy.data.images if i.type!='RENDER_RESULT'])
 print(key,len(objects),'objects',sum(o['triangles'] for o in objects),'triangles')
(OUT/'source_inspection.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')

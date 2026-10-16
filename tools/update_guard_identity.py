"""Incrementally update the editable Blender source and export its original rig."""
from pathlib import Path
import sys,json,hashlib
import bpy

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from guard_identity_geometry import add_guard_identity

source=ROOT/'AssetLibrary/characters/field_character'
output=ROOT/'GodotProject/assets/characters'
bpy.ops.wm.open_mainfile(filepath=str(source/'field_character.blend'))
arm=bpy.data.objects['FieldRig']
add_guard_identity(arm)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.wm.save_as_mainfile(filepath=str(source/'field_character.blend'))
bpy.ops.export_scene.gltf(filepath=str(output/'field_character.glb'),export_format='GLB',use_selection=True,
    export_animations=False,export_yup=True,export_apply=False,export_cameras=False,export_lights=False)
report=json.loads((output/'provenance.json').read_text(encoding='utf-8-sig'))
meshes=[]
for ob in bpy.context.scene.objects:
    if ob.type=='MESH':
        ob.data.calc_loop_triangles()
        meshes.append(dict(name=ob.name,vertices=len(ob.data.vertices),triangles=len(ob.data.loop_triangles)))
report.update(meshes=meshes,all_variant_triangles=sum(m['triangles'] for m in meshes),
    sha256=hashlib.sha256((output/'field_character.glb').read_bytes()).hexdigest(),
    identity_revision=dict(date='2026-10-15',request='User-requested guard-only red helmet circle and parted moustache',
        head_bone_weight=1.0,helmet_ring_outer_diameter_m=.062,helmet_ring_stroke_m=.006,
        new_triangles=448,source='tools/guard_identity_geometry.py'))
for p in [output/'provenance.json',source/'build-report.json']:
    p.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('GUARD_IDENTITY_EXPORTED',report['sha256'])

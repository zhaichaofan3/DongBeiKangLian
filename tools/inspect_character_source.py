import bpy, json
from pathlib import Path
from mathutils import Vector

root = Path(__file__).resolve().parents[1]
source = next((root/'AssetLibrary/characters/quaternius_base_characters').rglob('Superhero_Male_FullBody.gltf'))
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(source))
info=[]
for ob in bpy.context.scene.objects:
    item={'name':ob.name,'type':ob.type,'location':list(ob.location),'rotation':list(ob.rotation_euler),'scale':list(ob.scale)}
    if ob.type=='MESH':
        pts=[ob.matrix_world@v.co for v in ob.data.vertices]
        item.update(vertices=len(pts),materials=[m.name for m in ob.data.materials],bounds=[[min(p[i] for p in pts),max(p[i] for p in pts)] for i in range(3)])
        if ob.name.startswith('SuperHero'):
            for vg_name in ['Head','neck_01']:
                vg=ob.vertex_groups.get(vg_name)
                for limit in [.05,.5,.9]:
                    chosen=[v.co for v in ob.data.vertices if any(g.group==vg.index and g.weight>limit for g in v.groups)]
                    print(vg_name,limit,[[min(p[i] for p in chosen),max(p[i] for p in chosen)] for i in range(3)])
    if ob.type=='ARMATURE':
        item['bones']=[{'name':b.name,'head':list(ob.matrix_world@b.head_local),'tail':list(ob.matrix_world@b.tail_local)} for b in ob.data.bones]
    info.append(item)
out=root/'tools/blender-verification/character-source.json'
out.write_text(json.dumps(info,indent=2),encoding='utf-8')
print('SOURCE_INSPECTED',out)

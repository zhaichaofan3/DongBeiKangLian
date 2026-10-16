"""Blender offline adaptation of the existing JKM pine; preserve original source."""
import bpy
from pathlib import Path
import json
import hashlib
import shutil

ROOT = Path('C:/GameMake')
SOURCE = ROOT / 'AssetLibrary/environment/supplement/jkms-tree-set/extracted'
EDIT = ROOT / 'AssetLibrary/environment/derived/S12'
GAME = ROOT / 'GodotProject/assets/environment/landscape'
EDIT.mkdir(parents=True, exist_ok=True)
GAME.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.wm.obj_import(filepath=str(SOURCE / 'models/pinetree.obj'))
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
objects = [o for o in bpy.context.scene.objects if o.type == 'MESH']
lower = min((o.matrix_world @ v.co).z for o in objects for v in o.data.vertices)
upper = max((o.matrix_world @ v.co).z for o in objects for v in o.data.vertices)
# OBJ importer uses Y-up input and maps height to Blender Z.
scale = 10.0 / (upper - lower)
for obj in objects:
    for vertex in obj.data.vertices:
        vertex.co.z -= lower
        vertex.co *= scale
    for slot in obj.material_slots:
        original = slot.material.name if slot.material else ''
        leaf = 'nadel' in original
        material = bpy.data.materials.new('S12_PineNeedles' if leaf else 'S12_PineTrunk')
        material.use_nodes = True
        shader = material.node_tree.nodes.get('Principled BSDF')
        shader.inputs['Roughness'].default_value = 0.95
        texture = material.node_tree.nodes.new('ShaderNodeTexImage')
        texture.image = bpy.data.images.load(str(SOURCE / ('models/nadel.tga' if leaf else 'models/stamm.jpg')))
        material.node_tree.links.new(texture.outputs['Color'], shader.inputs['Base Color'])
        if leaf:
            material.node_tree.links.new(texture.outputs['Alpha'], shader.inputs['Alpha'])
            material.surface_render_method = 'DITHERED'
            material.use_backface_culling = False
        slot.material = material
    obj.name = 'S12_JKM_far_pine'
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(EDIT / 'far_pine.blend'))
bpy.ops.export_scene.gltf(filepath=str(GAME / 'far_pine.glb'), export_format='GLB', export_materials='EXPORT')
for asset in ['gravel_road', 'wood_chips']:
    target = ROOT / 'GodotProject/assets/environment/textures' / asset
    target.mkdir(exist_ok=True)
    for suffix in ['_diff_2k.jpg', '_nor_gl_2k.jpg', '_rough_2k.jpg']:
        file = ROOT / 'AssetLibrary/environment/textures' / asset / (asset + suffix)
        if not file.is_file():
            raise FileNotFoundError(file)
        shutil.copyfile(file, target / file.name)
shutil.copyfile(SOURCE / 'gpl.txt', GAME / 'JKM-GPL.txt')
shutil.copyfile(SOURCE / 'jkm_trees.txt', GAME / 'JKM-README.txt')
paths = [SOURCE / 'models/pinetree.obj', SOURCE / 'models/nadel.tga', SOURCE / 'models/stamm.jpg', EDIT / 'far_pine.blend', GAME / 'far_pine.glb']
report = {'source': 'Existing JKM tree set, GPL as included with original package; no new download', 'purpose': 'Distant forest only, shared mesh instancing; authored material bindings replace missing MTL', 'height_m': 10, 'vertices': sum(len(o.data.vertices) for o in objects), 'triangles': sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in objects), 'files': [{'path': p.relative_to(ROOT).as_posix(), 'bytes': p.stat().st_size, 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in paths]}
(EDIT / 'manifest.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print(json.dumps(report, ensure_ascii=False))

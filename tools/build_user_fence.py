"""Adapt the supplied wooden barbed-wire obstacle, preserving its original."""
import hashlib
import json
from pathlib import Path

import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / 'AssetLibrary/environment/user_expansion_20261015/imported'
bpy.ops.wm.open_mainfile(filepath=str(DOC / 'fence/raw-import.blend'))
objects = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
points = [obj.matrix_world @ vertex.co for obj in objects for vertex in obj.data.vertices]
low = Vector([min(point[i] for point in points) for i in range(3)])
high = Vector([max(point[i] for point in points) for i in range(3)])
origin = Vector(((low.x + high.x) / 2, (low.y + high.y) / 2, low.z))
scale = .8 / (high.z - low.z)
factor = Vector((scale, scale, scale))
dimensions = (high - low) * scale
for obj in objects:
    placement = obj.matrix_world.copy()
    obj.parent = None
    obj.data = obj.data.copy()
    for vertex in obj.data.vertices:
        point = placement @ vertex.co - origin
        vertex.co = [point[i] * factor[i] for i in range(3)]
    obj.matrix_world = Matrix.Identity(4)
    obj.animation_data_clear()
    obj.name = 'SuppliedBarbedWire'
    for material in obj.data.materials:
        if material and material.use_nodes:
            for node in material.node_tree.nodes:
                if node.type == 'TEX_IMAGE' and node.image and node.image.has_data:
                    node.image.pack()
editable = ROOT / 'AssetLibrary/derived/user_expansion_20261015/barbed_wire.blend'
output = ROOT / 'GodotProject/assets/user_expansion_20261015/barbed_wire.glb'
bpy.ops.wm.save_as_mainfile(filepath=str(editable))
bpy.ops.export_scene.gltf(filepath=str(output), export_format='GLB', export_animations=False,
                          export_cameras=False, export_lights=False, export_yup=True)
record = dict(id='barbed_wire', source='AssetLibrary/environment/user_expansion_20261015/fence/original.rar',
              editable=editable.relative_to(ROOT).as_posix(), game_model=output.relative_to(ROOT).as_posix(),
              dimensions_m=dict(width=dimensions.x, height=dimensions.z, depth=dimensions.y),
              triangles=sum(len(obj.data.polygons) for obj in objects),
              sha256=hashlib.file_digest(output.open('rb'), 'sha256').hexdigest(),
              notes='Original retained. Uniformly scaled to 0.8 m thigh height; used only at side alleys. Original opaque walls remain. Collision matches the low visible envelope.')
(DOC / 'fence-build-manifest.json').write_text(json.dumps(record, indent=2) + '\n', encoding='utf-8')
print('USER_FENCE_BUILD_COMPLETE', record['sha256'])

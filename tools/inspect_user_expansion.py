"""Import supplied scenery and rifle for measured adaptation and visual review."""
import bpy
import hashlib
import importlib.util
import json
import math
import sys
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / 'AssetLibrary/environment/user_expansion_20261015'
DOC = ROOT / 'docs/expansion_20261015'
spec = importlib.util.spec_from_file_location('expansion_max', ROOT / 'tools/third_party/max_importer/io_scene_max-main/source/import_max.py')
importer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(importer)
original_bitmap = importer.get_bitmap


def bitmap(chunk, visited=None):
    if chunk is None:
        return None
    visited = set() if visited is None else visited
    if id(chunk) in visited or len(visited) > 80:
        return None
    visited.add(id(chunk))
    try:
        result = original_bitmap(chunk)
        if result:
            return result
    except (IndexError, AttributeError, TypeError):
        pass
    for ref in importer.get_references(chunk) + list(importer.get_reference(chunk).values()):
        result = bitmap(ref, visited)
        if result:
            return result
    return None


importer.get_bitmap = bitmap


def bounds(objects):
    pts = [ob.matrix_world @ Vector(p) for ob in objects for p in ob.bound_box]
    return [min(p[i] for p in pts) for i in range(3)], [max(p[i] for p in pts) for i in range(3)]


def preview(objects, out):
    low, high = map(Vector, bounds(objects))
    center = (low + high) / 2
    size = max(high - low)
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 8
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = 1200, 900
    scene.render.resolution_percentage = 100
    scene.world = bpy.data.worlds.new('InspectionWorld')
    scene.world.use_nodes = True
    background = next(n for n in scene.world.node_tree.nodes if n.type == 'BACKGROUND')
    background.inputs[0].default_value = (.42, .48, .52, 1)
    background.inputs[1].default_value = .8
    light = bpy.data.objects.new('ReviewSun', bpy.data.lights.new('ReviewSun', 'SUN'))
    scene.collection.objects.link(light)
    light.data.energy = 2
    light.rotation_euler = (.45, -.5, -.5)
    data = bpy.data.cameras.new('ReviewCamera')
    data.type = 'ORTHO'
    data.ortho_scale = size * 1.35
    data.clip_end = size * 12
    camera = bpy.data.objects.new('ReviewCamera', data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    for name, direction in [('overview', (1, -1.5, 1.2)), ('top', (0, -.001, 2))]:
        camera.location = center + Vector(direction) * size
        camera.rotation_euler = (center - camera.location).to_track_quat('-Z', 'Y').to_euler()
        scene.render.filepath = str(out / (name + '.png'))
        bpy.ops.render.render(write_still=True)


roles = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else ['rifle', 'office', 'camp', 'village']
roles = [role for role in roles if not role.startswith('--')]
for role in roles:
    out = DOC / role
    out.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    folder = LIB / role
    source = next(p for p in folder.iterdir() if p.suffix.lower() in ['.max', '.fbx'])
    if '--preview-only' in sys.argv:
        bpy.ops.wm.open_mainfile(filepath=str(out / 'raw-import.blend'))
    elif source.suffix.lower() == '.fbx':
        bpy.ops.import_scene.fbx(filepath=str(source))
    else:
        importer.load(None, bpy.context, filepath=str(source), object_filter={'MATERIAL', 'UV', 'PRIMITIVE', 'EMPTY'})
    bpy.context.view_layer.update()
    meshes = [ob for ob in bpy.context.scene.objects if ob.type == 'MESH' and len(ob.data.vertices)]
    rows = []
    for ob in meshes:
        ob.data.calc_loop_triangles()
        rows.append({'name': ob.name, 'bounds': bounds([ob]), 'triangles': len(ob.data.loop_triangles),
                     'materials': [m.name if m else None for m in ob.data.materials]})
    report = {'source': source.relative_to(ROOT).as_posix(), 'sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
              'bounds': bounds(meshes), 'objects': rows, 'triangles': sum(r['triangles'] for r in rows),
              'images': [{'name': im.name, 'path': im.filepath, 'size': list(im.size)} for im in bpy.data.images],
              'materials': [{'name': m.name, 'color': list(m.diffuse_color),
                             'images': [n.image.name for n in m.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image] if m.use_nodes else []} for m in bpy.data.materials]}
    (out / 'inspection.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    for im in bpy.data.images:
        if im.has_data:
            im.pack()
    bpy.ops.wm.save_as_mainfile(filepath=str(out / 'raw-import.blend'))
    print('EXPANSION_IMPORT', role, len(meshes), report['triangles'], report['bounds'], flush=True)
    preview(meshes, out)

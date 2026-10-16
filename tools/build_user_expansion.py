"""Create measured runtime GLBs, preserving supplied editable sources."""
import bpy
import bmesh
import hashlib
import json
from pathlib import Path
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / 'AssetLibrary/environment/user_expansion_20261015/imported'
SOURCE = ROOT / 'AssetLibrary/derived/user_expansion_20261015'
OUT = ROOT / 'GodotProject/assets/user_expansion_20261015'
SOURCE.mkdir(parents=True, exist_ok=True)
OUT.mkdir(parents=True, exist_ok=True)
records = []


def meshes():
    return [o for o in bpy.context.scene.objects if o.type == 'MESH' and len(o.data.vertices)]


def open_role(role):
    bpy.ops.wm.open_mainfile(filepath=str(DOC / role / 'raw-import.blend'))
    for ob in list(bpy.context.scene.objects):
        if ob.type != 'MESH':
            bpy.data.objects.remove(ob, do_unlink=True)
    for ob in meshes():
        matrix = ob.matrix_world.copy()
        ob.parent = None
        ob.data = ob.data.copy()
        ob.data.transform(matrix)
        ob.matrix_world = Matrix.Identity(4)
        ob.animation_data_clear()
        ob.modifiers.clear()


def bounds(objects):
    pts = [v.co for ob in objects for v in ob.data.vertices]
    return Vector([min(p[i] for p in pts) for i in range(3)]), Vector([max(p[i] for p in pts) for i in range(3)])


def finish(name, role, notes):
    bpy.data.orphans_purge(do_local_ids=True, do_linked_ids=False, do_recursive=True)
    used = {mat for ob in meshes() for mat in ob.data.materials if mat}
    for mat in used:
        mat.use_nodes = True
        bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
        bsdf.inputs['Roughness'].default_value = .78 if role != 'rifle' else .55
        bsdf.inputs['Alpha'].default_value = 1
        for link in list(mat.node_tree.links):
            if link.to_socket == bsdf.inputs['Alpha']:
                mat.node_tree.links.remove(link)
        for node in mat.node_tree.nodes:
            if node.type == 'TEX_IMAGE' and node.image and node.image.has_data:
                im = node.image
                if max(im.size) > 2048:
                    factor = 2048 / max(im.size)
                    im.scale(max(1, int(im.size[0] * factor)), max(1, int(im.size[1] * factor)))
                im.pack()
    low, high = bounds(meshes())
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / (name + '.blend')))
    bpy.ops.export_scene.gltf(filepath=str(OUT / (name + '.glb')), export_format='GLB',
                              export_animations=False, export_cameras=False, export_lights=False,
                              export_image_format='JPEG', export_image_quality=88, export_yup=True)
    triangles = 0
    for ob in meshes():
        ob.data.calc_loop_triangles()
        triangles += len(ob.data.loop_triangles)
    records.append({'id': name, 'source_role': role, 'notes': notes,
                    'bounds_blender': [list(low), list(high)], 'triangles': triangles,
                    'sha256': hashlib.sha256((OUT / (name + '.glb')).read_bytes()).hexdigest()})


open_role('rifle')
# Native muzzle is at -Y. Align the bore to the existing hands and muzzle socket.
bolt_ids = ['c04938e8', '801b6df7', 'bae2fd78']
clip_ids = ['c78028de', '88822d87']
for ob in meshes():
    category = 'Bolt' if any(ob.name.startswith(p) for p in bolt_ids) else 'Clip' if any(ob.name.startswith(p) for p in clip_ids) else 'Body'
    for vertex in ob.data.vertices:
        p = vertex.co.copy()
        game = Vector(((p.x - 1.27) * .0105, (p.z - 3.1) * .0105 + .044, p.y * .0105 - .145))
        if category == 'Clip':
            game -= Vector((0, .098, -.022))
        vertex.co = (game.x, -game.z, game.y)
    ob.name = category + '_' + ob.name[:8]
finish('kar98k', 'rifle', 'Supplied textured receiver, stock, bore, independent bolt and stripper clip; existing player hands retained.')

open_role('office')
for ob in meshes():
    for v in ob.data.vertices:
        p = v.co.copy()
        v.co = (p.x * (26 / 625.8588), (p.y - 206.083) * (24 / 890.9361), max(-.025, (p.z + .885) * .029))
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    remove = []
    for face in bm.faces:
        center = face.calc_center_median()
        # West entry and a broad opening through the hall divider.
        doorway = center.x < -11.8 and -4.3 < center.y < .3 and center.z < 3.05
        divider = abs(center.x) < 5.4 and abs(center.y) < 1.6 and center.z < 3.05
        if doorway or divider:
            remove.append(face)
    bmesh.ops.delete(bm, geom=remove, context='FACES')
    bm.to_mesh(ob.data)
    bm.free()
    ob.name = 'SuppliedTelegraphOffice'
finish('office', 'office', '26 x 24 m double arched shell; opened west access and central indoor passage; runtime collision follows the shell and mission anchors move inside.')

for index in range(4):
    open_role('camp')
    selected = sorted([o for o in meshes() if len(o.data.polygons) > 10], key=lambda o: o.name)[index]
    for ob in list(meshes()):
        if ob != selected:
            bpy.data.objects.remove(ob, do_unlink=True)
    low, high = bounds([selected])
    target_height = [5.2, 3.5, 5.4, 4.4][index]
    scale = target_height / (high.z - low.z)
    origin = Vector(((low.x + high.x)/2, (low.y + high.y)/2, low.z))
    for v in selected.data.vertices:
        v.co = (v.co - origin) * scale
    selected.name = 'SuppliedLoggingHouse%d' % (index + 1)
    finish('camp_%d' % (index + 1), 'camp', 'Independent supplied house, grounded and uniformly scaled; runtime coarse collision preserves the route.')

# Extract complete textured courtyard buildings; discard the giant tiled preview ground,
# modern clutter, dense duplicate furniture and unused distant copies.
village_ids = ['Obj3d66-691775-387-726', 'Obj3d66-691775-388-812',
               'Obj3d66-691775-488-171', 'Obj3d66-691775-564-115']
for index, identifier in enumerate(village_ids):
    open_role('village')
    selected = bpy.data.objects[identifier]
    for ob in list(meshes()):
        if ob != selected:
            bpy.data.objects.remove(ob, do_unlink=True)
    low, high = bounds([selected])
    origin = Vector(((low.x + high.x)/2, (low.y + high.y)/2, low.z))
    for v in selected.data.vertices:
        v.co = (v.co - origin) * .01
    selected.name = 'SuppliedNortheastCourtyard%d' % (index + 1)
    finish('village_%d' % (index + 1), 'village', 'Complete supplied courtyard geometry at centimetres-to-metres scale; other source items retained as unused originals.')

(DOC / 'build-manifest.json').write_text(json.dumps(records, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('USER_EXPANSION_BUILD_COMPLETE', len(records), flush=True)

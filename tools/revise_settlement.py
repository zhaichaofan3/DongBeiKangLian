"""Inspect and adapt supplied scenery without changing the archived sources."""
import bpy
import bmesh
import numpy as np
import json
import sys
from pathlib import Path
from mathutils import Vector, Matrix

ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / 'docs/settlement_revision_20261015'
DOC.mkdir(parents=True, exist_ok=True)


def open_baked(path):
    bpy.ops.wm.open_mainfile(filepath=str(path))
    for ob in list(bpy.context.scene.objects):
        if ob.type != 'MESH':
            bpy.data.objects.remove(ob, do_unlink=True)
            continue
        matrix = ob.matrix_world.copy()
        ob.parent = None
        ob.data = ob.data.copy()
        ob.data.transform(matrix)
        ob.matrix_world = Matrix.Identity(4)


def mesh_objects():
    return [o for o in bpy.context.scene.objects if o.type == 'MESH']


def bounds(ob):
    points = [v.co for v in ob.data.vertices]
    return (Vector([min(p[i] for p in points) for i in range(3)]),
            Vector([max(p[i] for p in points) for i in range(3)]))


def camera_render(name, center, location, scale):
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 8
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = 1600, 1600
    scene.render.resolution_percentage = 100
    scene.world = bpy.data.worlds.new('ReviewWorld')
    scene.world.use_nodes = True
    background = next(n for n in scene.world.node_tree.nodes if n.type == 'BACKGROUND')
    background.inputs[0].default_value = (.42, .47, .5, 1)
    background.inputs[1].default_value = .7
    light = bpy.data.objects.new('ReviewSun', bpy.data.lights.new('ReviewSun', 'SUN'))
    scene.collection.objects.link(light)
    light.data.energy = 2
    light.rotation_euler = (.45, -.5, -.5)
    camera = bpy.data.objects.new('ReviewCamera', bpy.data.cameras.new('ReviewCamera'))
    scene.collection.objects.link(camera)
    camera.data.type = 'ORTHO'
    camera.data.ortho_scale = scale
    camera.data.clip_end = 2000
    camera.location = location
    camera.rotation_euler = (Vector(center) - camera.location).to_track_quat('-Z', 'Y').to_euler()
    scene.camera = camera
    scene.render.filepath = str(DOC / (name + '.png'))
    bpy.ops.render.render(write_still=True)


def settlement():
    open_baked(ROOT / 'AssetLibrary/environment/user_expansion_20261015/imported/village/raw-import.blend')
    kept, omitted = [], []
    for ob in mesh_objects():
        low, high = bounds(ob)
        center = (low + high) / 2
        number = int(ob.name.split('-')[-2])
        # The package includes a tiled presentation plane, utility poles and
        # detached demonstration copies. Retain the complete main settlement.
        reason = ''
        if number <= 339:
            reason = 'modern_power_distribution'
        elif high.x - low.x > 30000:
            reason = 'presentation_ground'
        elif not (-10000 < center.x < 17000 and -10500 < center.y < 17000):
            reason = 'detached_sample_outside_main_settlement'
        if reason:
            omitted.append({'name': ob.name, 'reason': reason})
            bpy.data.objects.remove(ob, do_unlink=True)
            continue
        kept.append({'name': ob.name, 'bounds_cm': [list(low), list(high)]})
        for vertex in ob.data.vertices:
            vertex.co *= .01
        ob.name = 'VillageSource_' + ob.name
        if number == 1535:
            bark = bpy.data.materials.new('OriginalVillageWinterTreeBark')
            bark.diffuse_color = (.22, .19, .14, 1)
            bark.use_nodes = True
            shader = next(n for n in bark.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
            shader.inputs['Base Color'].default_value = bark.diffuse_color
            shader.inputs['Roughness'].default_value = 1
            ob.data.materials.clear()
            ob.data.materials.append(bark)
            for face in ob.data.polygons:
                face.material_index = 0
        if len(ob.data.polygons) > 60000:
            modifier = ob.modifiers.new('TreeRuntimeReduction', 'DECIMATE')
            modifier.ratio = .15
            bpy.context.view_layer.objects.active = ob
            bpy.ops.object.modifier_apply(modifier=modifier.name)
    bpy.ops.object.select_all(action='DESELECT')
    for ob in mesh_objects():
        ob.select_set(True)
    bpy.context.view_layer.objects.active = mesh_objects()[0]
    bpy.ops.object.join()
    bpy.context.object.name = 'OriginalNortheastSettlement'
    for mat in bpy.data.materials:
        if not mat.use_nodes:
            continue
        bsdf = next((n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
        if bsdf:
            bsdf.inputs['Roughness'].default_value = .9
            bsdf.inputs['Alpha'].default_value = 1
        for n in mat.node_tree.nodes:
            if n.type == 'TEX_IMAGE' and n.image and n.image.size[0] and len(n.image.pixels):
                if max(n.image.size) > 2048:
                    factor = 2048 / max(n.image.size)
                    n.image.scale(int(n.image.size[0] * factor), int(n.image.size[1] * factor))
                n.image.pack()
    bpy.data.orphans_purge(do_local_ids=True, do_linked_ids=False, do_recursive=True)
    source = ROOT / 'AssetLibrary/derived/user_expansion_20261015/village_complete.blend'
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    bpy.ops.export_scene.gltf(filepath=str(ROOT / 'GodotProject/assets/user_expansion_20261015/village_complete.glb'),
                              export_format='GLB', export_animations=False, export_cameras=False,
                              export_lights=False, export_image_format='JPEG', export_image_quality=88)
    manifest = {'origin_game': [1100, 0, 180], 'scale': .01, 'kept': kept, 'omitted': omitted}
    (DOC / 'village-source-layout.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    (ROOT / 'GodotProject/assets/user_expansion_20261015/village-layout.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    camera_render('original-main-settlement-top', (35, 35, 0), (35, 35.001, 320), 290)
    camera_render('original-main-settlement-overview', (35, 35, 0), (250, -310, 290), 310)


def inspect_assets():
    result = {}
    for role in ['camp_2', 'office']:
        open_baked(ROOT / ('AssetLibrary/derived/user_expansion_20261015/' + role + '.blend'))
        result[role] = [{'name': o.name, 'materials': [m.name if m else None for m in o.data.materials],
                         'bounds': [list(v) for v in bounds(o)]} for o in mesh_objects()]
        for im in bpy.data.images:
            if im.size[0] and len(im.pixels):
                filename = role + '-' + im.name.replace('/', '_').replace('\\', '_') + '.png'
                im.save_render(str(DOC / filename))
        result[role + '_images'] = [{'name': im.name, 'path': im.filepath, 'packed': bool(im.packed_file), 'size': list(im.size)} for im in bpy.data.images]
        if role == 'office':
            camera_render('office-model-top', (0, 0, 0), (0, -.001, 40), 30)
            camera_render('office-model-interior', (1, 2, 1.5), (-8, -8, 3), 15)
    (DOC / 'asset-inspection.json').write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')


def office_components():
    open_baked(ROOT / 'AssetLibrary/derived/user_expansion_20261015/office.blend')
    rows = []
    ob = mesh_objects()[0]
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    remaining = set(bm.verts)
    while remaining:
        seed = remaining.pop()
        group = [seed]
        pending = [seed]
        while pending:
            vertex = pending.pop()
            for edge in vertex.link_edges:
                other = edge.other_vert(vertex)
                if other in remaining:
                    remaining.remove(other)
                    group.append(other)
                    pending.append(other)
        low = [min(v.co[i] for v in group) for i in range(3)]
        high = [max(v.co[i] for v in group) for i in range(3)]
        rows.append({'verts': len(group), 'bounds': [low, high]})
    bm.free()
    (DOC / 'office-components.json').write_text(json.dumps(sorted(rows, key=lambda r: r['verts'], reverse=True), indent=2) + '\n', encoding='utf-8')


def clean_hut():
    open_baked(ROOT / 'AssetLibrary/environment/user_expansion_20261015/imported/camp/raw-import.blend')
    selected = sorted([o for o in mesh_objects() if len(o.data.polygons)>10], key=lambda o:o.name)[1]
    for ob in list(mesh_objects()):
        if ob!=selected:
            bpy.data.objects.remove(ob, do_unlink=True)
    low, high = bounds(selected)
    origin = Vector(((low.x+high.x)/2, (low.y+high.y)/2, low.z))
    for vertex in selected.data.vertices:
        vertex.co = (vertex.co-origin) * (3.5/(high.z-low.z))
    selected.name = 'SuppliedLoggingHouse2'
    count = 0
    for im in bpy.data.images:
        if not im.name.startswith('3d66Model-4690991-files-2.'):
            continue
        width, height = im.size
        pixels = np.array(im.pixels[:], dtype=np.float32).reshape(height, width, 4)
        ys, xs = np.mgrid[:height, :width]
        mask = ((ys > height * .085) & (ys < height * .12) & (xs > width * .53) &
                (xs < width * .95) & (pixels[:,:,0] > .3) &
                (pixels[:,:,0] > pixels[:,:,1] * 1.6) & (pixels[:,:,0] > pixels[:,:,2] * 1.6))
        count = int(mask.sum())
        assert count > 200, count
        for _ in range(3):
            mask |= np.roll(mask, 1, 0) | np.roll(mask, -1, 0) | np.roll(mask, 1, 1) | np.roll(mask, -1, 1)
        replacement = pixels.copy()
        replacement[mask] = np.roll(pixels, -60, axis=0)[mask]
        for _ in range(120):
            average = (np.roll(replacement, 1, 0) + np.roll(replacement, -1, 0) +
                       np.roll(replacement, 1, 1) + np.roll(replacement, -1, 1)) * .25
            replacement[mask] = average[mask]
        im.pixels.foreach_set(replacement.ravel())
        im.update()
        im.pack()
        im.save_render(str(DOC / 'hut-clean-atlas.png'))
    assert count > 200
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'AssetLibrary/derived/user_expansion_20261015/camp_2.blend'))
    bpy.ops.export_scene.gltf(filepath=str(ROOT / 'GodotProject/assets/user_expansion_20261015/camp_2.glb'),
                              export_format='GLB', export_animations=False, export_cameras=False,
                              export_lights=False, export_image_format='JPEG', export_image_quality=88)
    (DOC / 'hut-cleanup.json').write_text(json.dumps({'red_text_pixels_removed': count, 'archived_original_unchanged': True}, indent=2) + '\n', encoding='utf-8')


def clip_half(poly, axis, limit, sign):
    result = []
    for i, vertex in enumerate(poly):
        other = poly[(i + 1) % len(poly)]
        a, b = sign * (vertex[0][axis] - limit), sign * (other[0][axis] - limit)
        if a <= 1e-7:
            result.append(vertex)
        if (a < -1e-7 and b > 1e-7) or (a > 1e-7 and b < -1e-7):
            factor = a / (a - b)
            result.append(tuple(x.lerp(y, factor) for x, y in zip(vertex, other)))
    return result


def subtract_box(poly, low, high):
    if any(max(v[0][i] for v in poly) < low[i] or min(v[0][i] for v in poly) > high[i] for i in range(3)):
        return [poly]
    outside, inside = [], poly
    for axis in range(3):
        for limit, sign in [(low[axis], -1), (high[axis], 1)]:
            part = clip_half(inside, axis, limit, -sign)
            if len(part) >= 3:
                outside.append(part)
            inside = clip_half(inside, axis, limit, sign)
            if len(inside) < 3:
                return outside
    return outside


def clean_office():
    open_baked(ROOT / 'AssetLibrary/environment/user_expansion_20261015/imported/office/raw-import.blend')
    ob = mesh_objects()[0]
    for v in ob.data.vertices:
        p = v.co.copy()
        v.co = (p.x * (26 / 625.8588), (p.y - 206.083) * (24 / 890.9361), max(-.025, (p.z + .885) * .029))
    original = ob.data
    uv = original.uv_layers.active.data
    verts, faces, uvs, normals, material_indices = [], [], [], [], []
    openings = [((-14, -4.8, -.1), (-7.8, .4, 3.15)),
                ((-7.9, -2.8, -.1), (10.4, 2, 3.15))]
    for face in original.polygons:
        pieces = [[(original.vertices[original.loops[i].vertex_index].co.copy(),
                    uv[i].uv.copy(), original.corner_normals[i].vector.copy()) for i in face.loop_indices]]
        for low, high in openings:
            pieces = [fragment for piece in pieces for fragment in subtract_box(piece, low, high)]
        for piece in pieces:
            faces.append(list(range(len(verts), len(verts) + len(piece))))
            verts.extend(p[0] for p in piece)
            uvs.extend(p[1] for p in piece)
            normals.extend(p[2].normalized() for p in piece)
            material_indices.append(face.material_index)
    mesh = bpy.data.meshes.new('OfficeMeasuredOpenings')
    mesh.from_pydata(verts, [], faces)
    for material in original.materials:
        mesh.materials.append(material)
    layer = mesh.uv_layers.new(name='UVMap')
    for i, coords in enumerate(uvs):
        layer.data[i].uv = coords
    for face, index in zip(mesh.polygons, material_indices):
        face.material_index = index
        face.use_smooth = True
    mesh.normals_split_custom_set(normals)
    ob.data = mesh
    ob.name = 'SuppliedTelegraphOffice'
    bpy.data.orphans_purge(do_local_ids=True, do_linked_ids=False, do_recursive=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.wm.save_as_mainfile(filepath=str(ROOT / 'AssetLibrary/derived/user_expansion_20261015/office.blend'))
    bpy.ops.export_scene.gltf(filepath=str(ROOT / 'GodotProject/assets/user_expansion_20261015/office.glb'),
                              export_format='GLB', export_animations=False, export_cameras=False,
                              export_lights=False, export_image_format='JPEG', export_image_quality=88)
    (DOC / 'office-openings.json').write_text(json.dumps({'openings_blender_m': openings, 'polygons': len(faces)}, indent=2) + '\n', encoding='utf-8')


if sys.argv[-1] == 'inspect':
    inspect_assets()
elif sys.argv[-1] == 'components':
    office_components()
elif sys.argv[-1] == 'hut':
    clean_hut()
elif sys.argv[-1] == 'office':
    clean_office()
else:
    settlement()

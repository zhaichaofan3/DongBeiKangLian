"""Derive the supplied pier, boat and river; retain every original package."""
import hashlib
import json
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / 'AssetLibrary/environment/user_expansion_20261015/imported'
SOURCE = ROOT / 'AssetLibrary/derived/user_expansion_20261015'
OUT = ROOT / 'GodotProject/assets/user_expansion_20261015'
records = []


def meshes():
    return [o for o in bpy.context.scene.objects if o.type == 'MESH' and o.data.vertices]


def open_role(role):
    bpy.ops.wm.open_mainfile(filepath=str(DOC / role / 'raw-import.blend'))
    for ob in list(bpy.context.scene.objects):
        if ob.type != 'MESH':
            bpy.data.objects.remove(ob, do_unlink=True)
    for ob in meshes():
        placement = ob.matrix_world.copy()
        ob.parent = None
        ob.data = ob.data.copy()
        ob.data.transform(placement)
        ob.matrix_world = Matrix.Identity(4)
        ob.animation_data_clear()
        ob.modifiers.clear()


def bounds(ob):
    return Vector([min(v.co[i] for v in ob.data.vertices) for i in range(3)]), Vector([max(v.co[i] for v in ob.data.vertices) for i in range(3)])


def export(name, role, notes, excluded):
    bpy.data.orphans_purge(do_local_ids=True, do_linked_ids=False, do_recursive=True)
    for mat in {m for ob in meshes() for m in ob.data.materials if m}:
        mat.use_nodes = True
        bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
        bsdf.inputs['Roughness'].default_value = .85
        bsdf.inputs['Alpha'].default_value = 1
        for link in list(mat.node_tree.links):
            if link.to_socket == bsdf.inputs['Alpha']:
                mat.node_tree.links.remove(link)
        for node in mat.node_tree.nodes:
            if node.type == 'TEX_IMAGE' and node.image and node.image.has_data:
                im = node.image
                if max(im.size) > 2048:
                    ratio = 2048 / max(im.size)
                    im.scale(max(1, int(im.size[0] * ratio)), max(1, int(im.size[1] * ratio)))
                im.pack()
    SOURCE.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / (name + '.blend')))
    bpy.ops.export_scene.gltf(filepath=str(OUT / (name + '.glb')), export_format='GLB', export_animations=False,
                              export_cameras=False, export_lights=False, export_image_format='JPEG', export_image_quality=88)
    triangles = 0
    for ob in meshes():
        ob.data.calc_loop_triangles()
        triangles += len(ob.data.loop_triangles)
    records.append(dict(id=name, source_role=role, notes=notes, objects=len(meshes()), triangles=triangles,
                        excluded_objects=excluded, sha256=hashlib.sha256((OUT / (name + '.glb')).read_bytes()).hexdigest()))
    print('WATERFRONT_ASSET', name, triangles, flush=True)


boat_id = '49c32c8d-cdde-4f4c-90fa-ee6d1dbd287b'
open_role('dock')
for ob in list(meshes()):
    if ob.name == boat_id:
        bpy.data.objects.remove(ob, do_unlink=True)
        continue
    for vertex in ob.data.vertices:
        p = vertex.co.copy()
        vertex.co = (p.y + 1.0, -(p.x - .5), p.z + 18.06535)
    ob.name = 'SuppliedPier_' + ob.name[:8]
export('dock', 'dock', 'Nine supplied timber pier parts. Entry is local X=0, Z=0; walking deck Y=0.', 1)

open_role('dock')
boat = bpy.data.objects[boat_id]
for ob in list(meshes()):
    if ob != boat:
        bpy.data.objects.remove(ob, do_unlink=True)
low, high = bounds(boat)
center = (low + high) * .5
for vertex in boat.data.vertices:
    p = vertex.co.copy()
    vertex.co = ((p.y-center.y)*1.4, -(p.x-center.x)*1.4, (p.z-low.z)*1.4)
boat.name = 'SuppliedWoodenBoatAndOars'
export('boat', 'dock', 'Supplied boat and oars; centred hull with its keel at local Y=0.', 9)

open_role('river')
total = len(meshes())
base_ids = {'Obj3d66-15202935-2-268', 'Obj3d66-15202935-3-834', 'Obj3d66-15202935-4-11'}
rocks = []
for ob in meshes():
    low, high = bounds(ob)
    center = (low + high) * .5
    if any(m and 'files-55' in m.name for m in ob.data.materials) and -5038 < center.y < 4967 and abs(center.x + 22950) < 2600:
        rocks.append(ob.name)
kept = base_ids | set(sorted(rocks)[::2][:16])
removed = [ob.name for ob in meshes() if ob.name not in kept]
for ob in list(meshes()):
    if ob.name not in kept:
        bpy.data.objects.remove(ob, do_unlink=True)
        continue
    bm = bmesh.new()
    bm.from_mesh(ob.data)
    if ob.name in base_ids:
        for x, normal in [(-25550, (1, 0, 0)), (-20350, (-1, 0, 0))]:
            bmesh.ops.bisect_plane(bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
                                  plane_co=(x, 0, 0), plane_no=normal, clear_inner=True)
    bm.to_mesh(ob.data)
    bm.free()
    if not ob.data.vertices:
        bpy.data.objects.remove(ob, do_unlink=True)
        continue
    for vertex in ob.data.vertices:
        p = vertex.co.copy()
        vertex.co = ((p.x + 22950)*.01, (p.y + 35.726)*.016, (p.z - 152.899)*.0068)
    if len(ob.data.polygons) > 5000:
        modifier = ob.modifiers.new('RiverBankLOD', 'DECIMATE')
        modifier.ratio = min(1, 2500 / len(ob.data.polygons))
        bpy.context.view_layer.objects.active = ob
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    ob.name = 'SuppliedRiverWater' if ob.name == 'Obj3d66-15202935-3-834' else 'SuppliedRiverBank_' + ob.name.split('-')[-2]
export('river', 'river', 'Cropped supplied channel, gravel banks, bed and selected stones. Fish, detached display assets and dense plants excluded.', total-len(meshes()))
(DOC / 'waterfront-manifest.json').write_text(json.dumps(dict(assets=records, river_excluded=removed), ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

"""Render imported candidates for inspection; no runtime assets are changed."""
import bpy
from mathutils import Vector, Matrix
from pathlib import Path
import math

ROOT = Path(__file__).resolve().parents[1]
DOC = ROOT / 'docs/user-models-20261015'

for role in ['japanese', 'volunteer']:
    bpy.ops.wm.open_mainfile(filepath=str(DOC / role / 'raw-import.blend'))
    meshes = [ob for ob in bpy.context.scene.objects if ob.type == 'MESH']
    coords = [ob.matrix_world @ v.co for ob in meshes for v in ob.data.vertices]
    low = Vector(tuple(min(p[i] for p in coords) for i in range(3)))
    high = Vector(tuple(max(p[i] for p in coords) for i in range(3)))
    center = Vector(((low.x + high.x) / 2, (low.y + high.y) / 2, low.z))
    factor = 1.75 / (high.z - low.z)
    for ob in meshes:
        transform = ob.matrix_world.copy()
        ob.parent = None
        for v in ob.data.vertices:
            v.co = (transform @ v.co - center) * factor
        ob.matrix_world = Matrix.Identity(4)
    for ob in list(bpy.context.scene.objects):
        if ob.type != 'MESH':
            bpy.data.objects.remove(ob, do_unlink=True)
    # A neutral clay pass exposes geometry when V-Ray shaders cannot translate.
    clay = bpy.data.materials.new('InspectionClay')
    clay.diffuse_color = (.50, .55, .57, 1)
    clay.use_nodes = True
    clay.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value = (.50, .55, .57, 1)
    for ob in meshes:
        for mat in ob.data.materials:
            if not mat or not mat.use_nodes:
                continue
            tex_nodes = [n for n in mat.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image]
            if not tex_nodes:
                bsdf = mat.node_tree.nodes.get('Principled BSDF')
                if bsdf:
                    bsdf.inputs['Base Color'].default_value = (.5, .55, .57, 1)
    bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, -.008))
    plane = bpy.context.object
    floor = bpy.data.materials.new('InspectionFloor')
    floor.diffuse_color = (.08, .10, .11, 1)
    plane.data.materials.append(floor)
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 16
    scene.cycles.use_denoising = True
    scene.render.resolution_x = 1100
    scene.render.resolution_y = 900
    scene.render.resolution_percentage = 100
    scene.world = bpy.data.worlds.new('InspectionWorld')
    scene.world.use_nodes = True
    scene.world.node_tree.nodes['Background'].inputs[0].default_value = (.18, .22, .25, 1)
    scene.world.node_tree.nodes['Background'].inputs[1].default_value = .7
    for location, power, size in [((2, -3, 5), 600, 4), ((-3, 0, 3), 450, 3), ((1, 3, 4), 700, 3)]:
        data = bpy.data.lights.new('InspectionLight', 'AREA')
        data.energy, data.shape, data.size = power, 'DISK', size
        ob = bpy.data.objects.new('InspectionLight', data)
        scene.collection.objects.link(ob)
        ob.location = location
        ob.rotation_euler = (Vector((0, 0, .9)) - ob.location).to_track_quat('-Z', 'Y').to_euler()
    camera_data = bpy.data.cameras.new('InspectionCamera')
    camera_data.type = 'ORTHO'
    camera_data.ortho_scale = 2.6
    camera = bpy.data.objects.new('InspectionCamera', camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    for view, location in [('front', (0, -5, 2.0)), ('back', (0, 5, 2.0)), ('side', (5, 0, 1.7))]:
        camera.location = location
        camera.rotation_euler = (Vector((0, 0, .85)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
        scene.render.filepath = str(DOC / role / (view + '.png'))
        bpy.ops.render.render(write_still=True)
    print('PREVIEW_COMPLETE', role, flush=True)

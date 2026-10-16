"""Render reproducible far and near previews for the S21 artistic Tianchi model."""
import math
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path("C:/GameMake")
SOURCE = ROOT / "AssetLibrary/environment/derived/S21/tianchi_artistic.blend"
OUT = ROOT / "docs/level/S21/previews"
OUT.mkdir(parents=True, exist_ok=True)

bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE_NEXT"
scene.render.resolution_x = 1024
scene.render.resolution_y = 576
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.render.film_transparent = False
scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs['Color'].default_value = (.22,.30,.39,1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value = .6

def aim_camera(camera, target):
    camera.rotation_euler = (Vector(target) - camera.location).to_track_quat("-Z", "Y").to_euler()

def add_light(kind, name, location, energy, color, size=10.0):
    data = bpy.data.lights.new(name=name, type=kind)
    data.energy = energy
    data.color = color
    if kind == "AREA":
        data.shape = "DISK"
        data.size = size
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    obj.location = location
    return obj

sun = add_light("SUN", "S21_Sun", (0, 0, 80), 2.2, (1.0, 0.86, 0.68))
sun.rotation_euler = (math.radians(28), math.radians(-22), math.radians(-35))
fill = add_light("AREA", "S21_Fill", (-70, -90, 90), 1800, (0.48, 0.65, 1.0), 80)
aim_camera(fill, (0, 0, 8))
near_fill = add_light("AREA", "S21_Near_Fill", (-25, -12, 42), 950, (1.0, 0.72, 0.50), 28)
aim_camera(near_fill, (-45, -20, 12))

camera_data = bpy.data.cameras.new("S21_Preview_Camera")
camera = bpy.data.objects.new("S21_Preview_Camera", camera_data)
scene.collection.objects.link(camera)
scene.camera = camera

views = {
    "far": {"location": (230, -245, 200), "target": (0, 0, 9), "lens": 45},
    "near": {"location": (-56, -24, 34), "target": (4, 2, 7), "lens": 35},
}
for name, spec in views.items():
    camera.location = spec["location"]
    camera_data.lens = spec["lens"]
    aim_camera(camera, spec["target"])
    scene.render.filepath = str(OUT / f"tianchi_{name}.png")
    bpy.ops.render.render(write_still=True)

print("Rendered S21 previews:", ", ".join(str(OUT / f"tianchi_{name}.png") for name in views))

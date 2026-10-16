"""Open two measured gates in a derived courtyard, preserving the supplied source."""
import json
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "AssetLibrary/derived/user_expansion_20261015"
OUTPUT = ROOT / "GodotProject/assets/user_expansion_20261015"
bpy.ops.wm.open_mainfile(filepath=str(SOURCE / "village_4.blend"))

# Blender XY maps to Godot X/-Z. Split crossing triangles before removing
# wall faces, so long source triangles cannot erase the rest of a courtyard.
openings = []
for game_z in (-12.0, -17.0):
    lo = Vector((10.6, -game_z - 1.25, 0.06))
    hi = Vector((12.5, -game_z + 1.25, 2.85))
    openings.append((lo, hi))

for obj in [o for o in bpy.context.scene.objects if o.type == "MESH"]:
    obj.data = obj.data.copy()
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    for lo, hi in openings:
        for axis in range(3):
            normal = Vector((0, 0, 0))
            normal[axis] = 1
            for value in (lo[axis], hi[axis]):
                point = Vector((0, 0, 0))
                point[axis] = value
                bmesh.ops.bisect_plane(
                    bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces),
                    dist=0.00001, plane_co=point, plane_no=normal,
                    clear_inner=False, clear_outer=False,
                )
        remove = [f for f in bm.faces if all(
            all(lo[i] - 0.0001 <= v.co[i] <= hi[i] + 0.0001 for i in range(3))
            for v in f.verts
        )]
        bmesh.ops.delete(bm, geom=remove, context="FACES")
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(obj.data)
    bm.free()
    obj.name = "NortheastCourtyardWithTwoSideGates"

bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "village_passages.blend"))
bpy.ops.export_scene.gltf(
    filepath=str(OUTPUT / "village_passages.glb"), export_format="GLB",
    export_animations=False, export_cameras=False, export_lights=False,
    export_image_format="JPEG", export_image_quality=88, export_yup=True,
)
(OUTPUT / "village-passages.json").write_text(json.dumps({
    "source": "village_4.blend", "units": "metres",
    "door_centres_godot": [[11.78, 0, -12], [11.78, 0, -17]],
    "door_width": 2.5, "door_height": 2.79,
    "purpose": "Two side gates connect a compact village street through an existing domestic courtyard.",
}, indent=2) + "\n", encoding="utf-8")
print("COURTYARD_PASSAGES_COMPLETE", flush=True)

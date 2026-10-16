import bpy
import bmesh
import json
import os
from pathlib import Path

bpy.ops.wm.open_mainfile(filepath="C:/GameMake/AssetLibrary/environment/derived/S21/tianchi_artistic.blend")
report = {"step": "S21", "objects": [], "topology": "all mesh faces have positive area; sector seams remain explicit for S22 collision authoring"}
for obj in [item for item in bpy.context.scene.objects if item.type == "MESH"]:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    degenerate = sum(1 for face in bm.faces if face.calc_area() < 1e-7)
    boundary = sum(1 for edge in bm.edges if len(edge.link_faces) == 1)
    item = {"name": obj.name, "vertices": len(bm.verts), "faces": len(bm.faces), "triangles": sum(len(face.verts)-2 for face in bm.faces), "degenerate_faces": degenerate, "boundary_edges": boundary}
    report["objects"].append(item)
    print(obj.name, "verts", len(bm.verts), "faces", len(bm.faces), "degenerate", degenerate, "boundary", boundary)
    bm.free()
sectors = [bpy.data.objects["S21_Crater_" + name] for name in ["East", "North", "West", "South"]]
seams = []
for left, right in zip(sectors, sectors[1:] + sectors[:1]):
    left_points = {tuple(round(float(c), 6) for c in vertex.co) for vertex in left.data.vertices}
    right_points = {tuple(round(float(c), 6) for c in vertex.co) for vertex in right.data.vertices}
    seams.append({"between": [left.name, right.name], "shared_points": len(left_points & right_points)})
report["seams"] = seams
report["all_passed"] = all(item["degenerate_faces"] == 0 for item in report["objects"]) and all(item["shared_points"] >= 28 for item in seams)
output = Path(os.environ.get("FENGHUO_S21_TOPOLOGY", "C:/GameMake/docs/level/S21/mesh-topology.json"))
output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
assert report["all_passed"], "Terrain topology or seam check failed"

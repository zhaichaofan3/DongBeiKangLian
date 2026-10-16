"""Run with Blender --background --python. Preserve the game's exact bind rig.

The immutable normalized inputs live in field_hands/source. Blender welds UV
seams before one subdivision step; UVs and skin weights interpolate with the
surface. Only mesh accessors change in GLB: joints/rest axes/binds stay intact.
"""
import copy
import hashlib
import json
import pathlib
import struct

import bpy
import bmesh
import numpy as np
from mathutils import Matrix, Quaternion, Vector

ROOT = pathlib.Path(__file__).resolve().parents[1]
WORK = ROOT / "AssetLibrary/first_person/field_hands"
DEST = ROOT / "GodotProject/assets/first_person"


def read_glb(path):
    raw = path.read_bytes()
    size = struct.unpack_from("<I", raw, 12)[0]
    doc = json.loads(raw[20:20 + size])
    binary_size = struct.unpack_from("<I", raw, 20 + size)[0]
    binary = raw[28 + size:28 + size + binary_size]
    return doc, binary


def values(doc, binary, index):
    acc = doc["accessors"][index]
    view = doc["bufferViews"][acc["bufferView"]]
    dtype = {5126: "<f4", 5125: "<u4", 5123: "<u2", 5121: "u1"}[acc["componentType"]]
    width = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}[acc["type"]]
    offset = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = view.get("byteStride", np.dtype(dtype).itemsize * width)
    return np.ndarray((acc["count"], width), dtype=dtype, buffer=binary,
                      offset=offset, strides=(stride, np.dtype(dtype).itemsize)).copy()


def node_matrix(node):
    if "matrix" in node:
        return Matrix(np.array(node["matrix"]).reshape(4, 4).T.tolist())
    x, y, z, w = node.get("rotation", [0, 0, 0, 1])
    return Matrix.LocRotScale(Vector(node.get("translation", [0, 0, 0])),
                              Quaternion((w, x, y, z)), Vector(node.get("scale", [1, 1, 1])))


def create_hand(side):
    filename = "hand_" + side + ".glb"
    source = WORK / "source" / filename
    doc, binary = read_glb(source)
    prim = doc["meshes"][0]["primitives"][0]
    attrs = {k: values(doc, binary, a) for k, a in prim["attributes"].items()}
    indices = values(doc, binary, prim["indices"]).reshape(-1, 3)
    mesh = bpy.data.meshes.new(side + "_hand_control_mesh")
    mesh.from_pydata(attrs["POSITION"].tolist(), [], indices.tolist())
    mesh.update()
    obj = bpy.data.objects.new(side + "_hand", mesh)
    bpy.context.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    uv = mesh.uv_layers.new(name="SourceUV")
    for loop in mesh.loops:
        u, v = attrs["TEXCOORD_0"][loop.vertex_index]
        uv.data[loop.index].uv = (u, 1.0 - v)
    joints = doc["skins"][0]["joints"]
    for node in joints:
        obj.vertex_groups.new(name=doc["nodes"][node]["name"])
    for i in range(len(mesh.vertices)):
        for joint, weight in zip(attrs["JOINTS_0"][i], attrs["WEIGHTS_0"][i]):
            if weight > 0:
                obj.vertex_groups[int(joint)].add([i], float(weight), "REPLACE")
    # Split UV vertices must not become physical cracks during smoothing.
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=0.0000001)
    bm.to_mesh(mesh)
    bm.free()
    for face in mesh.polygons:
        face.use_smooth = True
    subdivision = obj.modifiers.new("Knuckle silhouette refinement", "SUBSURF")
    subdivision.levels = 1
    subdivision.render_levels = 1
    subdivision.uv_smooth = "PRESERVE_BOUNDARIES"

    # Read the refined mesh before adding the editable armature modifier.
    evaluated = obj.evaluated_get(bpy.context.evaluated_depsgraph_get())
    refined = evaluated.to_mesh(preserve_all_data_layers=True, depsgraph=bpy.context.evaluated_depsgraph_get())
    refined.calc_loop_triangles()
    positions, normals, uvs, skin_joints, skin_weights = [], [], [], [], []
    corner_to_vertex, triangles = {}, []
    for tri in refined.loop_triangles:
        for loop_index in tri.loops:
            loop = refined.loops[loop_index]
            vertex = refined.vertices[loop.vertex_index]
            coord = refined.uv_layers.active.data[loop_index].uv
            key = (loop.vertex_index, round(coord.x, 7), round(coord.y, 7))
            if key not in corner_to_vertex:
                corner_to_vertex[key] = len(positions)
                positions.append(tuple(vertex.co))
                normals.append(tuple(vertex.normal))
                uvs.append((coord.x, 1.0 - coord.y))
                weights = sorted(((g.group, g.weight) for g in vertex.groups if g.weight > 1e-8), key=lambda x: -x[1])[:4]
                assert weights, "Unweighted refined vertex"
                total = sum(w for _, w in weights)
                skin_joints.append([j for j, _ in weights] + [0] * (4 - len(weights)))
                skin_weights.append([w / total for _, w in weights] + [0.0] * (4 - len(weights)))
            triangles.append(corner_to_vertex[key])
    evaluated.to_mesh_clear()
    result = copy.deepcopy(doc)
    output_binary = bytearray(binary)

    def append(data, component, kind, bounds=False):
        data = np.asarray(data, dtype={5126: "<f4", 5125: "<u4", 5123: "<u2"}[component])
        assert np.all(np.isfinite(data))
        output_binary.extend(b"\0" * (-len(output_binary) % 4))
        view = len(result["bufferViews"])
        result["bufferViews"].append({"buffer": 0, "byteOffset": len(output_binary), "byteLength": data.nbytes})
        output_binary.extend(data.tobytes())
        acc = {"bufferView": view, "componentType": component, "count": len(data), "type": kind}
        if bounds:
            acc.update(min=data.min(axis=0).tolist(), max=data.max(axis=0).tolist())
        result["accessors"].append(acc)
        return len(result["accessors"]) - 1

    refined_prim = result["meshes"][0]["primitives"][0]
    refined_prim["attributes"] = {
        "POSITION": append(positions, 5126, "VEC3", True),
        "NORMAL": append(normals, 5126, "VEC3"),
        "TEXCOORD_0": append(uvs, 5126, "VEC2"),
        "JOINTS_0": append(skin_joints, 5123, "VEC4"),
        "WEIGHTS_0": append(skin_weights, 5126, "VEC4"),
    }
    refined_prim["indices"] = append(triangles, 5125, "SCALAR")
    assert result["nodes"] == doc["nodes"] and result["skins"] == doc["skins"]
    assert np.max(np.abs(np.sum(skin_weights, axis=1) - 1.0)) < 1e-6
    output_binary.extend(b"\0" * (-len(output_binary) % 4))
    result["buffers"][0]["byteLength"] = len(output_binary)
    result["asset"]["generator"] = "Fenghuo Blender hand refinement; CC0 source by para"
    encoded = json.dumps(result, separators=(",", ":")).encode()
    encoded += b" " * (-len(encoded) % 4)
    raw = struct.pack("<4sII", b"glTF", 2, 28 + len(encoded) + len(output_binary))
    raw += struct.pack("<II", len(encoded), 0x4E4F534A) + encoded
    raw += struct.pack("<II", len(output_binary), 0x004E4942) + output_binary
    (DEST / filename).write_bytes(raw)

    # Build an editable rest rig. Runtime GLB uses the untouched source rig.
    parents = {child: parent for parent, n in enumerate(doc["nodes"]) for child in n.get("children", [])}
    globals_ = {}

    def world(n):
        if n not in globals_:
            globals_[n] = (world(parents[n]) if n in parents else Matrix.Identity(4)) @ node_matrix(doc["nodes"][n])
        return globals_[n]

    armature = bpy.data.armatures.new(side + "_hand_rig")
    rig = bpy.data.objects.new(side + "_hand_rig", armature)
    bpy.context.collection.objects.link(rig)
    obj.select_set(False)
    rig.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    for node in joints:
        bone = armature.edit_bones.new(doc["nodes"][node]["name"])
        bone.matrix = world(node)
        bone.length = 0.018
    for node in joints:
        parent = parents.get(node)
        if parent in joints:
            armature.edit_bones[doc["nodes"][node]["name"]].parent = armature.edit_bones[doc["nodes"][parent]["name"]]
    bpy.ops.object.mode_set(mode="OBJECT")
    mod = obj.modifiers.new("Editable finger rig", "ARMATURE")
    mod.object = rig
    obj.parent = rig
    rig.location.x = -0.12 if side == "left" else 0.12
    rig.show_in_front = True
    armature.display_type = "STICK"
    rig.select_set(False)

    # Keep the supplied source color map packed into the editable project.
    mat = bpy.data.materials.new(side + "_source_skin")
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Roughness"].default_value = 0.79
    image_spec = doc["images"][0]
    image_view = doc["bufferViews"][image_spec["bufferView"]]
    start = image_view.get("byteOffset", 0)
    image_path = WORK / (side + "_skin.png")
    image_path.write_bytes(binary[start:start + image_view["byteLength"]])
    texture = mat.node_tree.nodes.new("ShaderNodeTexImage")
    texture.image = bpy.data.images.load(str(image_path))
    texture.image.pack()
    mat.node_tree.links.new(texture.outputs["Color"], shader.inputs["Base Color"])
    mesh.materials.append(mat)
    obj["source_author"] = "para / CC0-1.0 / OpenGameArt FPS arms rigged only"
    obj["runtime_export"] = "Mesh refined; source GLB joint names, transforms and inverse binds preserved exactly"
    return {"file": filename, "source_triangles": len(indices), "triangles": len(triangles) // 3,
            "vertices": len(positions), "bones": len(joints), "bind_rig_preserved": True,
            "source_sha256": hashlib.sha256(source.read_bytes()).hexdigest(),
            "sha256": hashlib.sha256(raw).hexdigest()}


bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
reports = [create_hand(side) for side in ("left", "right")]
bpy.context.scene.unit_settings.system = "METRIC"
bpy.context.scene["README"] = "CC0 hands by para. Editable welded cages, packed original textures, one subdivision level, 24 bones per side. Runtime export preserves the original bind axes. Rebuild: tools/refine_fp_hands.py."
bpy.ops.wm.save_as_mainfile(filepath=str(WORK / "field_hands.blend"))
provenance = json.loads((WORK / "source/provenance.json").read_text(encoding="utf-8"))
provenance["changes"] += " Blender refinement: weld UV seam duplicates, one Catmull-Clark subdivision level, smooth normals, interpolate UVs/weights and normalize strongest four influences; preserve all original joint transforms and inverse binds."
provenance["outputs"] = reports
provenance["editable_source"] = "AssetLibrary/first_person/field_hands/field_hands.blend"
(DEST / "provenance.json").write_text(json.dumps(provenance, indent=2), encoding="utf-8")
(WORK / "build-report.json").write_text(json.dumps(reports, indent=2), encoding="utf-8")
print("HAND_REFINEMENT_COMPLETE " + json.dumps(reports))

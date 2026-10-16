"""Inspect user MAX assets in Blender without changing the game or its hands."""
import bpy
import hashlib
import importlib.util
import json
import sys
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
LIBRARY = ROOT / 'AssetLibrary/characters/user_models_20261015'
EVIDENCE = ROOT / 'docs/user-models-20261015'
IMPORTER = ROOT / 'tools/third_party/max_importer/io_scene_max-main/source/import_max.py'

spec = importlib.util.spec_from_file_location('user_max_importer', IMPORTER)
importer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(importer)
original_bitmap = importer.get_bitmap


def find_bitmap(chunk, visited=None):
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
    references = importer.get_references(chunk) + list(importer.get_reference(chunk).values())
    for reference in references:
        result = find_bitmap(reference, visited)
        if result:
            return result
    return None


# V-Ray color-correction wrappers refer to the original bitmap indirectly.
importer.get_bitmap = find_bitmap


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


for role in ['japanese', 'volunteer']:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    source = next((LIBRARY / role).glob('*.max'))
    importer.load(None, bpy.context, filepath=str(source),
                  object_filter={'MATERIAL', 'UV', 'PRIMITIVE', 'EMPTY', 'ARMATURE'})
    bpy.context.view_layer.update()
    objects = []
    for ob in bpy.context.scene.objects:
        item = {'name': ob.name, 'type': ob.type, 'parent': ob.parent.name if ob.parent else None}
        if ob.type == 'MESH':
            points = [ob.matrix_world @ v.co for v in ob.data.vertices]
            ob.data.calc_loop_triangles()
            item.update(vertices=len(points), triangles=len(ob.data.loop_triangles),
                        materials=[m.name if m else None for m in ob.data.materials],
                        uv_layers=len(ob.data.uv_layers),
                        vertex_groups=[g.name for g in ob.vertex_groups],
                        modifiers=[{'name': m.name, 'type': m.type} for m in ob.modifiers])
            if points:
                item['bounds'] = [[min(p[i] for p in points), max(p[i] for p in points)] for i in range(3)]
        elif ob.type == 'ARMATURE':
            item['bones'] = [{'name': b.name, 'head': list(ob.matrix_world @ b.head_local),
                              'tail': list(ob.matrix_world @ b.tail_local)} for b in ob.data.bones]
        objects.append(item)
    materials = []
    for mat in bpy.data.materials:
        materials.append({'name': mat.name, 'diffuse': list(mat.diffuse_color),
                          'images': [n.image.name for n in mat.node_tree.nodes
                                     if n.type == 'TEX_IMAGE' and n.image] if mat.use_nodes else []})
    report = {'role': role, 'source': source.relative_to(ROOT).as_posix(), 'sha256': digest(source),
              'importer': 'nrgsille76/io_scene_max 1.9.2 (GPL-2.0-or-later)',
              'objects': objects, 'materials': materials,
              'images': [{'name': im.name, 'filepath': im.filepath, 'size': list(im.size),
                          'has_data': im.has_data} for im in bpy.data.images],
              'animation_actions': [a.name for a in bpy.data.actions]}
    output = EVIDENCE / role
    output.mkdir(parents=True, exist_ok=True)
    (output / 'inspection.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    bpy.ops.wm.save_as_mainfile(filepath=str(output / 'raw-import.blend'))
    print('USER_MAX_INSPECTION', role, 'meshes', sum(o['type'] == 'MESH' for o in objects),
          'triangles', sum(o.get('triangles', 0) for o in objects),
          'armatures', sum(o['type'] == 'ARMATURE' for o in objects), flush=True)

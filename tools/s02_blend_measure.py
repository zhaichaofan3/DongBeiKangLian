"""Read existing Blender sources without executing embedded scripts or saving them."""
import bpy
from mathutils import Vector
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
entries = {
    'oga_dims-arboretum': 'AssetLibrary/environment/supplement/dims-arboretum/extracted/dim_arboretum.blend',
    'oga_birch-tree': 'AssetLibrary/environment/supplement/birch-tree/treebirch.blend',
    'oga_medieval-waterpowered-sawmill': 'AssetLibrary/environment/supplement/medieval-waterpowered-sawmill/extracted/WaterPoweredSawmillUpload.blend',
}
entries['oga_retro-log-cabin'] = next((ROOT / 'AssetLibrary/environment/supplement/retro-log-cabin').rglob('*.fbx')).relative_to(ROOT).as_posix()
results = []
for asset_id, relative in entries.items():
    path = ROOT / relative
    before = hashlib.sha256(path.read_bytes()).hexdigest()
    if path.suffix.lower() == '.blend':
        bpy.ops.wm.open_mainfile(filepath=str(path), load_ui=False, use_scripts=False)
    else:
        bpy.ops.wm.read_factory_settings(use_empty=True)
        bpy.ops.import_scene.fbx(filepath=str(path), use_anim=False, use_custom_props=False)
    objects = []
    all_points = []
    for obj in bpy.context.scene.objects:
        if obj.type != 'MESH':
            continue
        obj.data.calc_loop_triangles()
        points = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
        all_points += points
        bounds = [min(point[i] for point in points) for i in range(3)], [max(point[i] for point in points) for i in range(3)]
        objects.append({'name': obj.name, 'mesh': obj.data.name, 'source_triangles': len(obj.data.loop_triangles),
                        'world_bbox_blender_xyz': [round(bounds[1][i] - bounds[0][i], 6) for i in range(3)]})
    dimensions = [round(max(p[i] for p in all_points) - min(p[i] for p in all_points), 6) for i in range(3)] if all_points else []
    missing = []
    for image in bpy.data.images:
        if image.source == 'FILE' and not image.packed_file and not image.packed_files:
            image_path = Path(bpy.path.abspath(image.filepath))
            if not image_path.is_file():
                missing.append({'image': image.name, 'source_reference': image.filepath, 'data_users': image.users})
    assert hashlib.sha256(path.read_bytes()).hexdigest() == before
    results.append({'id': asset_id, 'path': relative, 'sha256': before, 'source_unchanged': True,
                    'scene_mesh_instances': len(objects), 'source_triangles_total_instances': sum(o['source_triangles'] for o in objects),
                    'source_scene_bbox_blender_xyz': dimensions, 'scene_unit_scale': bpy.context.scene.unit_settings.scale_length,
                    'objects': objects, 'missing_unpacked_image_references': missing,
                    'action_names': [action.name for action in bpy.data.actions],
                    'method': 'Blender 4.5 read-only scene inspection; Z up; base meshes, default frame and world object bounds; modifiers, particles and animation playback not evaluated.'})
output = ROOT / 'docs/resources/S02/blend_measurements.json'
output.parent.mkdir(parents=True, exist_ok=True)
output.write_text(json.dumps(results, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('S02 BLEND MEASUREMENT:', len(results), 'sources inspected, unchanged')

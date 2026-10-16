"""Adapt the supplied MAX meshes to the existing third-person motion rig."""
import bpy
import bmesh
import hashlib
import json
import math
import re
import sys
from pathlib import Path
from mathutils import Vector, Matrix
import numpy as np
import argparse

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from guard_identity_geometry import add_friendly_cap_star, add_guard_identity

LIB = ROOT / 'AssetLibrary/characters/user_models_20261015'
DOC = ROOT / 'AssetLibrary/characters/user_models_20261015/imported'
OUT = ROOT / 'GodotProject/assets/characters/user_soldiers'
LEGACY = ROOT / 'AssetLibrary/characters/field_character/field_character.blend'
LANDMARKS = {}
OUT.mkdir(parents=True, exist_ok=True)


def xyz(p):
    return Vector((p[0], -p[2], p[1]))


def game(p):
    return Vector((p.x, p.z, -p.y))


def smooth(a, b, value):
    t = max(0, min(1, (value - a) / (b - a)))
    return t * t * (3 - 2 * t)


def legacy_parts(names):
    with bpy.data.libraries.load(str(LEGACY), link=False) as (source, target):
        target.objects = names
    result = {}
    for ob in target.objects:
        name = ob.name
        bpy.context.collection.objects.link(ob)
        ob.parent = None
        ob.matrix_world = Matrix.Identity(4)
        ob.modifiers.clear()
        result[name] = ob
    return result


def make_rig():
    rests = {'Hips': ((0, .86, 0), None), 'Chest': ((0, 1.04, 0), 'Hips'),
             'Head': ((0, 1.518, -.005), 'Chest')}
    for i, sign in enumerate([-1, 1]):
        rests.update({f'Thigh{i}': ((sign * .118, .855, 0), 'Hips'),
                      f'Knee{i}': ((sign * .118, .465, 0), f'Thigh{i}'),
                      f'Foot{i}': ((sign * .118, .11, 0), f'Knee{i}'),
                      f'Shoulder{i}': ((sign * .243, 1.33, 0), 'Chest'),
                      f'Elbow{i}': ((sign * .243, 1.055, 0), f'Shoulder{i}')})
    data = bpy.data.armatures.new('SoldierSkeleton')
    arm = bpy.data.objects.new('SoldierRig', data)
    bpy.context.collection.objects.link(arm)
    bpy.ops.object.select_all(action='DESELECT')
    arm.select_set(True)
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode='EDIT')
    for name, (position, parent) in rests.items():
        bone = data.edit_bones.new(name)
        bone.head = xyz(position)
        bone.tail = bone.head + Vector((0, 0, .1))
        if parent:
            bone.parent = data.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT')
    return arm


def source_weights(p, part):
    x, y, z = p
    side = 0 if x < 0 else 1
    ax = abs(x)
    if part == 'Hands':
        return {f'Elbow{side}': 1}
    if part in ['Face', 'Cap', 'Helmet']:
        return {'Head': 1}
    arm = smooth(.18, .29, ax) * smooth(.91, 1.04, y)
    if ax > .35 and y > .86:
        arm = 1
    if arm > .001:
        # Blend across the original elbow rather than along world height.
        elbow = LANDMARKS[side]['elbow'].copy()
        elbow.x = abs(elbow.x)
        direction = LANDMARKS[side]['wrist'] - LANDMARKS[side]['elbow']
        direction.x = abs(direction.x)
        direction.normalize()
        along = (Vector((ax, y, z)) - elbow).dot(direction)
        lower = smooth(-.055, .055, along)
        weights = {f'Shoulder{side}': arm * (1 - lower), f'Elbow{side}': arm * lower}
        weights['Chest'] = 1 - arm
        return {k: v for k, v in weights.items() if v > .00001}
    if y < .85 and ax < .27:
        lower = smooth(.395, .535, y)
        foot = 1 - smooth(.13, .21, y)
        hips = smooth(.78, .87, y)
        return {k: v for k, v in {f'Thigh{side}': lower * (1 - hips),
                                 f'Knee{side}': (1 - lower) * (1 - foot),
                                 f'Foot{side}': foot, 'Hips': lower * hips}.items() if v > .00001}
    chest = smooth(.84, 1.07, y)
    return {k: v for k, v in {'Hips': 1 - chest, 'Chest': chest}.items() if v > .00001}


def repose(p, weights, part):
    if part == 'Hands':
        side = 0 if p.x < 0 else 1
        landmarks = LANDMARKS[side]
        direction = landmarks['wrist'] - landmarks['elbow']
        target_direction = Vector((-.027 if side == 0 else .027, -.232, 0))
        rotation = direction.normalized().rotation_difference(target_direction.normalized())
        return Vector((-.270 if side == 0 else .270, .823, 0)) + rotation @ (p - landmarks['wrist'])
    result = Vector((0, 0, 0))
    for bone, weight in weights.items():
        if bone.startswith(('Shoulder', 'Elbow')):
            sign = -1 if bone.endswith('0') else 1
            upper = bone.startswith('Shoulder')
            landmarks = LANDMARKS[0 if sign < 0 else 1]
            source = landmarks['shoulder' if upper else 'elbow']
            target = Vector((sign * .243, 1.33 if upper else 1.055, 0))
            direction = landmarks['elbow' if upper else 'wrist'] - source
            target_direction = Vector((0, -.275, 0)) if upper else Vector((sign * .027, -.232, 0))
            scale = target_direction.length / direction.length
            rotation = direction.normalized().rotation_difference(target_direction.normalized())
            offset = p - source
            axis = direction.normalized()
            offset += axis * offset.dot(axis) * (scale - 1)
            result += (target + rotation @ offset) * weight
        else:
            result += p * weight
    if max(weights.get('Elbow0', 0), weights.get('Elbow1', 0)) > .8:
        result.y = max(.823, result.y)
    return result


def assign_skin(ob, arm):
    ob.parent = arm
    modifier = ob.modifiers.new('Existing game motion', 'ARMATURE')
    modifier.object = arm


def fix_volunteer_materials(meshes):
    mapping = {1: 1, 2: 2, 3: 3, 4: 4, 5: 5, 6: 6, 7: 7, 8: 8, 9: 11, 10: 9, 11: 10, 12: 12}
    texture_dir = LIB / 'adapted/textures'
    texture_dir.mkdir(parents=True, exist_ok=True)
    for ob in meshes:
        for mat in ob.data.materials:
            if mat.get('adapted'):
                continue
            index = int(re.search(r'17309872-(\d{3})', mat.name)[1])
            texture = LIB / f'volunteer/3d66Model-17309872-files-{mapping[index]:03}.png'
            image = bpy.data.images.load(str(texture), check_existing=True)
            if index in [1, 2, 7, 10]:
                image = image.copy()
                image.name = f'VolunteerGray_{index}'
                pixels = np.empty(image.size[0] * image.size[1] * 4, dtype=np.float32)
                image.pixels.foreach_get(pixels)
                pixels = pixels.reshape((-1, 4))
                luminance = pixels[:, :3] @ np.array([.2126, .7152, .0722])
                pixels[:, :3] = np.clip(luminance[:, None] * np.array([1.17, 1.20, 1.23]) + .018, 0, 1)
                image.pixels.foreach_set(pixels.ravel())
                image.filepath_raw = str(texture_dir / f'volunteer_gray_{index:02}.png')
                image.file_format = 'PNG'
                image.save()
            mat.use_nodes = True
            mat.node_tree.nodes.clear()
            output = mat.node_tree.nodes.new('ShaderNodeOutputMaterial')
            shader = mat.node_tree.nodes.new('ShaderNodeBsdfPrincipled')
            shader.inputs['Roughness'].default_value = .87
            tex = mat.node_tree.nodes.new('ShaderNodeTexImage')
            tex.image = image
            mat.node_tree.links.new(tex.outputs['Color'], shader.inputs['Base Color'])
            mat.node_tree.links.new(shader.outputs['BSDF'], output.inputs['Surface'])
            mat['adapted'] = True


def extract_parts(meshes, role):
    parts = {}
    # Select one of the two identical, differently oriented volunteer figures.
    coords = [ob.matrix_world @ v.co for ob in meshes for v in ob.data.vertices]
    low = Vector(tuple(min(p[i] for p in coords) for i in range(3)))
    high = Vector(tuple(max(p[i] for p in coords) for i in range(3)))
    if role == 'volunteer':
        head = next(ob for ob in meshes if '-9-' in ob.name)
        head_points = [head.matrix_world @ v.co for v in head.data.vertices]
        center = Vector(((min(p.x for p in head_points) + max(p.x for p in head_points)) / 2,
                         (min(p.y for p in head_points) + max(p.y for p in head_points)) / 2, low.z))
    else:
        center = Vector(((low.x + high.x) / 2, (low.y + high.y) / 2, low.z))
    factor = 1.77 / (high.z - low.z)
    source_hands = [[], []]
    for ob in meshes:
        for polygon in ob.data.polygons:
            material = ob.data.materials[polygon.material_index]
            hand = ('files-002' in material.name) if role == 'japanese' else bool(re.search(r'17309872-012', material.name))
            if not hand:
                continue
            for index in polygon.vertices:
                p = (ob.matrix_world @ ob.data.vertices[index].co - center) * factor
                point = Vector((-p.x, p.z, p.y))
                source_hands[0 if point.x < 0 else 1].append(point)
    LANDMARKS.clear()
    for side, points in enumerate(source_hands):
        sign = -1 if side == 0 else 1
        top = max(p.y for p in points)
        rim = [p for p in points if p.y > top - .018]
        wrist = sum(rim, Vector()) / len(rim)
        shoulder = Vector((sign * .212, 1.40 if role == 'volunteer' else 1.36, 0))
        elbow = shoulder.lerp(wrist, .542)
        LANDMARKS[side] = {'shoulder': shoulder, 'elbow': elbow, 'wrist': wrist}
    print('SOURCE_ARM_LANDMARKS', role, {i: {k: list(v) for k, v in values.items()} for i, values in LANDMARKS.items()}, flush=True)
    for ob in meshes:
        coords = []
        for vertex in ob.data.vertices:
            p = (ob.matrix_world @ vertex.co - center) * factor
            # Both MAX figures face Blender -Y; the game faces Blender +Y.
            coords.append(Vector((-p.x, p.z, p.y)))
        for polygon in ob.data.polygons:
            points = [coords[i] for i in polygon.vertices]
            midpoint = sum(points, Vector()) / len(points)
            if role == 'volunteer':
                material_index = int(re.search(r'17309872-(\d{3})', ob.data.materials[polygon.material_index].name)[1])
                if material_index in [3, 6]:
                    # Omit the static rifle/bayonet and use the game weapon.
                    continue
                part = 'Hands' if material_index == 12 else 'Face' if material_index == 9 else 'Cap' if material_index == 10 else 'Clothing'
            else:
                material_name = ob.data.materials[polygon.material_index].name
                if 'files-002' in material_name:
                    continue
                part = 'Helmet' if midpoint.y > 1.65 else 'Face' if midpoint.y > 1.455 else 'Clothing'
            data = parts.setdefault(part, {'vertices': [], 'faces': [], 'uvs': [], 'materials': [], 'slots': [], 'weights': []})
            offset = len(data['vertices'])
            data['faces'].append(tuple(offset + i for i in range(len(points))))
            material = ob.data.materials[polygon.material_index]
            if material not in data['materials']:
                data['materials'].append(material)
            data['slots'].append(data['materials'].index(material))
            uv_layer = ob.data.uv_layers.active
            for point, loop in zip(points, polygon.loop_indices):
                weights = source_weights(point, part)
                data['vertices'].append(xyz(repose(point, weights, part)))
                data['weights'].append(weights)
                data['uvs'].append(tuple(uv_layer.data[loop].uv) if uv_layer else (0, 0))
    return parts


def make_part(name, data, arm):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(data['vertices'], [], data['faces'])
    mesh.update()
    ob = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(ob)
    for material in data['materials']:
        mesh.materials.append(material)
    uv = mesh.uv_layers.new(name='UVMap')
    for polygon, slot in zip(mesh.polygons, data['slots']):
        polygon.material_index = slot
        polygon.use_smooth = True
        for loop in polygon.loop_indices:
            uv.data[loop].uv = data['uvs'][mesh.loops[loop].vertex_index]
    groups = {name: ob.vertex_groups.new(name=name) for name in arm.data.bones.keys()}
    for index, weights in enumerate(data['weights']):
        total = sum(weights.values())
        for bone, value in weights.items():
            groups[bone].add([index], value / total, 'REPLACE')
    # Imported meshes often store a separate vertex at every triangle corner.
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=.00001)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    assign_skin(ob, arm)
    return ob


def friendly_grip(hands):
    grip = hands.copy()
    grip.data = hands.data.copy()
    grip.name = 'GuardHands'
    bpy.context.collection.objects.link(grip)
    for side, sign in enumerate([-1, 1]):
        vertices = [v for v in grip.data.vertices if v.co.x * sign > 0]
        points = np.array([game(v.co) for v in vertices])
        _, axes = np.linalg.eigh(np.cov(points.T))
        down = Vector(axes[:, 2])
        back = Vector(axes[:, 0])
        if down.y > 0:
            down.negate()
        if back.z < 0:
            back.negate()
        across = back.cross(down).normalized()
        rim = [Vector(p) for p in points if p[1] > .808]
        source_wrist = sum(rim, Vector()) / len(rim)
        wrist = Vector((sign * .270, .823, 0))
        for vertex in vertices:
            original = game(vertex.co)
            offset = original - source_wrist
            along = offset.dot(down) * .87
            width = offset.dot(across) * .86
            depth = offset.dot(back) * .85
            # Bend the supplied glove in its palm plane. World-axis squashing
            # leaves its original palm twist in place and sends fingers upward.
            width *= 1 - .38 * smooth(.03, .075, -sign * width) * smooth(.03, .09, along)
            angle = min(2.75, max(0, along - .075) / .028)
            center_y = .823 - min(along, .075) - .028 * math.sin(angle)
            center_z = -.008 * smooth(0, .07, along) - .028 * (1 - math.cos(angle))
            posed = Vector((wrist.x + width, center_y - depth * math.sin(angle),
                            center_z + depth * math.cos(angle)))
            vertex.co = xyz(original.lerp(posed, smooth(.008, .045, along)))
    bm = bmesh.new()
    bm.from_mesh(grip.data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(grip.data)
    bm.free()
    return grip


arguments = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
parser = argparse.ArgumentParser()
parser.add_argument('--role', choices=['japanese', 'volunteer', 'both'], default='both')
options = parser.parse_args(arguments)
reports = []
for role in ['japanese', 'volunteer']:
    if options.role not in ['both', role]:
        continue
    bpy.ops.wm.open_mainfile(filepath=str(DOC / role / 'raw-import.blend'))
    meshes = [ob for ob in bpy.context.scene.objects if ob.type == 'MESH'
              and (role != 'volunteer' or ob.parent.name == 'Group-17309872-1-36')]
    if role == 'volunteer':
        fix_volunteer_materials(meshes)
    parts = extract_parts(meshes, role)
    for ob in list(bpy.context.scene.objects):
        bpy.data.objects.remove(ob, do_unlink=True)
    arm = make_rig()
    built = [make_part(name, data, arm) for name, data in parts.items()]
    if role == 'volunteer':
        built.append(friendly_grip(next(ob for ob in built if ob.name == 'Hands')))
    compatible = legacy_parts(['Bandage'] if role == 'volunteer' else ['Hands', 'GuardHands', 'Bandage'])
    for name, ob in compatible.items():
        if role == 'japanese' and name == 'Bandage':
            bpy.data.objects.remove(ob, do_unlink=True)
            continue
        if role == 'volunteer' and name == 'Bandage':
            # The old forehead wrap floats across the new cap and eyes.
            head_group = ob.vertex_groups.get('Head')
            if head_group:
                bm = bmesh.new()
                bm.from_mesh(ob.data)
                layer = bm.verts.layers.deform.verify()
                bmesh.ops.delete(bm, geom=[v for v in bm.verts if v[layer].get(head_group.index, 0) > .5], context='VERTS')
                bm.to_mesh(ob.data)
                bm.free()
        assign_skin(ob, arm)
        built.append(ob)
    if role == 'volunteer':
        built.append(add_friendly_cap_star(arm))
    else:
        built.extend(add_guard_identity(arm))
    for image in bpy.data.images:
        if image.has_data and not image.packed_file:
            image.pack()
    target = LIB / 'adapted'
    target.mkdir(exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(target / (role + '.blend')))
    bpy.ops.object.select_all(action='SELECT')
    output = OUT / (role + '.glb')
    bpy.ops.export_scene.gltf(filepath=str(output), export_format='GLB', use_selection=True,
                              export_animations=False, export_yup=True, export_cameras=False,
                              export_lights=False)
    report = {'role': role, 'source': f'{role}/' + next((LIB / role).glob('*.max')).name,
              'game_model': output.relative_to(ROOT).as_posix(), 'sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
              'bones': len(arm.data.bones), 'parts': [],
              'adaptation': ('MAX geometry, original textured gloves and UVs reposed to the existing 13-bone game rig; separate relaxed/gripping hands. Leg bandage retained, incompatible old forehead wrap removed. First-person hands untouched.' if role == 'volunteer' else 'MAX geometry and UVs; normalized and reposed to the existing 13-bone game rig. Existing third-person hand contact meshes retained. First-person hands untouched.')}
    for ob in built:
        ob.data.calc_loop_triangles()
        report['parts'].append({'name': ob.name, 'triangles': len(ob.data.loop_triangles), 'vertices': len(ob.data.vertices)})
    report['triangles'] = sum(p['triangles'] for p in report['parts'])
    reports.append(report)
    print('USER_SOLDIER_BUILT', json.dumps(report), flush=True)
if options.role != 'both' and (OUT / 'provenance.json').exists():
    previous = json.loads((OUT / 'provenance.json').read_text(encoding='utf-8'))
    reports = [next((new for new in reports if new['role'] == old['role']), old) for old in previous]
(OUT / 'provenance.json').write_text(json.dumps(reports, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
(LIB / 'adapted/build-report.json').write_text(json.dumps(reports, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

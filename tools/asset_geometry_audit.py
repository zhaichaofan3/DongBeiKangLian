"""Read mesh bounds and complexity without importing or modifying source assets."""
import base64
import itertools
import json
from pathlib import Path
import struct
from urllib.parse import unquote
import xml.etree.ElementTree as ET


def identity():
    return [[float(i == j) for j in range(4)] for i in range(4)]


def multiply(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(4)) for j in range(4)] for i in range(4)]


def transform(node):
    if 'matrix' in node:
        return [[node['matrix'][j * 4 + i] for j in range(4)] for i in range(4)]
    x, y, z, w = node.get('rotation', [0, 0, 0, 1])
    scale = node.get('scale', [1, 1, 1])
    rotation = [[1-2*(y*y+z*z), 2*(x*y-z*w), 2*(x*z+y*w)],
                [2*(x*y+z*w), 1-2*(x*x+z*z), 2*(y*z-x*w)],
                [2*(x*z-y*w), 2*(y*z+x*w), 1-2*(x*x+y*y)]]
    result = identity()
    for i in range(3):
        for j in range(3):
            result[i][j] = rotation[i][j] * scale[j]
        result[i][3] = node.get('translation', [0, 0, 0])[i]
    return result


def dimensions(points):
    if not points:
        return None
    return [round(max(p[i] for p in points) - min(p[i] for p in points), 6) for i in range(3)]


def read_gltf(path):
    path = Path(path)
    binary = None
    if path.suffix.lower() == '.glb':
        raw = path.read_bytes()
        magic, version, length = struct.unpack_from('<4sII', raw)
        if magic != b'glTF' or version != 2 or length != len(raw):
            raise ValueError('Invalid GLB header')
        document = None
        offset = 12
        while offset < length:
            size, kind = struct.unpack_from('<II', raw, offset)
            chunk = raw[offset + 8: offset + 8 + size]
            if kind == 0x4E4F534A:
                document = json.loads(chunk)
            elif kind == 0x004E4942:
                binary = chunk
            offset += 8 + size
        if document is None:
            raise ValueError('Missing GLB JSON')
    else:
        document = json.loads(path.read_text(encoding='utf-8-sig'))
    return document, binary


def measure_gltf(path):
    path = Path(path)
    doc, binary = read_gltf(path)
    missing = []
    dependencies = []
    for item in doc.get('buffers', []) + doc.get('images', []):
        uri = item.get('uri', '')
        if uri and not uri.startswith('data:'):
            dependency = path.parent / unquote(uri)
            dependencies.append(str(dependency))
            if not dependency.is_file():
                missing.append(uri)

    def bounds(accessor_id):
        accessor = doc['accessors'][accessor_id]
        if 'min' in accessor and 'max' in accessor:
            return accessor['min'], accessor['max']
        if accessor['componentType'] != 5126 or accessor['type'] != 'VEC3' or 'sparse' in accessor:
            raise ValueError('Position accessor without supported bounds')
        view = doc['bufferViews'][accessor['bufferView']]
        buffer = doc['buffers'][view['buffer']]
        uri = buffer.get('uri')
        if uri is None:
            data = binary
        elif uri.startswith('data:'):
            data = base64.b64decode(uri.split(',', 1)[1])
        else:
            data = (path.parent / unquote(uri)).read_bytes()
        offset = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
        stride = view.get('byteStride', 12)
        values = [struct.unpack_from('<fff', data, offset + stride * i) for i in range(accessor['count'])]
        return [min(p[i] for p in values) for i in range(3)], [max(p[i] for p in values) for i in range(3)]

    mesh_metrics = []
    for mesh in doc.get('meshes', []):
        points, triangles, primitive_count = [], 0, 0
        for primitive in mesh['primitives']:
            if 'POSITION' not in primitive.get('attributes', {}):
                continue
            low, high = bounds(primitive['attributes']['POSITION'])
            points += list(itertools.product(*zip(low, high)))
            accessor_id = primitive.get('indices', primitive['attributes']['POSITION'])
            count = doc['accessors'][accessor_id]['count']
            mode = primitive.get('mode', 4)
            triangles += count // 3 if mode == 4 else max(0, count - 2) if mode in (5, 6) else 0
            primitive_count += 1
        mesh_metrics.append({'points': points, 'triangles': triangles, 'primitives': primitive_count})
    scene_points = []
    instance_triangles = instances = primitives = 0

    def visit(index, parent, ancestors):
        nonlocal instance_triangles, instances, primitives
        if index in ancestors:
            raise ValueError('Cyclic glTF scene')
        node = doc['nodes'][index]
        matrix = multiply(parent, transform(node))
        if 'mesh' in node:
            mesh = mesh_metrics[node['mesh']]
            instances += 1
            instance_triangles += mesh['triangles']
            primitives += mesh['primitives']
            for point in mesh['points']:
                scene_points.append([sum(matrix[i][j] * point[j] for j in range(3)) + matrix[i][3] for i in range(3)])
        for child in node.get('children', []):
            visit(child, matrix, ancestors | {index})

    scenes = doc.get('scenes', [])
    if scenes:
        roots = scenes[doc.get('scene', 0)].get('nodes', [])
    else:
        children = {child for node in doc.get('nodes', []) for child in node.get('children', [])}
        roots = [i for i in range(len(doc.get('nodes', []))) if i not in children]
    for index in roots:
        visit(index, identity(), set())
    return {'method': 'glTF default scene; transformed accessor bounds, conservative AABB; no skin, morph or animation evaluation',
            'axis': 'Y_UP', 'source_bounds_xyz': dimensions(scene_points), 'source_units': 'glTF nominal meters; author scale may be wrong',
            'unique_meshes': len(mesh_metrics), 'mesh_instances': instances, 'primitive_instances': primitives,
            'triangles_unique_meshes': sum(m['triangles'] for m in mesh_metrics), 'triangles_scene_instances': instance_triangles,
            'materials': len(doc.get('materials', [])), 'images': len(doc.get('images', [])),
            'skin_joint_counts': [len(s['joints']) for s in doc.get('skins', [])],
            'animation_names': [a.get('name', str(i)) for i, a in enumerate(doc.get('animations', []))],
            'external_dependencies': dependencies, 'missing_dependencies': missing}


def measure_obj(path):
    points, triangles, missing = [], 0, []
    path = Path(path)
    for line in path.read_text(encoding='utf-8-sig', errors='replace').splitlines():
        parts = line.strip().split()
        if parts and parts[0] == 'v':
            points.append([float(value) for value in parts[1:4]])
        elif parts and parts[0] == 'f':
            triangles += max(0, len(parts) - 3)
        elif parts and parts[0] == 'mtllib':
            name = line.strip()[7:].strip()
            if not (path.parent / name).is_file():
                missing.append(name)
    return {'method': 'OBJ vertices and polygon fan triangle estimate; no scene transforms', 'axis': 'author_defined',
            'source_units': 'unspecified', 'source_bounds_xyz': dimensions(points), 'triangles_scene_instances': triangles,
            'vertices': len(points), 'missing_dependencies': missing}


def measure_dae(path):
    doc = ET.parse(path).getroot()
    ns = {'c': doc.tag.split('}')[0].strip('{')}
    points, triangles = [], 0
    for geometry in doc.findall('.//c:library_geometries/c:geometry', ns):
        vertex_ids = {node.get('source', '').lstrip('#') for node in geometry.findall('.//c:vertices/c:input', ns) if node.get('semantic') == 'POSITION'}
        for source in geometry.findall('.//c:source', ns):
            if source.get('id') in vertex_ids:
                values = [float(v) for v in source.find('c:float_array', ns).text.split()]
                points += [values[i:i+3] for i in range(0, len(values), 3)]
        for primitive in geometry.findall('.//c:triangles', ns):
            triangles += int(primitive.get('count', 0))
        for counts in geometry.findall('.//c:polylist/c:vcount', ns):
            triangles += sum(max(0, int(v) - 2) for v in counts.text.split())
    unit = doc.find('c:asset/c:unit', ns)
    up = doc.findtext('c:asset/c:up_axis', default='unknown', namespaces=ns)
    return {'method': 'DAE library geometry only; scene instance transforms NOT applied; scene scale remains an S10 import check',
            'axis': up, 'source_units': 'author mesh units', 'declared_unit_meter': float(unit.get('meter', 1)) if unit is not None else 1,
            'raw_geometry_bounds_xyz': dimensions(points), 'triangles_unique_meshes': triangles,
            'missing_dependencies': []}

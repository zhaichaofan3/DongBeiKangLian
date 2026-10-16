"""Head-weighted helmet paint and moustache, fitted to the existing source surfaces."""
import math
import bpy
import bmesh
from mathutils import Vector

NAMES = ('GuardHelmetMark', 'GuardMoustache')

def material(name, rgb):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.use_nodes = True
    mat.diffuse_color = (*rgb, 1)
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*rgb, 1)
    shader.inputs['Roughness'].default_value = .9
    shader.inputs['Metallic'].default_value = 0
    return mat

def project(surface, x, y, offset):
    # Author in game coordinates (Y up, -Z forward), cast in Blender space.
    inverse = surface.matrix_world.inverted()
    origin = inverse @ Vector((x, .5, y))
    direction = inverse.to_3x3() @ Vector((0, -1, 0))
    hit, point, normal, _ = surface.ray_cast(origin, direction)
    if not hit:
        raise RuntimeError(f'Identity surface miss: {surface.name} at {x}, {y}')
    return surface.matrix_world @ point + (surface.matrix_world.to_3x3() @ normal).normalized() * offset

def mesh(name, vertices, faces, mat, armature):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    bm = bmesh.new(); bm.from_mesh(data)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(data); bm.free()
    obj = bpy.data.objects.new(name, data)
    bpy.context.collection.objects.link(obj)
    obj.data.materials.append(mat)
    for polygon in data.polygons: polygon.use_smooth = True
    obj.vertex_groups.new(name='Head').add(list(range(len(vertices))), 1, 'REPLACE')
    mod = obj.modifiers.new('Field skin', 'ARMATURE'); mod.object = armature
    obj.parent = armature
    return obj

def add_friendly_cap_star(armature):
    cap = bpy.data.objects['Cap']
    center = project(cap, 0, 1.705, .0015)
    vertices = [center]
    for i in range(10):
        angle = math.pi / 2 + i * math.pi / 5
        radius = .025 if i % 2 == 0 else .0105
        vertices.append(project(cap, math.cos(angle) * radius,
                                1.705 + math.sin(angle) * radius, .0015))
    return mesh('FriendlyCapStar', vertices,
                [(0, i + 1, (i + 1) % 10 + 1) for i in range(10)],
                material('FriendlyRedStar', (.72, .018, .012)), armature)


def add_guard_identity(armature):
    for name in NAMES:
        old = bpy.data.objects.get(name)
        if old: bpy.data.objects.remove(old, do_unlink=True)
    helmet = bpy.data.objects['Helmet']
    face = bpy.data.objects['Face']
    # A 62 mm painted circle, 6 mm stroke, offset less than a millimetre.
    vertices = []
    faces = []
    sides = 64
    for radius in [.025, .031]:
        for i in range(sides):
            angle = math.tau * i / sides
            vertices.append(project(helmet, math.cos(angle)*radius, 1.706+math.sin(angle)*radius, .0009))
    for i in range(sides):
        j=(i+1)%sides
        faces.append((i,j,sides+j,sides+i))
    mark = mesh(NAMES[0], vertices, faces, material('GuardRedPaint', (.58,.013,.009)), armature)
    # Two gently tapered lobes with a small centre part and a raised hair surface.
    vertices=[];faces=[]
    columns=20;rows=4
    for sign in [-1,1]:
        base=len(vertices)
        for i in range(columns+1):
            t=i/columns
            x=sign*(.0035+.037*t)
            center_y=1.5455-.011*t+.001*math.sin(math.pi*t)
            width=.0045*(math.sin(math.pi*(.13+.87*t))**.55)+.00015
            for j in range(rows+1):
                u=2*j/rows-1
                y=center_y+u*width
                lift=.0008+.0015*(1-u*u)*math.sin(math.pi*t)
                vertices.append(project(face,x,y,lift))
        for i in range(columns):
            for j in range(rows):
                a=base+i*(rows+1)+j
                faces.append((a,a+rows+1,a+rows+2,a+1))
    moustache=mesh(NAMES[1],vertices,faces,material('GuardFacialHair',(.018,.012,.008)),armature)
    return [mark,moustache]

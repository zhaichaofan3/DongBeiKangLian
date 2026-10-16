"""Build an editable, skinned field character for the existing Godot actor rig.

Head/eyes/hands derive from Quaternius Universal Base Characters (CC0).
Clothing, equipment, fabric textures and the game skeleton are authored here.
All geometry helpers take Godot coordinates: metres, Y up, -Z forward.
"""
import bpy
import bmesh
import math
import json
import hashlib
import sys
from pathlib import Path
from mathutils import Vector
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from guard_identity_geometry import add_guard_identity, add_friendly_cap_star
OUT = ROOT / 'GodotProject/assets/characters'
SOURCE = ROOT / 'AssetLibrary/characters/field_character'
OUT.mkdir(parents=True, exist_ok=True)
SOURCE.mkdir(parents=True, exist_ok=True)
BASE = next((ROOT/'AssetLibrary/characters/quaternius_base_characters').rglob('Superhero_Male_FullBody.gltf'))
NODES = {}
MATS = {}
PARTS = {}

def xyz(p):
    return Vector((p[0], -p[2], p[1]))

def godot(p):
    return Vector((p[0], p[2], -p[1]))

def material(name, color, rough=.85, metal=0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    shader = m.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*color, 1)
    shader.inputs['Roughness'].default_value = rough
    shader.inputs['Metallic'].default_value = metal
    MATS[name] = m
    return m

def fabric(mat, name, scale=1):
    # A packed portable texture, rather than a Blender-only procedural shader.
    size = 512
    rng = np.random.default_rng(1938 + int(scale*10))
    yy, xx = np.mgrid[:size, :size]
    weave = np.sin(xx*math.pi/2)*.025 + np.sin(yy*math.pi/2)*.02
    mottle = .024*np.sin(xx*.031+np.cos(yy*.044)) + .018*np.sin(yy*.071)
    gray = np.clip(.72 + weave + mottle + rng.normal(0,.018,(size,size)),0,1)
    rgba = np.ones((size,size,4),dtype=np.float32)
    rgba[:,:,:3] = gray[:,:,None]
    im = bpy.data.images.new(name, width=size, height=size)
    im.pixels.foreach_set(rgba.ravel())
    im.filepath_raw = str(SOURCE/(name+'.png'))
    im.file_format = 'PNG'; im.save(); im.pack()
    nodes = mat.node_tree.nodes; links=mat.node_tree.links
    tex = nodes.new('ShaderNodeTexImage'); tex.image=im
    links.new(tex.outputs['Color'],nodes.get('Principled BSDF').inputs['Base Color'])
    # Exported base_color_factor supplies the role colour in Godot.
    mat.diffuse_color = (.55,.56,.48,1)

def mesh_obj(name, vertices, faces, mat, weights=None, uvs=None):
    me = bpy.data.meshes.new(name)
    me.from_pydata([xyz(v) for v in vertices], [], faces)
    me.update()
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(MATS[mat] if isinstance(mat,str) else mat)
    for p in me.polygons: p.use_smooth=True
    uv = me.uv_layers.new(name='UVMap')
    for poly in me.polygons:
        for li in poly.loop_indices:
            vi = me.loops[li].vertex_index
            v=vertices[vi]
            uv.data[li].uv = uvs[vi] if uvs else (v[0]*2+v[2]*.3, v[1]*2)
    if weights:
        groups={}
        for i,v in enumerate(vertices):
            for bone,weight in weights(Vector(v)).items():
                if weight > .00001:
                    if bone not in groups: groups[bone]=ob.vertex_groups.new(name=bone)
                    groups[bone].add([i],weight,'REPLACE')
    return ob

def rigid(bone):
    return lambda p:{bone:1.0}

def add(part, ob):
    PARTS.setdefault(part,[]).append(ob)
    return ob

def loft(part, name, rings, mat, weight, sides=32, ripple=0, cap=True):
    # Ring = centre x/y/z, radius x/z. Cloth folds are shallow, not separate strips.
    vs=[]; uv=[]
    for ri,(x,y,z,rx,rz) in enumerate(rings):
        for s in range(sides):
            a=2*math.pi*s/sides
            r=1+ripple*(math.sin(a*7+y*35)*.65+math.cos(a*11-y*28)*.35)
            vs.append((x+math.cos(a)*rx*r,y,z+math.sin(a)*rz*r))
            uv.append((s/sides*1.6,y*2.4))
    fs=[]
    for i in range(len(rings)-1):
        for s in range(sides):
            sn=(s+1)%sides
            fs.append((i*sides+s,i*sides+sn,(i+1)*sides+sn,(i+1)*sides+s))
    if cap:
        fs.append(tuple(reversed(range(sides))))
        fs.append(tuple((len(rings)-1)*sides+s for s in range(sides)))
    ob=mesh_obj(name,vs,fs,mat,weight,uv)
    # Recalculate regardless of ring direction.
    bm=bmesh.new(); bm.from_mesh(ob.data)
    bmesh.ops.recalc_face_normals(bm,faces=bm.faces)
    bm.to_mesh(ob.data);bm.free()
    return add(part,ob)

def box(part,name,at,size,mat,bone,bevel=.008,rotation=None):
    bpy.ops.mesh.primitive_cube_add(size=1,location=xyz(at))
    ob=bpy.context.object; ob.name=name
    ob.dimensions=(size[0],size[2],size[1])
    if rotation: ob.rotation_euler=rotation
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=ob.modifiers.new('Soft stitched edges','BEVEL');mod.width=bevel;mod.segments=3
        bpy.ops.object.modifier_apply(modifier=mod.name)
    ob.data.materials.append(MATS[mat])
    for p in ob.data.polygons:p.use_smooth=True
    vg=ob.vertex_groups.new(name=bone);vg.add(list(range(len(ob.data.vertices))),1,'REPLACE')
    return add(part,ob)

def ellipsoid(part,name,at,size,mat,bone,segments=24,rings=12):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,radius=1,location=xyz(at))
    ob=bpy.context.object;ob.name=name
    ob.scale=(size[0]/2,size[2]/2,size[1]/2)
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    ob.data.materials.append(MATS[mat])
    for p in ob.data.polygons:p.use_smooth=True
    vg=ob.vertex_groups.new(name=bone);vg.add(list(range(len(ob.data.vertices))),1,'REPLACE')
    return add(part,ob)

def cord(part,name,points,radius,mat,bone):
    curve=bpy.data.curves.new(name,'CURVE');curve.dimensions='3D'
    curve.resolution_u=2;curve.bevel_depth=radius;curve.bevel_resolution=2
    sp=curve.splines.new('POLY');sp.points.add(len(points)-1)
    for p,co in zip(sp.points,points):p.co=(*xyz(co),1)
    ob=bpy.data.objects.new(name,curve);bpy.context.collection.objects.link(ob)
    bpy.context.view_layer.objects.active=ob;ob.select_set(True)
    bpy.ops.object.convert(target='MESH')
    ob=bpy.context.object;ob.data.materials.append(MATS[mat])
    vg=ob.vertex_groups.new(name=bone);vg.add(list(range(len(ob.data.vertices))),1,'REPLACE')
    ob.select_set(False)
    return add(part,ob)

def smooth_weight(value):
    t=max(0,min(1,value))
    return t*t*(3-2*t)


def weights_torso(p):
    hip=smooth_weight((1.03-p.y)/.22)
    return {'Chest':1-hip,'Hips':hip}


def weights_sleeve(side):
    def w(p):
        # Weight by the garment part, so inner sleeve vertices never stick to
        # the waist. Only the overlapping shoulder cap follows the chest.
        chest=.40*smooth_weight((p.y-1.325)/.05)
        elbow=smooth_weight((1.12-p.y)/.13)
        return {'Chest':chest,f'Shoulder{side}':(1-chest)*(1-elbow),
                f'Elbow{side}':(1-chest)*elbow}
    return w

def weights_leg(side):
    def w(p):
        knee=max(0,min(1,(.54-p.y)/.15))
        ankle=max(0,min(1,(.20-p.y)/.08))
        return {f'Thigh{side}':1-knee,f'Knee{side}':knee*(1-ankle),f'Foot{side}':knee*ankle}
    return w

def smooth_apply(ob, voxel=None):
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
    if voxel:
        ob.data.remesh_voxel_size=voxel
        bpy.ops.object.voxel_remesh()
    mod=ob.modifiers.new('Tailored soft cloth','SMOOTH');mod.factor=.65;mod.iterations=4
    bpy.ops.object.modifier_apply(modifier=mod.name)
    if voxel:
        mod=ob.modifiers.new('Game topology density','DECIMATE');mod.ratio=.42
        bpy.ops.object.modifier_apply(modifier=mod.name)
    for p in ob.data.polygons:p.use_smooth=True

def join_part(part):
    obs=PARTS[part]
    bpy.ops.object.select_all(action='DESELECT')
    for ob in obs:ob.select_set(True)
    bpy.context.view_layer.objects.active=obs[0]
    bpy.ops.object.join();ob=bpy.context.object;ob.name=part
    bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    PARTS[part]=[ob]
    return ob

def reweight(ob, fn):
    ob.vertex_groups.clear();groups={}
    for v in ob.data.vertices:
        for name,weight in fn(godot(v.co)).items():
            if weight>.00001:
                if name not in groups:groups[name]=ob.vertex_groups.new(name=name)
                groups[name].add([v.index],weight,'REPLACE')
    if not ob.data.uv_layers:ob.data.uv_layers.new(name='UVMap')
    uv=ob.data.uv_layers.active
    for p in ob.data.polygons:
        n=godot(p.normal)
        for li in p.loop_indices:
            v=godot(ob.data.vertices[ob.data.loops[li].vertex_index].co)
            uv.data[li].uv=((v.x if abs(n.z)>abs(n.x) else v.z)*2.4,v.y*2.4)

def source_parts():
    bpy.ops.import_scene.gltf(filepath=str(BASE))
    imported=list(bpy.context.selected_objects)
    body=next(o for o in imported if o.type=='MESH' and o.name.startswith('SuperHero'))
    for ob in imported:
        if ob.type!='MESH' or ob.name.startswith('Icosphere'):continue
        if ob==body or ob.name in ['Eyes','Eyebrows']:
            head=ob.copy();head.data=ob.data.copy();bpy.context.collection.objects.link(head)
            head.parent=None;head.matrix_world=ob.matrix_world.copy();head.modifiers.clear()
            bm=bmesh.new();bm.from_mesh(head.data)
            bmesh.ops.delete(bm,geom=[v for v in bm.verts if v.co.z<1.53],context='VERTS')
            bm.to_mesh(head.data);bm.free()
            for v in head.data.vertices:
                s=v.co.copy()
                # Broader cheek planes, less tapered superhero jaw, restrained nose.
                width=1.10 + .05*math.exp(-((s.z-1.63)/.035)**2)
                front=s.y*.96
                if s.y<-.09:front=-.086+(s.y+.09)*.78
                at=Vector((-s.x*width,1.507+(s.z-1.60)*.94,front))
                if s.z<1.615 and s.y>-.040:
                    # Reshape the original connected neck into the collar; do
                    # not leave cut shoulder flaps or add a separate cylinder.
                    t=max(0,min(1,(s.z-1.53)/.085))
                    at.y=1.374+t*(1.5211-1.374)
                    radius=.062+.004*math.sin(t*math.pi)
                    length=math.sqrt(at.x*at.x+(at.z-.012)**2)
                    if length>radius:
                        ratio=radius/length
                        at.x*=ratio;at.z=.012+(at.z-.012)*ratio
                v.co=xyz(at)
            head.vertex_groups.clear()
            groups={name:head.vertex_groups.new(name=name) for name in ['Head','Chest']}
            for v in head.data.vertices:
                p=godot(v.co)
                chest=max(0,min(1,(1.49-p.y)/.10)) if p.z>-.04 else 0.0
                groups['Head'].add([v.index],1-chest,'REPLACE')
                groups['Chest'].add([v.index],chest,'REPLACE')
            bpy.ops.object.select_all(action='DESELECT');head.select_set(True);bpy.context.view_layer.objects.active=head
            if head.data.has_custom_normals:
                bpy.ops.mesh.customdata_custom_splitnormals_clear()
            if ob==body:
                sub=head.modifiers.new('Face surface refinement','SUBSURF');sub.levels=1
                bpy.ops.object.modifier_apply(modifier=sub.name)
            for m in head.data.materials:
                if m:
                    if m.name.startswith('MI_Superhero'):m.name='SkinFace'
                    elif m.name.startswith('MI_Eyes'):m.name='Eyes'
                    elif m.name.startswith('MI_Hair'):m.name='Brows'
                    if m.use_nodes:
                        sh=m.node_tree.nodes.get('Principled BSDF')
                        if sh:sh.inputs['Roughness'].default_value=.63 if m.name=='Eyes' else .87
                        if m.name=='SkinFace':
                            for node in m.node_tree.nodes:
                                if node.type=='NORMAL_MAP':node.inputs['Strength'].default_value=.3
            for p in head.data.polygons:p.use_smooth=True
            add('Face',head)
    # Retain actual fingers and UVs, fold them into a relaxed hand shape.
    for gripping in [False,True]:
        for side in range(2):
            sign=-1 if side==0 else 1
            hand=body.copy();hand.data=body.data.copy();bpy.context.collection.objects.link(hand)
            hand.parent=None;hand.matrix_world=body.matrix_world.copy();hand.modifiers.clear()
            bm=bmesh.new();bm.from_mesh(hand.data)
            bmesh.ops.delete(bm,geom=[v for v in bm.verts if sign*v.co.x<.695],context='VERTS')
            bm.to_mesh(hand.data);bm.free()
            for v in hand.data.vertices:
                s=v.co.copy();d=max(0,abs(s.x)-.7065)
                bend=max(0,d-.065)
                height=.822-d*.69+bend*.14
                front=(s.y-.0654)*.72-bend*.32
                if gripping and d>.065:
                    # Curl all finger surface vertices around a 19mm stock grip.
                    t=min(math.pi*1.13,(d-.065)/.135*math.pi*1.13)
                    height=.777-math.sin(t)*.027
                    front=(s.y-.0654)*.45-(1-math.cos(t))*.022
                v.co=xyz((sign*.270+(s.z-1.4555)*.72,height,front))
            hand.vertex_groups.clear();vg=hand.vertex_groups.new(name=f'Elbow{side}')
            vg.add(list(range(len(hand.data.vertices))),1,'REPLACE')
            bpy.ops.object.select_all(action='DESELECT');hand.select_set(True);bpy.context.view_layer.objects.active=hand
            if hand.data.has_custom_normals:bpy.ops.mesh.customdata_custom_splitnormals_clear()
            for p in hand.data.polygons:p.use_smooth=True
            add('GuardHands' if gripping else 'Hands',hand)
    for ob in imported:
        if ob.name in bpy.data.objects:bpy.data.objects.remove(ob,do_unlink=True)

def outfit():
    material('Coat',(.44,.46,.34));fabric(MATS['Coat'],'field_cotton_weave')
    material('Wool',(.18,.21,.18));fabric(MATS['Wool'],'field_wool_weave',2)
    material('Leather',(.11,.075,.046),.77)
    material('LeatherEdge',(.23,.16,.09),.81)
    material('Metal',(.18,.20,.16),.62,.35)
    material('Brass',(.37,.30,.16),.5,.6)
    material('Linen',(.55,.53,.43),.97)
    material('Seam',(.24,.27,.19),.95)
    material('Rubber',(.035,.039,.03),.96)
    material('Hair',(.035,.03,.024),.96)
    material('Stain',(.23,.13,.095),.94)
    # Tailor the body and sleeves separately; voxel-union at the armpits would
    # create a web between the inner sleeve and the coat down to the belt.
    torso=[(.79,.213,.143),(.82,.218,.147),(.88,.207,.15),(.94,.185,.14),(1.02,.18,.143),(1.12,.187,.149),(1.24,.216,.157),(1.32,.229,.150),(1.37,.20,.123),(1.40,.088,.075)]
    coat=loft('Clothing','CoatBody',[(0,y,0,x,z) for y,x,z in torso],'Coat',weights_torso,48,.018)
    smooth_apply(coat,.0075);reweight(coat,weights_torso)
    for side in range(2):
        sign=-1 if side==0 else 1
        sleeve=[(1.375,.243,.071,.079),(1.33,.255,.087,.090),(1.26,.270,.089,.091),(1.19,.280,.083,.083),(1.12,.284,.075,.078),(1.085,.282,.074,.076),(1.055,.280,.073,.075),(1.025,.279,.072,.074),(1.00,.277,.070,.072),(.95,.275,.064,.066),(.88,.272,.056,.058),(.823,.270,.050,.051)]
        ob=loft('Clothing','Sleeve',[(sign*x,y,0,rx,rz) for y,x,rx,rz in sleeve],'Coat',weights_sleeve(side),32,.025)
        smooth_apply(ob);reweight(ob,weights_sleeve(side))
    # Waist gathers and continuous trousers include soft knee deformation.
    for side in range(2):
        sign=-1 if side==0 else 1
        rings=[(.88,.108,.105),(.80,.108,.111),(.71,.102,.111),(.62,.093,.099),(.54,.086,.089),(.48,.079,.083),(.43,.081,.084),(.37,.078,.080),(.30,.069,.073),(.22,.060,.064),(.145,.052,.056)]
        loft('Trousers','TrouserLeg',[(sign*.118,y,0,rx,rz) for y,rx,rz in rings],'Coat',weights_leg(side),32,.036)
        # Puttees with overlapping diagonal cloth winding rather than separated rings.
        for wrap in range(7):
            y=.20+wrap*.027;rx=.059+wrap*.0035
            points=[]
            for j in range(49):
                a=2*math.pi*j/48
                points.append((sign*.118+math.cos(a)*rx,y+j/48*.027,math.sin(a)*(rx+.006)))
            cord('Trousers','PutteeEdge',points,.004,'Wool',f'Knee{side}')
        loft('Boots','LeatherBoot',[(sign*.118,.012,-.042,.080,.143),(sign*.118,.035,-.045,.084,.147),(sign*.118,.07,-.042,.080,.140),(sign*.118,.107,-.011,.060,.086),(sign*.118,.17,0,.052,.059)],'Leather',rigid(f'Foot{side}'),32)
        loft('Boots','BootSole',[(sign*.118,.005,-.043,.085,.151),(sign*.118,.027,-.043,.086,.151)],'Rubber',rigid(f'Foot{side}'),32)
        for lace in range(4):
            y=.101-lace*.009;z=-.067-lace*.018
            cord('Boots','Laces',[(sign*.118-.032,y,z),(sign*.118+.032,y-.004,z-.013)],.0022,'Linen',f'Foot{side}')
        # Reinforced sleeve cuff and stitched outer trouser seam.
        loft('Cuffs','SleeveCuff',[(sign*.270,.818,0,.052,.054),(sign*.270,.85,0,.055,.057)],'Wool',rigid(f'Elbow{side}'),32)
    # Curved leather belt tracks the padded waist.
    loft('Belt','WaistBelt',[(0,.917,0,.215,.153),(0,.961,0,.211,.150)],'Leather',rigid('Chest'),48)
    box('Belt','Buckle',(0,.94,-.163),(.060,.050,.014),'Brass','Chest',.006)
    box('Belt','BuckleInner',(0,.94,-.173),(.043,.030,.009),'Leather','Chest',.003)
    box('Details','FrontPlacket',(0,1.153,-.160),(.031,.335,.014),'Coat','Chest',.006)
    for y in [1.03,1.105,1.18,1.255,1.33]:
        ellipsoid('Details','CoatButton',(0,y,-.174),(.014,.014,.007),'Brass','Chest',12,8)
    for sign in [-1,1]:
        box('Details','BreastPocket',(sign*.117,1.218,-.149),(.125,.134,.025),'Coat','Chest',.012)
        box('Details','PocketFlap',(sign*.117,1.277,-.165),(.135,.038,.014),'Coat','Chest',.007)
        ellipsoid('Details','PocketButton',(sign*.117,1.272,-.177),(.011,.011,.006),'Brass','Chest',12,8)
        for j in range(8):
            box('Details','PocketStitch',(sign*.117-.050+j*.014,1.157,-.164),(.006,.0015,.002),'Linen','Chest',.0005)
        box('Details','HipPocket',(sign*.142,.852,-.136),(.124,.041,.023),'Coat','Hips',.007)
        # Broad rounded stand collar with separate folded collar points.
        box('Details','Collar',(sign*.063,1.387,-.093),(.093,.070,.030),'Coat','Chest',.012,rotation=(0,sign*.18,sign*.25))
    # Scarf and tail, travel pack, bedroll and harness.
    loft('Scarf','ScarfNeck',[(0,1.365,0,.112,.096),(0,1.404,0,.105,.087),(0,1.431,0,.093,.080)],'Wool',rigid('Chest'),40,.025)
    box('Scarf','ScarfTail',(-.078,1.277,-.181),(.068,.205,.020),'Wool','Chest',.013)
    box('Backpack','CanvasPack',(0,1.14,.231),(.30,.32,.15),'Wool','Chest',.028)
    box('Backpack','PackLid',(0,1.29,.254),(.315,.067,.163),'Coat','Chest',.017)
    box('Backpack','PackPocket',(0,1.106,.318),(.192,.17,.03),'Coat','Chest',.012)
    for sign in [-1,1]:
        cord('Backpack','ShoulderStrap',[(sign*.13,.99,-.156),(sign*.17,1.23,-.17),(sign*.185,1.37,-.064),(sign*.16,1.32,.20),(sign*.10,1.00,.311)],.016,'Leather','Chest')
        box('Backpack','PackFastener',(sign*.095,1.12,.348),(.027,.24,.009),'Leather','Chest',.004)
        box('Backpack','PackBuckle',(sign*.095,1.17,.356),(.044,.040,.012),'Brass','Chest',.004)
    roll=ellipsoid('Backpack','Bedroll',(0,1.39,.24),(.365,.125,.144),'Wool','Chest',32,16)
    for sign in [-1,1]:
        box('Backpack','BedrollTie',(sign*.115,1.437,.24),(.024,.013,.151),'Leather','Chest',.005)
    # Civilian cloth cap. Helmet is a separate guard-only mesh.
    loft('Cap','ClothCap',[(0,1.653,.005,.103,.106),(0,1.69,.008,.114,.110),(0,1.737,.011,.098,.094),(0,1.763,.012,.066,.062),(0,1.772,.012,.008,.008)],'Wool',rigid('Head'),48,.013)
    ellipsoid('Cap','CapPeak',(0,1.664,-.076),(.244,.014,.18),'Wool','Head',32,12)
    loft('Cap','CapBand',[(0,1.65,.005,.105,.108),(0,1.671,.005,.106,.109)],'Coat',rigid('Head'),48)
    for sign in [-1,1]:
        cord('Cap','CapPanelSeam',[(sign*.096,1.679,-.025),(sign*.079,1.725,-.036),(sign*.040,1.758,-.025),(0,1.771,.012)],.0015,'Seam','Head')
    loft('Helmet','HelmetShell',[(0,1.637,.009,.143,.145),(0,1.652,.009,.146,.149),(0,1.68,.009,.13,.135),(0,1.72,.009,.113,.119),(0,1.759,.009,.080,.088),(0,1.778,.009,.026,.031),(0,1.78,.009,.002,.003)],'Metal',rigid('Head'),48)
    for sign in [-1,1]:
        cord('Helmet','ChinStrap',[(sign*.11,1.66,0),(sign*.09,1.49,-.025),(sign*.045,1.462,-.081),(0,1.461,-.090)],.006,'Leather','Head')
    for sign in [-1,1]:
        box('GuardGear','AmmoPouch',(sign*.153,.938,-.191),(.104,.102,.065),'Leather','Chest',.011)
        box('GuardGear','PouchFlap',(sign*.153,.977,-.229),(.111,.029,.010),'LeatherEdge','Chest',.006)
        ellipsoid('GuardGear','PouchStud',(sign*.153,.967,-.237),(.012,.011,.006),'Brass','Chest',12,8)
    # Bandages follow head/knee, avoiding a rigid arm sling across a moving elbow.
    loft('Bandage','ForeheadWrap',[(0,1.636,0,.106,.105),(0,1.659,0,.106,.105)],'Linen',rigid('Head'),48)
    box('Bandage','HeadWrapStain',(-.046,1.647,-.097),(.025,.018,.009),'Stain','Head',.005)
    for i in range(4):
        y=.31+i*.024
        loft('Bandage','LegBandage',[(-.118,y,0,.084,.09),(-.118,y+.020,0,.084,.09)],'Linen',rigid('Knee0'),32)

def rig():
    rests={'Hips':((0,.86,0),None),'Chest':((0,1.04,0),'Hips'),'Head':((0,1.518,-.005),'Chest')}
    for side in range(2):
        sign=-1 if side==0 else 1
        rests.update({f'Thigh{side}':((sign*.118,.855,0),'Hips'),f'Knee{side}':((sign*.118,.465,0),f'Thigh{side}'),f'Foot{side}':((sign*.118,.11,0),f'Knee{side}'),f'Shoulder{side}':((sign*.243,1.33,0),'Chest'),f'Elbow{side}':((sign*.243,1.055,0),f'Shoulder{side}')})
    data=bpy.data.armatures.new('FieldSkeleton');ob=bpy.data.objects.new('FieldRig',data)
    bpy.context.collection.objects.link(ob);bpy.context.view_layer.objects.active=ob;ob.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    for name,(at,parent) in rests.items():
        b=data.edit_bones.new(name);b.head=xyz(at);b.tail=b.head+Vector((0,0,.10))
        if parent:b.parent=data.edit_bones[parent]
    bpy.ops.object.mode_set(mode='OBJECT');ob.show_in_front=True
    for part in list(PARTS):
        mesh=join_part(part)
        mod=mesh.modifiers.new('Field skin','ARMATURE');mod.object=ob
        mesh.parent=ob
    return ob

def main():
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    source_parts();outfit();arm=rig()
    for detail in add_guard_identity(arm): PARTS[detail.name]=[detail]
    star = add_friendly_cap_star(arm)
    PARTS[star.name] = [star]
    bpy.ops.object.select_all(action='SELECT')
    # Pack source textures so this is an editable standalone modelling project.
    for im in bpy.data.images:
        if im.size[0]>0 and not im.packed_file:
            try: im.pack()
            except RuntimeError: pass
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'field_character.blend'))
    bpy.ops.export_scene.gltf(filepath=str(OUT/'field_character.glb'),export_format='GLB',use_selection=True,export_animations=False,export_yup=True,export_apply=False,export_cameras=False,export_lights=False)
    meshes=[]
    for part,obs in PARTS.items():
        ob=obs[0];ob.data.calc_loop_triangles()
        meshes.append({'name':part,'vertices':len(ob.data.vertices),'triangles':len(ob.data.loop_triangles)})
    report={'asset':'field_character.glb','source_project':str(SOURCE/'field_character.blend'),'source_base':str(BASE.relative_to(ROOT)),
            'base_author':'Quaternius','base_license':'CC0-1.0','base_url':'https://quaternius.com/packs/universalbasecharacters.html',
            'adaptation':'Head, eyes, eyebrows and hands retained with UVs; reshaped head and relaxed hands. New padded clothing, equipment, textures and 13-bone game skeleton. Existing gameplay motion drives the skeleton.',
            'bone_count':len(arm.data.bones),'meshes':meshes,'all_variant_triangles':sum(m['triangles'] for m in meshes),
            'sha256':hashlib.sha256((OUT/'field_character.glb').read_bytes()).hexdigest()}
    (OUT/'provenance.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    (SOURCE/'build-report.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    print('FIELD_CHARACTER_BUILT',json.dumps(report))

main()

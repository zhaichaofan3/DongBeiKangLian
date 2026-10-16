"""Make editable, metre-scale adaptations of five downloaded buildings for S10."""
import bpy, bmesh, json, math, hashlib
from pathlib import Path
from mathutils import Vector, Matrix

ROOT=Path(__file__).resolve().parents[1]
RAW=ROOT/'AssetLibrary/environment'
SOURCE=ROOT/'AssetLibrary/derived/S10_buildings'
GAME=ROOT/'GodotProject/assets/environment/buildings'
EVIDENCE=ROOT/'docs/level/S10'
for folder in [SOURCE,GAME,EVIDENCE]: folder.mkdir(parents=True,exist_ok=True)
inspection=json.loads((EVIDENCE/'source_inspection.json').read_text(encoding='utf8'))
records=[]

def bounds(objects):
 points=[o.matrix_world@Vector(c) for o in objects for c in o.bound_box]
 return Vector([min(v[i] for v in points) for i in range(3)]),Vector([max(v[i] for v in points) for i in range(3)])

def load(slot):
 bpy.ops.wm.read_factory_settings(use_empty=True)
 path=ROOT/inspection[slot]['source']
 if path.suffix=='.blend': bpy.ops.wm.open_mainfile(filepath=str(path))
 elif path.suffix=='.fbx': bpy.ops.import_scene.fbx(filepath=str(path))
 else: bpy.ops.import_scene.gltf(filepath=str(path))
 for ob in list(bpy.context.scene.objects):
  if ob.type!='MESH': bpy.data.objects.remove(ob,do_unlink=True)
 for ob in list(bpy.context.scene.objects):
  matrix=ob.matrix_world.copy()
  ob.parent=None
  ob.data=ob.data.copy()
  ob.data.transform(matrix)
  ob.matrix_world=Matrix.Identity(4)
 return path

def meshes(): return [o for o in bpy.context.scene.objects if o.type=='MESH']

def transform(objects,matrix):
 for ob in objects: ob.data.transform(matrix)
 bpy.context.view_layer.update()

def material(name,color=(.32,.26,.18,1),image=None):
 mat=bpy.data.materials.new(name)
 mat.diffuse_color=color
 mat.use_nodes=True
 bs=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
 if bs is None:
  bs=mat.node_tree.nodes.new('ShaderNodeBsdfPrincipled')
  output=next((n for n in mat.node_tree.nodes if n.type=='OUTPUT_MATERIAL'),None) or mat.node_tree.nodes.new('ShaderNodeOutputMaterial')
  mat.node_tree.links.new(bs.outputs['BSDF'],output.inputs['Surface'])
 bs.inputs['Base Color'].default_value=color
 bs.inputs['Roughness'].default_value=.86
 if image:
  node=mat.node_tree.nodes.new('ShaderNodeTexImage')
  node.image=image
  mat.node_tree.links.new(node.outputs['Color'],bs.inputs['Base Color'])
 return mat

def texture_mat(name,asset):
 folder=ROOT/'GodotProject/assets/environment/textures'/asset
 path=next(p for p in folder.rglob('*') if p.is_file() and ('diff' in p.name or 'albedo' in p.name) and p.suffix in ['.jpg','.png'])
 return material(name,image=bpy.data.images.load(str(path)))

def cube(name,at,size,mat):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at)
 ob=bpy.context.object
 ob.name=name
 ob.scale=size
 bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 ob.data.materials.clear()
 ob.data.materials.append(mat)
 # Reproject UVs in metres; avoid stretching a single plank across a whole roof.
 uv=ob.data.uv_layers.active
 for face in ob.data.polygons:
  axis=max(range(3),key=lambda i:abs(face.normal[i]))
  dims=[i for i in range(3) if i!=axis]
  for loop in face.loop_indices:
   point=ob.data.vertices[ob.data.loops[loop].vertex_index].co
   uv.data[loop].uv=(point[dims[0]]/3,point[dims[1]]/3)
 return ob

def roof(width,depth,eave,rise,mat):
 half=width/2
 for sign in [-1,1]:
  ob=cube('Added_pitched_roof', (sign*half/2,0,eave+rise/2), (math.hypot(half,rise),depth,.16), mat)
  # Geometry was baked by cube(): rotate about its own centre around Y.
  c=Vector((sign*half/2,0,eave+rise/2))
  rotation=Matrix.Rotation(sign*math.atan2(rise,half),4,'Y')
  transform([ob],Matrix.Translation(c)@rotation@Matrix.Translation(-c))
 for y in [-depth/2,depth/2]:
  mesh=bpy.data.meshes.new('Closed_roof_gable')
  mesh.from_pydata([(-half,y,eave),(half,y,eave),(0,y,eave+rise)],[],[(0,1,2)])
  mesh.materials.append(mat)
  ob=bpy.data.objects.new('Added_closed_gable',mesh)
  bpy.context.collection.objects.link(ob)
  uv=mesh.uv_layers.new()
  for loop in mesh.loops:
   co=mesh.vertices[loop.vertex_index].co
   uv.data[loop.index].uv=(co.x/3,co.z/3)

def collisions_box(size,center=None):
 return [{'center':center or [0,size[1]/2,0],'size':size}]

def finish(slot,path,changes,collisions,door_height=None):
 for ob in meshes():
  ob.animation_data_clear()
  for mod in list(ob.modifiers): ob.modifiers.remove(mod)
  ob.data.validate(clean_customdata=False)
 # Make every used material exportable, clamp textures to the reviewed game budget.
 used={m for ob in meshes() for m in ob.data.materials if m}
 for mat in used:
  mat.use_nodes=True
  if mat.node_tree:
   for node in mat.node_tree.nodes:
    if node.type=='TEX_IMAGE' and node.image:
     im=node.image
     if max(im.size)>1024:
      factor=1024/max(im.size)
      im.scale(max(1,int(im.size[0]*factor)),max(1,int(im.size[1]*factor)))
     im.pack()
  # These are solid exteriors; glazing is shaded, not a gameplay opening.
  mat.use_backface_culling=False
 lo,hi=bounds(meshes())
 bpy.context.scene.unit_settings.system='METRIC'
 bpy.context.scene.unit_settings.scale_length=1
 bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/(slot+'.blend')))
 bpy.ops.object.select_all(action='DESELECT')
 for ob in meshes(): ob.select_set(True)
 bpy.context.view_layer.objects.active=meshes()[0]
 bpy.ops.object.join()
 bpy.context.object.name=slot+'_adapted_building'
 bpy.ops.export_scene.gltf(filepath=str(GAME/(slot+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_cameras=False,export_lights=False)
 ob=bpy.context.object
 triangles=sum(len(p.vertices)-2 for p in ob.data.polygons)
 records.append(dict(slot=slot,source=path.relative_to(ROOT).as_posix(),source_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),changes=changes,
  dimensions_godot=[hi.x-lo.x,hi.z-lo.z,hi.y-lo.y],bounds_godot={'low':[lo.x,lo.z,-hi.y],'high':[hi.x,hi.z,-lo.y]},triangles=triangles,materials=len(used),door_height_m=door_height,colliders=collisions,
  editable=(SOURCE/(slot+'.blend')).relative_to(ROOT).as_posix(),game=(GAME/(slot+'.glb')).relative_to(ROOT).as_posix()))
 print('S10 BUILT',slot,triangles,'triangles')

# D01: cottage only, so a premade terrain slab does not intersect the game ground.
path=load('D01')
for ob in list(meshes()):
 if ob.name not in ['Cottage','Door']: bpy.data.objects.remove(ob,do_unlink=True)
lo,hi=bounds(meshes())
center=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
transform(meshes(),Matrix.Rotation(math.pi,4,'Z')@Matrix.Diagonal((.01,.01,.01,1))@Matrix.Translation(-center))
finish('D01',path,['Extracted Cottage and Door; scenery slab and fence retained in original only','Centimetres to metres; front turned toward forest road','Scenic log-house reference, not a regional historical reconstruction'],collisions_box([12.7,5.5,11.8]),1.854)

# D02: preserve human-sized door; the S09 12x10 slot becomes a yard around a cabin.
path=load('D02')
image=bpy.data.images.load(str(RAW/'supplement/retro-log-cabin/extracted/log_cabin/log_cabin_1024px.png'))
wood=material('Retro_cabin_original_atlas',image=image)
for ob in meshes(): ob.data.materials.clear(); ob.data.materials.append(wood)
lo,hi=bounds(meshes())
transform(meshes(),Matrix.Diagonal((1.08,1.08,1.08,1))@Matrix.Translation(Vector((0,0,-lo.z))))
finish('D02',path,['Restored missing FBX material link to supplied 1024px atlas','Uniform scale 1.08; door approximately 2.07m','Smaller solid shell matches cabin; remaining slot is open yard'],collisions_box([6,2.9,5.9]),(1.93-.01)*1.08)

# D03: reinforce the open warehouse source with a roof and closed timber doors.
path=load('D03')
lo,hi=bounds(meshes())
center=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
transform(meshes(),Matrix.Diagonal((10/(hi.x-lo.x),17/(hi.y-lo.y),7.2/(hi.z-lo.z),1))@Matrix.Translation(-center))
wood=texture_mat('Warehouse_repair_planks','weathered_brown_planks')
metal=texture_mat('Warehouse_roof_weathered_metal','rusty_metal_04')
roof(10.6,17.6,7.15,1.1,metal)
# Backing fills holes in the downloaded corrugated walls; front is a closed service facade.
cube('Closed_west_wall',(-4.78,0,3.45),(.15,16.8,6.9),wood)
cube('Closed_east_wall',(4.78,0,3.45),(.15,16.8,6.9),wood)
for side in [-1,1]:
 cube('Closed_gable_wall',(0,side*8.36,3.5),(9.6,.18,7),wood)
 for x in [-2.6,2.6]:
  cube('Storage_window',(x,side*8.49,4.6),(1.5,.08,1.2),material('Dusty_glass',(.16,.21,.20,1)))
 cube('Closed_timber_loading_door',(0,side*8.51,1.65),(3.2,.12,3.3),wood)
 for x in [-1.4,1.4]: cube('Door_vertical_iron_strap',(x,side*8.59,1.65),(.1,.05,3.1),metal)
finish('D03',path,['Scaled source to10x17m; wall height7.2m','Added pitched roof, closed gables, timber wall backing and closed loading doors','Original steel/corrugated structure preserved; no playable interior'],collisions_box([10,7.2,17]),3.3)

# D04: assemble selected facade panels, not the supplier display grid.
path=load('D04')
templates={o.name:o for o in meshes()}
for ob in templates.values(): ob.hide_render=True; ob.hide_set(True)
brick=bpy.data.materials['modular_factory_facade_brick']
wood=texture_mat('Factory_timber_doors','weathered_brown_planks')
roofmat=texture_mat('Factory_grey_roof','grey_roof_tiles')
used_parts=[]
def copy_panel(name,origin,offset,angle=0,scale_x=1):
 src=templates[name]
 ob=bpy.data.objects.new('Assembled_'+name,src.data.copy())
 bpy.context.collection.objects.link(ob)
 matrix=Matrix.Translation(Vector(offset))@Matrix.Rotation(angle,4,'Z')@Matrix.Diagonal((scale_x,1,1,1))@Matrix.Translation(-Vector(origin))
 ob.data.transform(matrix)
 used_parts.append(name)
 return ob
for side in [-1,1]:
 angle=0 if side==-1 else math.pi
 for i in range(8):
  # Supplier fronts face -Y; rotate the opposite elevation to face +Y.
  x=(-10.325+i*2.95) * (1 if side==-1 else -1)
  if i in [3,4]:
   copy_panel('wall_standard_standard_01',(-18.5,0,0),(x,side*5.8,0),angle,2.95/3)
  else:
   for name in ['wall_window_centered_large_01','window_centered_large_01']:
    copy_panel(name,(1.5,0,4),(x,side*5.8,0),angle,2.95/3)
 cube('Factory_upper_brick_band',(0,side*5.73,3.9),(23.6,.16,1.8),brick)
 cube('Factory_closed_loading_door',(0,side*5.88,1.3),(4,.12,2.6),wood)
 for x in [-1.9,0,1.9]: cube('Loading_door_brace',(x,side*5.97,1.3),(.08,.05,2.5),roofmat)
for side in [-1,1]:
 angle=math.pi/2 if side==1 else -math.pi/2
 for i in range(4):
  y=-4.35+i*2.9
  for name in ['wall_window_centered_large_01','window_centered_large_01']:
   copy_panel(name,(1.5,0,4),(side*11.8,y,0),angle,2.9/3)
 cube('Factory_end_upper_band',(side*11.73,0,3.9),(.16,11.6,1.8),brick)
for ob in templates.values(): bpy.data.objects.remove(ob,do_unlink=True)
cube('Factory_closed_interior',(0,0,2.25),(23.1,11.1,4.5),material('Unlit_interior',(.045,.04,.035,1)))
cube('Factory_floor',(0,0,.06),(23.6,11.6,.12),brick)
roof(24,12,4.82,2.05,roofmat)
for x in [-11.7,11.7]:
 for y in [-5.7,5.7]: cube('Factory_corner_pier',(x,y,2.4),(.3,.3,4.8),brick)
finish('D04',path,['Assembled24 facade bays from original wall/window modules','Added solid backings, full roof, gables, corners and closed timber doors','Omitted modern garage doors and unused display-grid parts;1K packed textures'],collisions_box([23.6,4.8,11.6]),2.6)

# D05: shell of the sawmill, without an unexplained operating waterwheel.
path=load('D05')
keep={'RoofFrame','Roof','WoodenFrame','Floor'}
for ob in list(meshes()):
 if ob.name not in keep: bpy.data.objects.remove(ob,do_unlink=True)
# Restore legacy Blender Internal materials explicitly from packed source images.
mapping={'Wood':'Wood.jpg','TreeLogEdgeWeathered':'TreeLogEdgeWeathered.jpg','RoofTiles':'RoofTiles.jpg'}
for mat in list(bpy.data.materials):
 if mat.name in mapping:
  replacement=material('Sawmill_'+mat.name,image=bpy.data.images.get(mapping[mat.name]))
  for ob in meshes():
   for i,slot in enumerate(ob.material_slots):
    if slot.material==mat: ob.data.materials[i]=replacement
lo,hi=bounds(meshes())
center=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
transform(meshes(),Matrix.Diagonal((11.4/(hi.x-lo.x),5.65/(hi.y-lo.y),4.85/(hi.z-lo.z),1))@Matrix.Translation(-center))
# Simplified post colliders from low connected pieces of the source timber frame.
frame=bpy.data.objects.get('WoodenFrame')
bm=bmesh.new(); bm.from_mesh(frame.data)
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.001)
# After baking the source's object transforms, the low frame posts start at
# roughly 2 m in the adapted local frame; retain their lower section.
bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),plane_co=(0,0,3.0),plane_no=(0,0,1),clear_outer=True)
seen=set(); cols=[]
components=[]
for start in bm.verts:
 if start in seen: continue
 todo=[start]; component=[]; seen.add(start)
 while todo:
  vertex=todo.pop(); component.append(vertex.co.copy())
  for edge in vertex.link_edges:
   other=edge.other_vert(vertex)
   if other not in seen: seen.add(other); todo.append(other)
 low=Vector([min(p[i] for p in component) for i in range(3)])
 high=Vector([max(p[i] for p in component) for i in range(3)])
 size=high-low
 components.append({'low':list(low),'high':list(high)})
 # The four pairs of low posts are the only narrow x/y components after
 # the shell transform. Their height varies with the source's axis scale.
 if size.x<.65 and size.y<.65:
  mid=(low+high)/2
  cols.append({'center':[mid.x,mid.z,-mid.y],'size':[max(size.x,.22),size.z,max(size.y,.22)]})
bm.free()
(EVIDENCE/'sawmill-post-components.json').write_text(json.dumps(components,indent=2),encoding='utf8')
assert len(cols)>=4, f'Sawmill low post extraction failed: {len(cols)}'
cols.append({'center':[0,4.05,0],'size':[11.4,.2,5.65]})
finish('D05',path,['Kept original timber frame, roof framing, roof and floor','Removed waterwheel, submerged foundation and powered saw mechanism; originals remain untouched','Scaled shell into11.4x5.65m plot, roof4.85m; low post collision derived from timber pieces','D07 stock still shares this roof; detailed production dressing remains S11'],cols)

(GAME/'buildings.json').write_text(json.dumps({'step':'S10','buildings':records},ensure_ascii=False,indent=2),encoding='utf8')
(EVIDENCE/'build_manifest.json').write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding='utf8')
print('S10 BUILD COMPLETE')

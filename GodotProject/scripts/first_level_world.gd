extends RefCounted
const Layout = preload("res://scripts/first_level_layout.gd")
const Scenery = preload("res://scripts/first_level_scenery.gd")
var scenery := Scenery.new()
var _world: WeakRef
var w: RefCounted:
	get: return _world.get_ref()
var edges: Dictionary = {}
var base_solid := PackedByteArray()
var ready := false
var structure_footprints: Array[Rect2]=[]
var berm_samples: Array[Dictionary]=[]
var cleaned_camp_surfaces: Array[BaseMaterial3D]=[]

func build(world: RefCounted) -> void:
	_world = weakref(world)
	# Land ends at the west bank; a continuous slab here used to bury the river.
	w.box("首关山谷地面",Vector3(7.5,-.3,148),Vector3(155,.6,380),"mud")
	w.box("首关对岸林地",Vector3(177,-.55,48),Vector3(94,.6,200),"mud",false)
	w.navigation.region = Rect2i(Vector2i.ZERO,w.GRID_SIZE)
	w.navigation.cell_size = Vector2(w.TILE,w.TILE)
	w.navigation.offset = Vector2.ONE*w.TILE*.5
	w.navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	w.navigation.update()
	_boundaries()
	w._build_office()
	w._build_river()
	w._build_reeds()
	w._build_distant_scene()
	w._build_atmosphere()
	for i in 3:
		var id: String = ["checkpoint","yard","river"][i]
		w._build_route_gate(id,w.cell_at(Layout.GATES[i]),i==2)
		var gate: Dictionary = w.route_gates[id]
		gate.body.position = Layout.GATES[i]
		gate.collider.shape.size.x = 8.0
		for mesh in gate.body.get_children():
			if mesh is MeshInstance3D: mesh.position.x *= 2; mesh.scale.x *= 2
		var backing:=MeshInstance3D.new()
		backing.mesh=w._unit_box
		backing.material_override=w.materials.wood
		backing.scale=Vector3(8,2.8,.12)
		gate.body.add_child(backing)
		gate.cells = []
		for j in range(-2,2):
			gate.cells.append(w.cell_at(Layout.GATES[i]+(Vector3(0,0,j*2+1) if i==2 else Vector3(j*2+1,0,0))))
	_buildings()
	_cover()
	_road()
	_dressing()
	scenery.build(w)
	_trees()
	w._sign("青嵐林場",Vector3(33,4,253),0)
	w._sign("電報房",Vector3(40.99,3.52,38),-PI*.5)
	w._sign("林溪渡口",Vector3(78,2.6,19),0)
	for item in [[Vector3(15,1.9,256),"林場 →"],[Vector3(37.5,1.9,202),"木料場 ↑"],[Vector3(55,1.9,181),"木料場 ↑"],[Vector3(37.5,1.9,126),"電報房 ↑"],[Vector3(72,1.9,80),"電報房 ←"],[Vector3(37,1.9,24),"渡口 →"]]:
		w._route_sign(item[1],item[0],0)
	w._batch_static_visuals()
	_initialize.call_deferred()

func _inside(x: float,z: float) -> bool:
	for area: Rect2 in Layout.AREAS:
		if area.has_point(Vector2(x,z)): return true
	return false

func _boundaries() -> void:
	# Merge the union's exposed cell edges into continuous physical walls.
	for y in w.GRID_SIZE.y:
		for x in w.GRID_SIZE.x:
			var at: Vector3 = w.cell_position(Vector2i(x,y))
			var inside := _inside(at.x,at.z)
			w.navigation.set_point_solid(Vector2i(x,y),not inside)
			if not inside: continue
			for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				if _inside(at.x+d.x*2,at.z+d.y*2): continue
				var key := "%s_%d" % ["v" if d.x!=0 else "h",int(at.x+d.x) if d.x!=0 else int(at.z+d.y)]
				if not edges.has(key): edges[key] = []
				edges[key].append(int(at.z-1) if d.x!=0 else int(at.x-1))
	for key: String in edges:
		var list: Array = edges[key]
		list.sort()
		var start: int = list[0]
		var end := start+2
		for value in list.slice(1):
			if value == end: end+=2
			else:
				_wall(key,start,end)
				start=value; end=value+2
		_wall(key,start,end)

func _wall(key: String,start: int,end: int) -> void:
	var vertical := key.begins_with("v")
	var fixed := float(key.split("_")[1])
	var at := Vector3(fixed,1.4,(start+end)*.5) if vertical else Vector3((start+end)*.5,1.4,fixed)
	if vertical and fixed==84 and end<=30:
		w.box("渡口临水矮石岸",Vector3(fixed,.34,at.z),Vector3(.5,.68,end-start+.25),"stone")
		return
	if (at.z>72 and at.z<122) or (at.z>170 and at.z<198) or (vertical and fixed==4):
		_berm(vertical,fixed,start,end)
		return
	var size := Vector3(.45,2.8,end-start+.25) if vertical else Vector3(end-start+.25,2.8,.45)
	var body: Node3D = w.box("林场连续实木围墙",at,size,"wood")
	body.set_meta("first_level_boundary",true)
	for n in range(start,end,4):
		var post := Vector3(fixed,1.55,n) if vertical else Vector3(n,1.55,fixed)
		w.box("围墙立木",post,Vector3(.3,3.1,.3),"bark",false)
	for height in [.5,2.5]:
		var rail := size; rail.y=.15
		w.box("围墙横梁",Vector3(at.x,height,at.z),rail,"bark",false)

func _berm(vertical: bool,fixed: float,start: int,end: int) -> void:
	var middle: float=(start+end)*.5
	var normal:=Vector3.RIGHT if vertical else Vector3.BACK
	var center:=Vector3(fixed,0,middle) if vertical else Vector3(middle,0,fixed)
	if _inside(center.x+normal.x,center.z+normal.z): normal=-normal
	var a:=Vector3(fixed,0,start-.15) if vertical else Vector3(start-.15,0,fixed)
	var b:=Vector3(fixed,0,end+.15) if vertical else Vector3(end+.15,0,fixed)
	var surface:=SurfaceTool.new(); surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var previous: Array[Vector3]=[]
	var count:=ceili(a.distance_to(b)/2.5)
	for segment in count+1:
		var base:=a.lerp(b,float(segment)/count)
		var noise:=sin(base.x*.43+base.z*.31)
		var row: Array[Vector3]=[base,base+normal*(1.8+noise*.45)+Vector3.UP*(3.5+noise*.5),base+normal*(5+noise*.9)+Vector3.UP*(2.8+cos(base.z*.17+base.x*.11)*.7),base+normal*9]
		if not previous.is_empty():
			for i in 3:
				for p in [previous[i],row[i],row[i+1],previous[i],row[i+1],previous[i+1]]: surface.add_vertex(p)
		if segment==0 or segment==count:
			for p in [row[0],row[2],row[1],row[0],row[3],row[2]]: surface.add_vertex(p)
		if segment%3==1: berm_samples.append({"at":base-normal*.35,"normal":normal,"crest":row[1].lerp(row[2],.35),"yaw":base.x*.3+base.z*.2})
		previous=row
	surface.generate_normals()
	var mesh:=MeshInstance3D.new(); mesh.name="林道实体土石坡"; mesh.mesh=surface.commit()
	mesh.set_meta("blockout_retained",true)
	var mat: StandardMaterial3D=w.materials.mud.duplicate(); mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	mesh.material_override=mat
	w.root.add_child(mesh)
	mesh.create_trimesh_collision()
	for shape: CollisionShape3D in mesh.find_children("*","CollisionShape3D",true,false): shape.shape.backface_collision=true

func _building(id: String,at: Vector3,fit: Vector3) -> void:
	var model := (load("res://assets/user_expansion_20261015/"+id+".glb") as PackedScene).instantiate() as Node3D
	model.name = "重构首关_"+id
	var bounds: AABB = w.AssetDressing.new()._bounds(model)
	var scale := fit/bounds.size
	model.scale=scale
	model.position=at-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*scale
	w.root.add_child(model)
	for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		if id.begins_with("camp_"):
			for surface in mesh.mesh.get_surface_count():
				var material := mesh.get_active_material(surface) as BaseMaterial3D
				if material == null or material.albedo_texture == null: continue
				if material.albedo_texture.get_size() != Vector2(1536,3072): continue
				var cleaned := material.duplicate() as BaseMaterial3D
				cleaned.albedo_texture=load("res://assets/user_expansion_20261015/camp_2_3d66Model-4690991-files-2.jpg")
				mesh.set_surface_override_material(surface,cleaned)
				cleaned_camp_surfaces.append(cleaned)
		mesh.create_trimesh_collision()
	structure_footprints.append(Rect2(at.x-fit.x*.5,at.z-fit.z*.5,fit.x,fit.z))

func _buildings() -> void:
	_building("camp_1",Vector3(-5,0,274),Vector3(12.7,5.5,11.8))
	_building("camp_2",Vector3(51,0,240),Vector3(6,3.7,5.9))
	_building("camp_3",Vector3(53,0,216),Vector3(10,7.2,17))
	_building("camp_4",Vector3(51,0,150),Vector3(8,4.4,6))
	_building("camp_1",Vector3(54,0,58),Vector3(23.6,5.2,11.6))
	# A village edge and production buildings share the arrival vista.
	_building("village_1",Vector3(-20,0,244),Vector3(14,5.5,11))
	_building("village_2",Vector3(-20,0,268),Vector3(12,5,10))
	_building("camp_2",Vector3(7.4,0,277),Vector3(4.8,3.2,5.6))
	_building("village_1",Vector3(28,0,281),Vector3(12,5.2,13))
	_building("village_3",Vector3(51,0,253),Vector3(10,4.7,7))
	_building("camp_2",Vector3(27.2,0,237.5),Vector3(4.4,3.2,4.8))
	_building("camp_4",Vector3(56,0,161.5),Vector3(7,3.7,4.8))

func _cover() -> void:
	for at in [Vector3(28,0,244),Vector3(42,0,232),Vector3(29,0,220),Vector3(40,0,206),Vector3(28,0,160),Vector3(42,0,150),Vector3(28,0,140),Vector3(42,0,130),Vector3(32,0,60),Vector3(77,0,26)]:
		w.box("逐段推进木箱",at+Vector3(0,.6,0),Vector3(2.4,1.2,1.2),"wood")
	for at in [Vector3(40,0,240),Vector3(45,0,220),Vector3(28,0,152),Vector3(45,0,136)]:
		w._collision_only_box("原木堆实碰撞",at+Vector3(0,.65,0),Vector3(3.4,1.3,2.2),"bark")
		for layer in 3:
			for j in 4-layer:
				var log: MeshInstance3D = w.cylinder("生产原木",at+Vector3(0,.24+layer*.43,(j-1.5)*.48),.25,3.8,"bark")
				log.rotation.z=PI*.5
	for at in [Vector3(36.8,.35,201.5),Vector3(36.8,.35,125.5)]:
		w.box("应急弹药箱",at,Vector3(.8,.7,.65),"wood")
	w.box("检查口横梁",Vector3(34,3.5,252),Vector3(8,.3,.4),"wood")
	w.box("追兵入口遮挡木堆",Vector3(68,1.3,18.8),Vector3(2.4,2.6,2.0),"bark")
	for x in [30,38]: w.box("岗亭柱",Vector3(x,1.75,252),Vector3(.3,3.5,.3),"wood")
	w.side_wires.append(w.WireFence.add_blocker(w.root,"林师傅木棚尽头低网",Vector3(4,0,250),Vector3(20,0,250)))
	w.side_wires.append(w.WireFence.add_blocker(w.root,"装卸棚后低网",Vector3(60,0,122),Vector3(60,0,170)))

func _road() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1,Layout.ROUTE.size()):
		var a: Vector3 = Layout.ROUTE[i-1]; var b: Vector3 = Layout.ROUTE[i]
		if i>=18 and i<=24: continue
		var side := Vector3(b.z-a.z,0,a.x-b.x).normalized()*2.3
		for p in [a-side,b+side,a+side,a-side,b-side,b+side]: surface.add_vertex(Vector3(p.x,.014,p.z))
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name="首关连续车辙主路"
	mesh.mesh=surface.commit()
	mesh.material_override=w.AssetDressing.pbr("muddy_tracks",.23,Color("a9ada3"))
	w.root.add_child(mesh)

func _dressing() -> void:
	w.asset_dressing=w.AssetDressing.new()
	var d: RefCounted = w.asset_dressing
	d.dressing_root=Node3D.new()
	d.dressing_root.name="重构首关实物布景"
	d.dressing_root.set_meta("blockout_retained",true)
	w.root.add_child(d.dressing_root)
	d._office()
	for at in [Vector3(8,0,270),Vector3(51,0,245),Vector3(48,0,153)]:
		d._spawn("WoodenTable_01",at,0,0,"",0,Vector3(1.5,.8,.8),60)
		d._spawn("Lantern_01",at+Vector3(0,.8,0),.33,0,"",0,Vector3.ZERO,70)
		d._fixture(at+Vector3(0,1.1,0),1,5)
	for at in [Vector3(18,0,256),Vector3(34,0,186),Vector3(56,0,168),Vector3(72,0,108),Vector3(72,0,76)]:
		# Keep the centre of a turn clear for both player and escort capsules.
		at.x-=2.6
		d._spawn("Lantern_01",at+Vector3(0,.5,0),.4,0,"",0,Vector3.ZERO,70)
		w.box("路灯矮桩",at+Vector3(0,.25,0),Vector3(.4,.5,.4),"bark")
		d._fixture(at+Vector3(0,.8,0),.9,6)
	w.lights.assign(d.fixture_lights)

func _trees() -> void:
	var source := (load("res://assets/environment/landscape/far_pine.glb") as PackedScene).instantiate() as Node3D
	var pieces: Array[Dictionary]=[]
	w.landscape._collect(source,Transform3D.IDENTITY,pieces)
	var bounds: AABB = w.asset_dressing._bounds(source)
	var rng:=RandomNumberGenerator.new(); rng.seed=19381016
	var transforms: Array[Transform3D]=[]
	for i in 1000:
		var at:=Vector3(rng.randf_range(-55,105),-.02,rng.randf_range(-28,328))
		var excluded:=false
		for area: Rect2 in Layout.AREAS:
			if area.grow(3).has_point(Vector2(at.x,at.z)): excluded=true
		for area: Rect2 in structure_footprints:
			if area.grow(2).has_point(Vector2(at.x,at.z)): excluded=true
		if excluded or (at.x>82 and at.z<100): continue
		if w.forest_positions.any(func(other): return Vector2(other.x-at.x,other.z-at.z).length()<3.5): continue
		at.y=scenery._hill_height(at.x,at.z)
		var factor:=rng.randf_range(9,16)/bounds.size.y
		transforms.append(Transform3D(Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3.ONE*factor),at)*Transform3D(Basis.IDENTITY,-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)))
		w.forest_positions.append(at)
	for item: Vector4 in scenery.tree_sites:
		var at:=Vector3(item.x,item.y,item.z)
		var factor:=item.w/bounds.size.y
		transforms.append(Transform3D(Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3.ONE*factor),at)*Transform3D(Basis.IDENTITY,-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)))
		w.forest_positions.append(at)
		var body:=StaticBody3D.new(); body.name="林缘松树树干"
		var collision:=CollisionShape3D.new(); var shape:=CylinderShape3D.new()
		shape.radius=.21; shape.height=2.8; collision.shape=shape
		body.add_child(collision); body.position=at+Vector3.UP*1.4
		w.root.add_child(body)
	for item: Dictionary in pieces:
		var mm:=MultiMesh.new(); mm.transform_format=MultiMesh.TRANSFORM_3D; mm.mesh=item.mesh; mm.instance_count=transforms.size()
		for i in transforms.size(): mm.set_instance_transform(i,transforms[i]*item.transform)
		var batch:=MultiMeshInstance3D.new(); batch.name="重构首关山林"; batch.multimesh=mm
		var tree_mesh: Mesh=item.mesh.duplicate()
		for s in tree_mesh.get_surface_count():
			var mat:=tree_mesh.surface_get_material(s).duplicate() as StandardMaterial3D
			if mat==null: continue
			mat.albedo_color=Color("607b51")
			mat.vertex_color_use_as_albedo=true
			mat.roughness=1
			mat.metallic_specular=.12
			if mat.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:
				mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				mat.alpha_scissor_threshold=.45
				mat.cull_mode=BaseMaterial3D.CULL_DISABLED
			tree_mesh.surface_set_material(s,mat)
		mm.mesh=tree_mesh
		batch.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		w.root.add_child(batch)
	source.free()

func _initialize() -> void:
	var lifetime: RefCounted = w
	if lifetime == null or not is_instance_valid(lifetime.root): return
	var tree: SceneTree = lifetime.root.get_tree()
	await tree.physics_frame
	await tree.physics_frame
	if not is_instance_valid(lifetime.root) or not lifetime.root.is_inside_tree(): return
	var capsule:=CapsuleShape3D.new(); capsule.radius=.44; capsule.height=1.72
	var query:=PhysicsShapeQueryParameters3D.new(); query.shape=capsule; query.collision_mask=1
	var exclude: Array[RID]=[]
	for gate: Dictionary in w.route_gates.values(): exclude.append(gate.body.get_rid())
	query.exclude=exclude
	base_solid.resize(w.GRID_SIZE.x*w.GRID_SIZE.y)
	var space: PhysicsDirectSpaceState3D=w.root.get_world_3d().direct_space_state
	for y in w.GRID_SIZE.y:
		for x in w.GRID_SIZE.x:
			var at: Vector3=w.cell_position(Vector2i(x,y))
			query.transform.origin=at+Vector3(0,1,0)
			var solid:=not _inside(at.x,at.z) or not space.intersect_shape(query,1).is_empty()
			# The office has its own one-metre interior graph. Outdoor routes
			# must stay on its western/northern roads rather than cut through it.
			if Rect2(40,24,28,24).has_point(Vector2(at.x,at.z)): solid=true
			# Reserve complete building footprints; tiny foundation edges can sit
			# below the standing capsule sample while still catching moving feet.
			for area: Rect2 in structure_footprints:
				if area.grow(.45).has_point(Vector2(at.x,at.z)): solid=true
			for wire: StaticBody3D in w.side_wires:
				var size: Vector3=wire.get_child(0).shape.size
				var local: Vector3=wire.to_local(at)
				if absf(local.x)<size.x*.5+1 and absf(local.z)<size.z*.5+1: solid=true
			base_solid[y*w.GRID_SIZE.x+x]=int(solid)
			w.navigation.set_point_solid(Vector2i(x,y),solid)
	# Narrow props can lie between two free grid centres. Sweep their connection
	# and reserve one endpoint, retaining the road's usable width around bends.
	var connection_blocks: Dictionary={}
	for y in w.GRID_SIZE.y-1:
		for x in w.GRID_SIZE.x-1:
			var a:=Vector2i(x,y)
			if base_solid[y*w.GRID_SIZE.x+x]!=0: continue
			for delta: Vector2i in [Vector2i.RIGHT,Vector2i.DOWN]:
				var b:=a+delta
				if base_solid[b.y*w.GRID_SIZE.x+b.x]!=0: continue
				query.transform.origin=w.cell_position(a)+Vector3.UP
				query.motion=Vector3(delta.x*2,0,delta.y*2)
				var travel: float=space.cast_motion(query)[0]
				if travel<.9999: connection_blocks[a if travel<.5 else b]=true
	for cell: Vector2i in connection_blocks:
		base_solid[cell.y*w.GRID_SIZE.x+cell.x]=1
		w.navigation.set_point_solid(cell,true)
	ready=true
	for id: String in w.route_gates: w.set_route_gate(id,w.route_gates[id].opened)

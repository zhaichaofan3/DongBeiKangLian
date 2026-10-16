extends RefCounted
## The supplied settlement retains its authored courtyard and lane positions.

const ORIGIN := Vector3(1100, 0, 180)
const Forest = preload("res://scripts/forest_approach.gd")
const START := Vector3(1153, .08, 278)
const EXIT := Vector3(1147, .08, 24)
const GATES := [Vector3(1143, 1.4, 182), Vector3(1148, 1.4, 75)]
const APPROACHES := [Vector3(1143,.08,185), Vector3(1148,.08,78)]
const ROUTE_STOPS := [
	[Vector3(1153,.08,268), Vector3(1152,.08,244), Vector3(1147,.08,219), Vector3(1143,.08,191)],
	[Vector3(1140,.08,167), Vector3(1141,.08,146), Vector3(1148,.08,123), Vector3(1148,.08,86)],
	[Vector3(1147,.08,68), Vector3(1147,.08,48), Vector3(1147,.08,29)]]
const GRID := Vector2i(290, 450)
const OFFSET := Vector2(990.5,.5)
var _world: WeakRef
var world: RefCounted:
	get: return _world.get_ref()
var container: Node3D
var navigation := AStarGrid2D.new()
var base_solid := PackedByteArray()
var gates: Array[StaticBody3D] = []
var opaque_wings: Array[StaticBody3D] = []
var navigation_ready := false
var phase := 0
var house_count := 0
var tree_count := 0
var environment: Environment
var side_wires: Array[StaticBody3D] = []
var forest := Forest.new()

func build(owner_world: RefCounted) -> void:
	_world = weakref(owner_world)
	environment = world.environment.duplicate()
	environment.fog_density = .0008
	environment.fog_height_density = .002
	container = Node3D.new()
	container.name = "东北农村_原村落布局"
	world.root.add_child(container)
	_box("村庄山谷地面", Vector3(1125,-.3,47), Vector3(650,.6,500), "mud")
	var settlement := (load("res://assets/user_expansion_20261015/village_complete.glb") as PackedScene).instantiate() as Node3D
	settlement.name = "东北农村完整原场景"
	settlement.position = ORIGIN
	container.add_child(settlement)
	for mesh: MeshInstance3D in settlement.find_children("*", "MeshInstance3D", true, false):
		mesh.create_trimesh_collision()
		for shape: CollisionShape3D in mesh.find_children("*", "CollisionShape3D", true, false):
			if shape.shape is ConcavePolygonShape3D: shape.shape.backface_collision = true
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/user_expansion_20261015/village-layout.json"))
	for item in manifest.kept:
		var lo: Array = item.bounds_cm[0]
		var hi: Array = item.bounds_cm[1]
		if hi[0]-lo[0]>2000 and hi[1]-lo[1]>2000 and hi[2]-lo[2]>400: house_count += 1
	# Only the short gate returns are new opaque masonry. Side lanes are closed
	# with low wire measured against the source buildings after physics starts.
	for entry in [
		[Vector3(1132.5,1.4,182),Vector3(13,2.8,.35)],
		[Vector3(1148.5,1.4,182),Vector3(3,2.8,.35)],
		[Vector3(1141.5,1.4,75),Vector3(5,2.8,.35)],
		[Vector3(1155,1.4,75),Vector3(6,2.8,.35)]]:
		opaque_wings.append(_box("沿原院墙接出的门垛",entry[0],entry[1],"brick"))
	for i in 2: gates.append(_box("村内院门_%d" % i,GATES[i],Vector3(8,2.8,.35),"wood"))
	_build_lane()
	_build_perimeter()
	_build_logging_edge()
	_build_surroundings()
	forest.build(world,container)
	world.build_supplied_river(Vector3(1214,0,451),PI*.5)
	world.build_supplied_dock(Vector3(1214,0,426),-PI*.5)
	var shore_ramp := _box("栈桥岸边踏板",Vector3(1214,.08,433.3),Vector3(2,.12,2),"wood")
	shore_ramp.rotation.x = -.14
	_box("栈桥平台铺板",Vector3(1214,.205,435.55),Vector3(2,.15,3.2),"wood")
	world._build_boat(Vector3(1214,-1.7,439.6))
	world._sign("松嶺屯",Vector3(1147,2.4,275),0)
	navigation.region = Rect2i(Vector2i.ZERO,GRID)
	navigation.cell_size = Vector2.ONE
	navigation.offset = OFFSET
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	navigation.update()

func _box(title: String, at: Vector3, size: Vector3, material: String) -> StaticBody3D:
	var body: StaticBody3D = world.box(title,at,size,material)
	body.reparent(container)
	return body

func _build_lane() -> void:
	var points: Array[Vector3] = [START+Vector3(0,0,9)]
	for section: Array in ROUTE_STOPS:
		for at: Vector3 in section: points.append(at)
	points.append(EXIT)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1,points.size()):
		var a := points[i-1]
		var b := points[i]
		var side := Vector3(b.z-a.z,0,a.x-b.x).normalized()*2.6
		for p in [a-side,b+side,a+side,a-side,b-side,b+side]: surface.add_vertex(Vector3(p.x,.012,p.z))
	surface.generate_normals()
	var road := MeshInstance3D.new()
	road.name = "顺原村道延伸的泥辙"
	road.mesh = surface.commit()
	road.material_override = world.AssetDressing.pbr("muddy_tracks",.23,Color("a9ada3"))
	container.add_child(road)

func _build_perimeter() -> void:
	var rim := [Vector2(994,45),Vector2(1010,3),Vector2(1200,3),Vector2(1278,35),Vector2(1278,275),Vector2(1230,297),Vector2(1163,297),Vector2(1147,297),Vector2(1020,297),Vector2(994,250)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in rim.size():
		var a: Vector2 = rim[i]
		var b: Vector2 = rim[(i+1)%rim.size()]
		if a==Vector2(1163,297) and b==Vector2(1147,297): continue
		var side := Vector2(b.y-a.y,a.x-b.x).normalized()
		var pa := [Vector3(a.x-side.x*5,-.1,a.y-side.y*5),Vector3(a.x-side.x*2.5,5,a.y-side.y*2.5),Vector3(a.x+side.x*2.5,5,a.y+side.y*2.5),Vector3(a.x+side.x*5,-.1,a.y+side.y*5)]
		var pb := [Vector3(b.x-side.x*5,-.1,b.y-side.y*5),Vector3(b.x-side.x*2.5,5,b.y-side.y*2.5),Vector3(b.x+side.x*2.5,5,b.y+side.y*2.5),Vector3(b.x+side.x*5,-.1,b.y+side.y*5)]
		for j in 3:
			for p in [pa[j],pb[j+1],pa[j+1],pa[j],pb[j],pb[j+1]]: surface.add_vertex(p)
	surface.generate_normals()
	var bank := MeshInstance3D.new()
	bank.name = "村外连续林坡"
	bank.mesh = surface.commit()
	bank.material_override = world.materials.mud
	container.add_child(bank)
	bank.create_trimesh_collision()
	for shape: CollisionShape3D in bank.find_children("*","CollisionShape3D",true,false): shape.shape.backface_collision = true

func _build_logging_edge() -> void:
	var yard := Node3D.new()
	yard.name = "村边林场作业点"
	yard.position = Vector3(1070,0,246)
	container.add_child(yard)
	for entry in [["camp_3",Vector3(-5,0,-3)],["camp_4",Vector3(8,0,3)]]:
		var model := (load("res://assets/user_expansion_20261015/%s.glb" % entry[0]) as PackedScene).instantiate() as Node3D
		model.position = entry[1]
		yard.add_child(model)
		for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false): mesh.create_trimesh_collision()
	for x in 4:
		for layer in 3:
			var log: MeshInstance3D = world.cylinder("村边林场原木",Vector3(1070+x*.65,.32+layer*.54,260),.32,7,"bark")
			log.rotation.z = PI*.5
			log.reparent(container)
	_box("作业点木料堆碰撞",Vector3(1071,.8,260),Vector3(9,1.6,2.3),"wood").visible = false

func _build_surroundings() -> void:
	var source := (load("res://assets/environment/landscape/far_pine.glb") as PackedScene).instantiate() as Node3D
	var pieces: Array[Dictionary] = []
	_collect(source,Transform3D.IDENTITY,pieces)
	var bounds := AABB()
	for item in pieces:
		var box: AABB = item.transform*item.mesh.get_aabb()
		bounds = box if bounds.size==Vector3.ZERO else bounds.merge(box)
	var rng := RandomNumberGenerator.new()
	rng.seed = 19381015
	var transforms: Array[Transform3D] = []
	for i in 300:
		var angle := TAU*float(i)/300
		var at := Vector3(1136+cos(angle)*rng.randf_range(155,190),-.05,150+sin(angle)*rng.randf_range(159,200))
		var factor := rng.randf_range(10,18)/bounds.size.y
		var offset := -Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)
		transforms.append(Transform3D(Basis(Vector3.UP,rng.randf_range(0,TAU)).scaled(Vector3.ONE*factor),at)*Transform3D(Basis.IDENTITY,offset))
	tree_count = transforms.size()
	for item in pieces:
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		var mesh: Mesh = item.mesh.duplicate()
		for index in mesh.get_surface_count():
			var mat := mesh.surface_get_material(index).duplicate() as StandardMaterial3D
			if mat==null: continue
			mat.albedo_color = Color("819573")
			mat.roughness = 1
			if mat.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				mat.alpha_scissor_threshold = .45
				mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			mesh.surface_set_material(index,mat)
		instances.mesh = mesh
		instances.instance_count = transforms.size()
		for i in transforms.size(): instances.set_instance_transform(i,transforms[i]*item.transform)
		var trees := MultiMeshInstance3D.new()
		trees.name = "环村树林"
		trees.multimesh = instances
		container.add_child(trees)
	source.free()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 96:
		var a := TAU*i/96.0
		var b := TAU*(i+1)/96.0
		var points := [Vector3(cos(a)*215,-1,sin(a)*245),Vector3(cos(a)*275,52+sin(a*5)*17,sin(a)*300),Vector3(cos(b)*275,52+sin(b*5)*17,sin(b)*300),Vector3(cos(b)*215,-1,sin(b)*245)]
		for index in [0,2,1,0,3,2]: surface.add_vertex(points[index])
	surface.generate_normals()
	var hills := MeshInstance3D.new()
	hills.name = "环村山岭"
	hills.mesh = surface.commit()
	var material: StandardMaterial3D = world.materials.stone.duplicate()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	hills.material_override = material
	hills.position = Vector3(1136,0,150)
	container.add_child(hills)

func _collect(node: Node3D, parent: Transform3D, result: Array[Dictionary]) -> void:
	var placement := parent*node.transform
	if node is MeshInstance3D: result.append({"mesh":node.mesh,"transform":placement})
	for child in node.get_children():
		if child is Node3D: _collect(child,placement,result)

func _close_side_lanes() -> void:
	var space := container.get_world_3d().direct_space_state
	var probe := SphereShape3D.new()
	probe.radius = .06
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = probe
	query.collision_mask = 1
	for section in 2:
		var z: float = GATES[section].z
		for span: Array in [[1000.0,GATES[section].x-4],[GATES[section].x+4,1272.0]]:
			var start := -1.0
			var x: float = span[0]
			while x<=span[1]+.25:
				query.transform.origin = Vector3(x,.75,z)
				var closed: bool = x>span[1] or not space.intersect_shape(query,1).is_empty()
				if not closed and start<0: start = x-1.0
				if closed and start>=0:
					if x-start>1.5: side_wires.append(world.WireFence.add_blocker(container,"原村院落支巷封口_%d_%d" % [section,side_wires.size()],Vector3(start,0,z),Vector3(x+1.0,0,z)))
					start = -1
				x += .2
	# Keep the original climbable haystacks behind a low enclosure, so they
	# cannot serve as steps over the northern encounter boundary.
	for entry in [
		[Vector3(1128.5,0,75),Vector3(1128.5,0,79)],
		[Vector3(1128.5,0,79),Vector3(1140,0,79)],
		[Vector3(1140,0,79),Vector3(1140,0,75)]]:
		side_wires.append(world.WireFence.add_blocker(container,"北院草垛支路低网_%d" % side_wires.size(),entry[0],entry[1]))

func initialize_navigation() -> void:
	if navigation.region.size!=GRID:
		push_error("Village build did not finish before navigation initialization")
		return
	_close_side_lanes()
	var capsule := CapsuleShape3D.new()
	capsule.radius = .55
	capsule.height = 1.62
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.collision_mask = 1
	var excluded: Array[RID] = []
	for gate in gates: excluded.append(gate.get_rid())
	query.exclude = excluded
	var space := container.get_world_3d().direct_space_state
	base_solid.resize(GRID.x*GRID.y)
	var obstacles: Array[Dictionary] = []
	for body: StaticBody3D in side_wires+opaque_wings:
		var shapes := body.find_children("*","CollisionShape3D",true,false)
		obstacles.append({"inverse":body.global_transform.affine_inverse(),"size":shapes[0].shape.size})
	for y in GRID.y:
		for x in GRID.x:
			var at := Vector3(OFFSET.x+x,1.02,OFFSET.y+y)
			query.transform.origin = at
			var solid := not contains(Vector3(at.x,.08,at.z)) or not space.intersect_shape(query,1).is_empty()
			for obstacle: Dictionary in obstacles:
				var size: Vector3 = obstacle.size
				var local: Vector3 = obstacle.inverse*at
				if absf(local.x)<size.x*.5+.65 and absf(local.z)<size.z*.5+.65:
					solid = true
					break
			base_solid[y*GRID.x+x] = 1 if solid else 0
			navigation.set_point_solid(Vector2i(x,y),solid)
	navigation_ready = true
	set_phase(phase)

func set_phase(value: int) -> void:
	phase = value
	for i in gates.size():
		var opened := phase>i
		gates[i].visible = not opened
		gates[i].collision_layer = 0 if opened else 1
		if not navigation_ready: continue
		for y in range(floori(GATES[i].z-1),ceili(GATES[i].z+1)):
			for x in range(floori(GATES[i].x-OFFSET.x-4.65),ceili(GATES[i].x-OFFSET.x+4.65)):
				navigation.set_point_solid(Vector2i(x,y),base_solid[y*GRID.x+x]!=0 or not opened)

func _anchor(at: Vector3) -> Vector2i:
	var cell := Vector2i(floori(at.x-OFFSET.x),floori(at.z-OFFSET.y))
	var best := Vector2i(-1,-1)
	var distance := INF
	for y in range(maxi(1,cell.y-3),mini(GRID.y-2,cell.y+3)+1):
		for x in range(maxi(1,cell.x-3),mini(GRID.x-2,cell.x+3)+1):
			var candidate := Vector3(OFFSET.x+x,.08,OFFSET.y+y)
			if not navigation.is_point_solid(Vector2i(x,y)) and candidate.distance_squared_to(at)<distance and world._path_segment_clear(at,candidate):
				best = Vector2i(x,y)
				distance = candidate.distance_squared_to(at)
	return best

func path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var route := PackedVector3Array()
	if not navigation_ready or not contains(from) or not contains(to): return route
	var a := _anchor(from)
	var b := _anchor(to)
	if a.x<0 or b.x<0: return route
	for point in navigation.get_point_path(a,b): route.append(Vector3(point.x,.08,point.y))
	if not route.is_empty() and world._path_segment_clear(route[-1],to): route.append(to)
	return route

static func contains(at: Vector3) -> bool:
	if not at.is_finite() or at.y<-.1 or at.y>6: return false
	return (at.x>=992 and at.x<=1279 and at.z>=1.4 and at.z<=299) or Forest.AREA.has_point(Vector2(at.x,at.z)) or Forest.PIER_AREA.has_point(Vector2(at.x,at.z))

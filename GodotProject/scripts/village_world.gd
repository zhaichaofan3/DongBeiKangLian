extends RefCounted
## Large supplied courtyards form a narrow street with three playable yard detours.

const Forest = preload("res://scripts/forest_approach.gd")
const Scenery = preload("res://scripts/village_scenery.gd")
const START := Vector3(1147, .08, 282)
const EXIT := Vector3(1147, .08, 24)
const GATES := [Vector3(1147, 1.4, 196), Vector3(1147, 1.4, 112)]
const APPROACHES := [Vector3(1147,.08,199), Vector3(1147,.08,115)]
const PHASE_STARTS := [START, Vector3(1147,.08,192), Vector3(1147,.08,108)]
const YARDS := [Vector3(1143.5,.08,204),Vector3(1150.5,.08,148.5),Vector3(1150.5,.08,64.5)]
const ROUTE_STOPS := [
	[Vector3(1147,.08,274),Vector3(1147,.08,250),Vector3(1147,.08,225),Vector3(1147,.08,210),
	Vector3(1147,.08,206),Vector3(1143.5,.08,206),Vector3(1143.5,.08,201),Vector3(1147,.08,201),Vector3(1147,.08,199)],
	[Vector3(1147,.08,192),Vector3(1147,.08,174),Vector3(1147,.08,156),
	Vector3(1147,.08,151),Vector3(1150.5,.08,151),Vector3(1150.5,.08,146),Vector3(1147,.08,146),Vector3(1147,.08,118)],
	[Vector3(1147,.08,108),Vector3(1147,.08,87),Vector3(1147,.08,70),
	Vector3(1147,.08,67),Vector3(1150.5,.08,67),Vector3(1150.5,.08,62),Vector3(1147,.08,62),Vector3(1147,.08,40),Vector3(1147,.08,29)]]
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
var scenery := Scenery.new()
var road_material: ShaderMaterial
var courtyard_modules: Array[Node3D] = []
var street_barricades: Array[StaticBody3D] = []

func build(owner_world: RefCounted) -> void:
	_world = weakref(owner_world)
	environment = world.environment.duplicate()
	environment.fog_density = .0008
	environment.fog_height_density = .002
	container = Node3D.new()
	container.name = "东北农村_窄街与院落巷战"
	world.root.add_child(container)
	var ground := _box("村庄山谷地面", Vector3(1125,-.3,47), Vector3(650,.6,500), "mud")
	ground.get_child(0).material_override = _ground_material(false)
	_build_courtyards()
	for i in 2:
		for span in [[1117.5,1145.3],[1148.7,1176.5]]:
			opaque_wings.append(_box("院墙关口门垛",Vector3((span[0]+span[1])*.5,1.4,GATES[i].z),Vector3(span[1]-span[0],2.8,.4),"brick"))
		gates.append(_box("村内院门_%d" % i,GATES[i],Vector3(3.5,2.8,.4),"wood"))
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
	world._build_boat(Vector3(1214,-1.7,440.4))
	world._sign("松嶺屯",Vector3(1147,2.4,281),0)
	navigation.region = Rect2i(Vector2i.ZERO,GRID)
	navigation.cell_size = Vector2.ONE
	navigation.offset = OFFSET
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	navigation.update()

func _build_courtyards() -> void:
	var packed := load("res://assets/user_expansion_20261015/village_4.glb") as PackedScene
	var passage := load("res://assets/user_expansion_20261015/village_passages.glb") as PackedScene
	for z in [260,218,176,134,92,50]:
		for side in [-1,1]:
			var playable: bool = (side<0 and z==218) or (side>0 and z in [134,50])
			var model := (passage if playable else packed).instantiate() as Node3D
			model.name = "穿行大院_%d_%d" % [side,z] if playable else "沿街大院_%d_%d" % [side,z]
			model.position = Vector3(1147+side*13.5,-.1045,z)
			model.rotation.y = 0 if side<0 else PI
			container.add_child(model)
			courtyard_modules.append(model)
			house_count += 1
			for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
				mesh.create_trimesh_collision()
				for shape: CollisionShape3D in mesh.find_children("*","CollisionShape3D",true,false):
					shape.shape.backface_collision = true
	# Narrow gap alleys remain domestic spaces, closed at their outer ends by
	# visible masonry. Main-street barricades make each opened yard the route.
	for z in [239,155,71,29]:
		for span in [[1118.0,1145.3],[1148.7,1176.0]]:
			_box("相邻院落横巷尽头",Vector3((span[0]+span[1])*.5,1.35,z),Vector3(span[1]-span[0],2.7,.35),"brick")
	for z in [203.5,148.5,64.5]:
		street_barricades.append(_box("迫使转入院内的木料封街",Vector3(1147,1.4,z),Vector3(3.6,2.8,.65),"wood"))
		for x in [1145.65,1148.35]:
			var brace := _box("封街斜撑",Vector3(x,1.1,z+1),Vector3(.16,2.5,.16),"bark")
			brace.rotation.x = -.5
	for at in [Vector3(1145.8,.4,254),Vector3(1148.2,.4,171),Vector3(1145.8,.4,89),Vector3(1148.2,.4,40)]:
		_box("窄街路旁柴箱掩体",at,Vector3(.85,.8,1.6),"wood")

func _box(title: String, at: Vector3, size: Vector3, material: String) -> StaticBody3D:
	var body: StaticBody3D = world.box(title,at,size,material)
	body.reparent(container)
	return body

func _build_lane() -> void:
	var points: Array[Vector3] = [Forest.ENTRANCE,START]
	for section: Array in ROUTE_STOPS:
		for at: Vector3 in section: points.append(at)
	points.append(EXIT)
	var samples: Array[Vector3] = []
	for i in range(1,points.size()):
		var count := ceili(points[i-1].distance_to(points[i])/2)
		for j in count: samples.append(points[i-1].lerp(points[i],float(j)/count))
	samples.append(points[-1])
	var edges: Array[Vector3] = []
	for i in samples.size():
		var direction := (samples[mini(i+1,samples.size()-1)]-samples[maxi(0,i-1)]).normalized()
		edges.append(Vector3(direction.z,0,-direction.x)*(1.35+sin(samples[i].z*.51)*.08))
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1,samples.size()):
		var a := samples[i-1]
		var b := samples[i]
		var left := edges[i-1]
		var right := edges[i]
		var vertices := [a-left,a+left,b+right,a-left,b+right,b-right]
		for k in 6:
			var p: Vector3 = vertices[k]
			surface.set_uv(Vector2([0,1,1,0,1,0][k],p.z*.26))
			surface.add_vertex(Vector3(p.x,.016,p.z))
	surface.generate_normals()
	var road := MeshInstance3D.new()
	road.name = "窄街转入院落的泥辙"
	road.mesh = surface.commit()
	road.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	road_material = _ground_material(true)
	road.material_override = road_material
	container.add_child(road)

func _ground_material(is_road: bool) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/village_ground.gdshader")
	material.set_shader_parameter("ground_diffuse",load("res://assets/environment/textures/gravel_road/gravel_road_diff_2k.jpg"))
	material.set_shader_parameter("road_diffuse",load("res://assets/environment/textures/muddy_tracks/muddy_tracks_diff_2k.jpg"))
	material.set_shader_parameter("road_normal",load("res://assets/environment/textures/muddy_tracks/muddy_tracks_nor_gl_2k.jpg"))
	material.set_shader_parameter("is_road",is_road)
	return material

func _build_perimeter() -> void:
	for x in [1118,1176]:
		_box("村后连续院墙",Vector3(x,1.4,149),Vector3(.4,2.8,266),"brick")
	_box("北院尽头院墙",Vector3(1147,1.4,17),Vector3(58,2.8,.4),"brick")
	for span in [[1118,1145.2],[1148.8,1176]]:
		_box("村口收口院墙",Vector3((span[0]+span[1])*.5,1.4,280),Vector3(span[1]-span[0],2.8,.4),"brick")
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
	# Inaccessible woodlots connect the yard trees to the distant forest while
	# leaving the logging sheds and timber landing a clear working space.
	for i in 460:
		var at := Vector3(rng.randf_range(1018,1112) if i%2==0 else rng.randf_range(1182,1264),-.05,rng.randf_range(24,280))
		if Vector2(at.x-1070,at.z-250).length()<17: continue
		var factor := rng.randf_range(8,15)/bounds.size.y
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
	# Low wire closes short, visible side recesses; solid court walls carry the
	# encounter boundaries, keeping enemies concealed beyond the current section.
	for z in [237.5,153.5,69.5]:
		for x in [1145.2,1148.8]:
			_box("横巷封口门柱",Vector3(x,.65,z),Vector3(.45,1.3,1.25),"brick")
		for span in [[1117.8,1145.3],[1148.7,1176.2]]:
			side_wires.append(world.WireFence.add_blocker(container,"横巷柴场低网_%d" % side_wires.size(),Vector3(span[0],0,z),Vector3(span[1],0,z)))

func prepare_navigation() -> void:
	_close_side_lanes()
	scenery.build(world,container)

func initialize_navigation() -> void:
	if navigation.region.size!=GRID:
		push_error("Village build did not finish before navigation initialization")
		return
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
		for y in range(floori(GATES[i].z-OFFSET.y-1),ceili(GATES[i].z-OFFSET.y+1)):
			for x in range(floori(GATES[i].x-OFFSET.x-2.3),ceili(GATES[i].x-OFFSET.x+2.3)):
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

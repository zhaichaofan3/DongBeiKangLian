extends RefCounted

const AssetDressing = preload("res://scripts/asset_dressing.gd")
const RouteBlockout = preload("res://scripts/route_blockout.gd")
const Landscape = preload("res://scripts/landscape.gd")
const VillageWorld = preload("res://scripts/village_world.gd")
const WireFence = preload("res://scripts/wire_fence.gd")
const FirstLevel = preload("res://scripts/first_level_world.gd")
const TILE := 2.0
const GRID_SIZE := Vector2i(44, 152)
var first_level := FirstLevel.new()
var root: Node3D
var navigation := AStarGrid2D.new()
var blocked: Array[Vector2i] = []
var materials: Dictionary = {}
var lights: Array[OmniLight3D] = []
var water: MeshInstance3D
var clock := 0.0
var glow_material: StandardMaterial3D
var environment: Environment
var sunlight: DirectionalLight3D
var quality_level := 1
var static_batch_count := 0
var static_instance_count := 0
var _mesh_cache: Dictionary = {}
var _texture_cache: Dictionary = {}
var _foliage_materials: Array[ShaderMaterial] = []
var _ground_batches: Array[MultiMeshInstance3D] = []
var _atmosphere: Array[CPUParticles3D] = []
var _unit_box := BoxMesh.new()
var asset_dressing: RefCounted
var route_gates: Dictionary = {}
var route_blockout := RouteBlockout.new()
var landscape := Landscape.new()
var village_world := VillageWorld.new()
var forest_positions: Array[Vector3] = []
var _path_capsule := CapsuleShape3D.new()
var route_walls: Dictionary = {}
var side_wires: Array[StaticBody3D] = []
var office_navigation := AStarGrid2D.new()
var office_base_solid := PackedByteArray()
var office_navigation_ready := false
var office_door_open := false
const OFFICE_ENTRY := Vector3(38.5,.08,38.5)

func build(parent: Node3D) -> void:
	root = parent
	_unit_box.size = Vector3.ONE
	materials["brick"] = _material(Color("6d6457"), "brick")
	materials["wood"] = _material(Color("70583d"), "wood")
	materials["mud"] = _material(Color("696552"), "mud")
	materials["tile"] = _material(Color("34464b"), "tile")
	materials["iron"] = _material(Color("4b5355"), "iron")
	materials["paper"] = _material(Color("d7dcbd"), "paper")
	materials["sandbag"] = _material(Color("93a094"), "cloth")
	materials["water"] = _material(Color("47777e"), "water")
	materials["bark"] = _material(Color("403a31"), "wood")
	materials["pine"] = _material(Color("34483c"), "cloth")
	materials["birch"] = _material(Color("bebbb0"), "birch")
	materials["leaf"] = _material(Color("9d783f"), "cloth")
	materials["stone"] = _material(Color("777b73"), "stone")
	materials["window"] = _material(Color("7c9695"), "iron")
	materials["window"].metallic = 0.4
	materials["wood_end"] = _material(Color("a18c64"), "endgrain")
	materials["bark"] = AssetDressing.pbr("pine_bark", 0.62, Color("9aaba4"))
	materials["pine"] = _foliage_material(Color("263d31"), Color("647156"), 0.055)
	materials["leaf"] = _foliage_material(Color("534934"), Color("82744b"), 0.15)
	materials["reeds"] = _foliage_material(Color("3c4430"), Color("6b7150"), 0.12)
	var distant_land := StandardMaterial3D.new()
	distant_land.albedo_color = Color("6a7d80")
	distant_land.roughness = 1.0
	distant_land.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	distant_land.disable_fog = true
	distant_land.vertex_color_use_as_albedo = true
	distant_land.cull_mode = BaseMaterial3D.CULL_DISABLED
	materials["distant_land"] = distant_land
	var river_material := ShaderMaterial.new()
	river_material.shader = load("res://shaders/river.gdshader")
	materials["water"] = river_material
	glow_material = StandardMaterial3D.new()
	glow_material.albedo_color = Color("ffd69a")
	glow_material.emission_enabled = true
	glow_material.emission = Color("dfaa62")
	glow_material.emission_energy_multiplier = 1.4
	materials["glow"] = glow_material
	_setup_environment()
	first_level.build(self)
	village_world.build(self)
	apply_quality(quality_level)
	_initialize_office_navigation.call_deferred()

func _legacy_compact_build() -> void:
	box("远处林地", Vector3(-15, -0.5, 46), Vector3(206, 0.3, 340), "mud", false)
	box("对岸林地", Vector3(220, -0.5, 46), Vector3(175, 0.3, 340), "mud", false)
	box("江岸泥地", Vector3(44, -0.3, 48), Vector3(88, 0.6, 96), "mud")
	navigation.region = Rect2i(Vector2i.ZERO, GRID_SIZE)
	navigation.cell_size = Vector2(TILE, TILE)
	navigation.offset = Vector2(TILE * 0.5, TILE * 0.5)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	navigation.update()
	for x in GRID_SIZE.x:
		_block(Vector2i(x, 0), "wood", 2.4)
		_block(Vector2i(x, GRID_SIZE.y - 1), "wood", 2.4)
	for y in range(1, GRID_SIZE.y - 1):
		_block(Vector2i(0, y), "wood", 2.4)
		_block(Vector2i(GRID_SIZE.x - 1, y), "wood", 1.3)
	# Continuous fences funnel the approach through the checkpoint, timber lane
	# and the north side of the office instead of allowing a run around the yard.
	for y in range(1, 23):
		if y != 18:
			_block(Vector2i(5, y), "wood", 2.8)
	for x in range(6, 21):
		if x != 8:
			_block(Vector2i(x, 14), "wood", 2.8)
	for x in range(6, 10):
		if x != 8:
			_block(Vector2i(x, 10), "wood", 2.8)
	for y in range(1, 14):
		if y != 5:
			_block(Vector2i(17, y), "wood", 2.8)
	_build_office()
	# Join the old timber partition to the building at both exposed ends.
	# These were real capsule-width bypasses despite the coarse navigation mask.
	box("木料巷隔墙接电报房", Vector3(42.7, 1.4, 42), Vector3(5.6, 2.8, .4), "wood")
	box("电报房东南封口", Vector3(67.5, 1.4, 48), Vector3(1.5, 2.8, .4), "wood")
	_build_yard()
	_build_linear_route()
	_build_river()
	_build_reeds()
	_build_distant_scene()
	_build_lamps()
	_build_forest()
	_build_details()
	_build_ground_cover()
	_build_close_details()
	_build_atmosphere()
	_sign("青嵐林場", Vector3(22.0, 4.0, 74.0), 0.0)
	_sign("電報房", Vector3(42.0, 3.2, 37.5), PI * 0.5)
	_sign("林溪渡口", Vector3(78, 2.6, 19), 0.0)
	_batch_static_visuals()
	asset_dressing = AssetDressing.new()
	asset_dressing.build(root)
	route_blockout.build(self)
	asset_dressing.build_s11()
	asset_dressing.build_s12()
	landscape.build(root)
	village_world.build(self)
	route_blockout.hide_s11_slot_visuals()
	_build_side_wires()
	apply_quality(quality_level)
	_initialize_office_navigation.call_deferred()

func cell_position(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * TILE + TILE * 0.5, 0, cell.y * TILE + TILE * 0.5)

func cell_at(position: Vector3) -> Vector2i:
	return Vector2i(clampi(int(position.x / TILE), 1, GRID_SIZE.x - 2), clampi(int(position.z / TILE), 1, GRID_SIZE.y - 2))

func path(from: Vector3, to: Vector3) -> PackedVector3Array:
	if from.x > 900 or to.x > 900:
		return village_world.path(from, to)
	if office_navigation_ready:
		var a := _inside_office(from)
		var b := _inside_office(to)
		if a and b: return _office_path(from,to)
		if a or b:
			if not office_door_open: return PackedVector3Array()
			var first := _office_path(from,OFFICE_ENTRY) if a else _forest_path(from,OFFICE_ENTRY)
			var second := _forest_path(OFFICE_ENTRY,to) if a else _office_path(OFFICE_ENTRY,to)
			if first.is_empty() or second.is_empty(): return PackedVector3Array()
			first.append_array(second)
			return first
	return _forest_path(from,to)

func _forest_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var route := PackedVector3Array()
	var a := _path_anchor(from)
	var b := _path_anchor(to)
	if a == Vector2i(-1,-1) or b == Vector2i(-1,-1):
		return route
	for point in navigation.get_point_path(a, b):
		route.append(Vector3(point.x, 0, point.y))
	if route.is_empty(): return route
	# Keep actual endpoints. A courier must not stop at the grid centre when
	# the player is standing at a corner or beside cover in a reserved cell.
	if _path_segment_clear(route[-1], to):
		route.append(Vector3(to.x, 0, to.z))
	return route

func _inside_office(at: Vector3) -> bool:
	return at.x>40.2 and at.x<67.8 and at.z>24 and at.z<48

func _initialize_office_navigation() -> void:
	var lifetime: RefCounted = self
	await root.get_tree().physics_frame
	if not is_instance_valid(lifetime.root) or not lifetime.root.is_inside_tree(): return
	office_navigation.region = Rect2i(0,0,31,28)
	office_navigation.cell_size = Vector2.ONE
	office_navigation.offset = Vector2(38.5,22.5)
	office_navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	office_navigation.update()
	var query := PhysicsShapeQueryParameters3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = .52
	capsule.height = 1.72
	query.shape = capsule
	query.collision_mask = 1
	var door := root.find_child("电报房木门",true,false) as StaticBody3D
	if door!=null: query.exclude = [door.get_rid()]
	var space := root.get_world_3d().direct_space_state
	office_base_solid.resize(31*28)
	for y in 28:
		for x in 31:
			query.transform.origin = Vector3(38.5+x,.99,22.5+y)
			var solid := not space.intersect_shape(query,1).is_empty()
			office_base_solid[y*31+x] = int(solid)
			office_navigation.set_point_solid(Vector2i(x,y),solid)
	office_navigation_ready = true
	set_office_door(office_door_open)

func set_office_door(opened: bool) -> void:
	office_door_open = opened
	if not office_navigation_ready: return
	for y in range(13,19): office_navigation.set_point_solid(Vector2i(3,y),office_base_solid[y*31+3]!=0 or not opened)

func _office_anchor(at: Vector3) -> Vector2i:
	var cell := Vector2i(floori(at.x-38),floori(at.z-22))
	var best := Vector2i(-1,-1)
	var distance := INF
	for y in range(maxi(0,cell.y-3),mini(27,cell.y+3)+1):
		for x in range(maxi(0,cell.x-3),mini(30,cell.x+3)+1):
			var target := Vector3(38.5+x,.08,22.5+y)
			if not office_navigation.is_point_solid(Vector2i(x,y)) and target.distance_squared_to(at)<distance and _path_segment_clear(at,target):
				best = Vector2i(x,y)
				distance = target.distance_squared_to(at)
	return best

func _office_path(from: Vector3,to: Vector3) -> PackedVector3Array:
	var route := PackedVector3Array()
	var a := _office_anchor(from)
	var b := _office_anchor(to)
	if a.x<0 or b.x<0: return route
	for point in office_navigation.get_point_path(a,b): route.append(Vector3(point.x,.08,point.y))
	if not route.is_empty() and _path_segment_clear(route[-1],to): route.append(to)
	return route

func _path_anchor(point: Vector3) -> Vector2i:
	var cell := cell_at(point)
	if not navigation.is_point_solid(cell) and _path_segment_clear(point, cell_position(cell)):
		return cell
	# Only connect nearby free cells through verified capsule clearance. Never
	# relocate the actor or connect across a closed gate, wall or solid prop.
	var nearest := Vector2i(-1,-1)
	var best := INF
	for y in range(maxi(1,cell.y-1), mini(GRID_SIZE.y-2,cell.y+1)+1):
		for x in range(maxi(1,cell.x-1), mini(GRID_SIZE.x-2,cell.x+1)+1):
			var candidate := Vector2i(x,y)
			if navigation.is_point_solid(candidate): continue
			var center := cell_position(candidate)
			var distance := Vector2(point.x-center.x,point.z-center.z).length_squared()
			if distance < best and _path_segment_clear(point,center):
				best = distance
				nearest = candidate
	return nearest

func _path_segment_clear(from: Vector3, to: Vector3) -> bool:
	_path_capsule.radius = .33
	_path_capsule.height = 1.72
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _path_capsule
	query.collision_mask = 1
	query.margin = .001
	query.transform.origin = Vector3(from.x,maxf(from.y, .12)+.86,from.z)
	var space := root.get_world_3d().direct_space_state
	if not space.intersect_shape(query,1).is_empty(): return false
	query.motion = Vector3(to.x-from.x,0,to.z-from.z)
	return space.cast_motion(query)[0] >= .9999

func relocate_to_walkable(point: Vector3) -> Vector3:
	# Old checkpoints can predate the route fences. Preserve an already valid
	# position, otherwise choose the nearest free grid centre at the same height.
	if _inside_office(point) and _path_segment_clear(point,point): return point
	if not navigation.is_point_solid(cell_at(point)):
		return point
	var nearest := point
	var nearest_distance := INF
	for y in range(1, GRID_SIZE.y - 1):
		for x in range(1, GRID_SIZE.x - 1):
			var cell := Vector2i(x, y)
			if navigation.is_point_solid(cell):
				continue
			var candidate := cell_position(cell)
			candidate.y = point.y
			var distance := point.distance_squared_to(candidate)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = candidate
	return nearest

func set_route_gate(id: String, opened: bool) -> void:
	if not route_gates.has(id):
		return
	var gate: Dictionary = route_gates[id]
	var body: StaticBody3D = gate["body"]
	var collider: CollisionShape3D = gate["collider"]
	body.visible = not opened
	body.collision_layer = 0 if opened else 1
	collider.set_deferred("disabled", opened)
	for cell in gate.get("cells",[gate["cell"]]):
		var solid: bool = not opened
		if first_level.ready: solid = solid or first_level.base_solid[cell.y*GRID_SIZE.x+cell.x]!=0
		navigation.set_point_solid(cell,solid)
	gate["opened"] = opened

func _build_route_gate(id: String, cell: Vector2i, sideways: bool = false) -> void:
	var body := StaticBody3D.new()
	body.name = "路线栅门_%s" % id
	body.position = cell_position(cell) + Vector3(0, 1.4, 0)
	body.rotation.y = PI * 0.5 if sideways else 0.0
	body.set_meta("route_gate", true)
	root.add_child(body)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(TILE, 2.8, 0.32)
	collider.shape = shape
	body.add_child(collider)
	# Keep these meshes under the dynamic body so static batching cannot detach
	# their visibility from the gate's state.
	for i in 9:
		var plank := MeshInstance3D.new()
		plank.mesh = _unit_box
		plank.material_override = materials["wood"]
		plank.position.x = -1.8 + i * 0.45
		plank.scale = Vector3(0.35, 2.7, 0.22)
		body.add_child(plank)
	for height in [-0.85, 0.85]:
		var brace := MeshInstance3D.new()
		brace.mesh = _unit_box
		brace.material_override = materials["iron"]
		brace.position = Vector3(0, height, 0.14)
		brace.scale = Vector3(TILE, 0.13, 0.09)
		body.add_child(brace)
	route_gates[id] = {"body": body, "collider": collider, "cell": cell, "opened": true}
	set_route_gate(id, true)

func _build_linear_route() -> void:
	_build_route_gate("checkpoint", Vector2i(8, 14))
	_build_route_gate("yard", Vector2i(8, 10))
	_build_route_gate("river", Vector2i(17, 5), true)
	for z in [61.5, 45.5]:
		box("应急弹药箱", Vector3(36.8, 0.35, z), Vector3(0.8, 0.7, 0.65), "wood")
		_sign("備用彈藥", Vector3(36.8, 0.9, z + 0.35), 0.0)
	# Small cover islands leave a full walking lane beside each encounter.
	for cell in [Vector2i(6, 16), Vector2i(11, 17), Vector2i(6, 8), Vector2i(14, 4)]:
		var at := cell_position(cell)
		for row in 3:
			for bag in 3:
				var stagger := 0.16 if row % 2 == 1 else 0.0
				box("路线沙袋", at + Vector3((bag - 1) * 0.86 + stagger, 0.19 + row * 0.35, 0), Vector3(0.92, 0.38, 1.0), "sandbag")
		navigation.set_point_solid(cell)
	var timber_at := cell_position(Vector2i(6, 12))
	box("巷口木料掩体", timber_at + Vector3(0, 0.48, 0), Vector3(2.8, 0.96, 1.2), "wood")
	for i in 3:
		var log := cylinder("巷口圆木", timber_at + Vector3(0, 1.15, (i - 1) * 0.35), 0.22, 2.8, "bark")
		log.rotation.z = PI * 0.5
	navigation.set_point_solid(Vector2i(6, 12))
	_route_sign("木料場 ↑", Vector3(37.7, 1.95, 60.7), 0.0)
	_route_sign("電報房 ↑", Vector3(37.7, 1.95, 44.7), 0.0)
	_route_sign("渡口 →", Vector3(39.1, 1.95, 21.2), 0.0)

func _route_sign(text: String, at: Vector3, yaw: float) -> void:
	var board := box("路线木牌", at, Vector3(2.5, 0.65, 0.12), "wood", false)
	board.rotation.y = yaw
	box("路线木牌立柱", at - Vector3(0, 0.96, 0), Vector3(0.14, 1.85, 0.14), "bark", false)
	_sign(text, at + Basis(Vector3.UP, yaw) * Vector3(0, 0, 0.08), yaw)

func _block(cell: Vector2i, material_name: String, height: float = 3.8) -> void:
	blocked.append(cell)
	navigation.set_point_solid(cell)
	var position := cell_position(cell)
	position.y = height * 0.5
	var barrier := box("围墙", position, Vector3(TILE, height, TILE), material_name)
	route_walls[cell] = barrier
	if cell.x == GRID_SIZE.x - 1 and cell.y in [3, 4]:
		# Keep the established collision and navigation boundary, but open the
		# dock's view to the river with a low quay and a thin timber railing.
		barrier.name = "渡口护岸"
		var mesh := barrier.get_child(0) as MeshInstance3D
		mesh.scale.y = 0.24
		mesh.position.y = (0.24 - height) * 0.5
		var rail_x := position.x - TILE * 0.5 + 0.12
		for offset in [-1.85, 1.85]:
			box("渡口栏柱", Vector3(rail_x, 0.77, position.z + offset), Vector3(0.17, 1.06, 0.17), "bark", false)
		box("渡口木扶手", Vector3(rail_x, 1.18, position.z), Vector3(0.14, 0.12, TILE), "wood", false)
		return
	if material_name == "wood":
		box("墙顶木梁", position + Vector3(0, height * .5, 0), Vector3(TILE + .08, .16, TILE + .08), "bark", false)

func _build_side_wires() -> void:
	# Close unused dead-end spurs, leaving the logger, supplies and escort road open.
	side_wires.append(WireFence.add_blocker(root, "木棚北侧尽头封路", Vector3(4,0,58), Vector3(20,0,58)))
	side_wires.append(WireFence.add_blocker(root, "装卸区东侧支巷封路", Vector3(64,0,47.1), Vector3(64,0,56)))
	# Reserve intersected grid cells as well as the visible low collision.
	for body in side_wires:
		var size: Vector3 = (body.get_child(0).shape as BoxShape3D).size
		for y in range(1, GRID_SIZE.y-1):
			for x in range(1, GRID_SIZE.x-1):
				var local := body.to_local(cell_position(Vector2i(x,y)))
				if absf(local.x) < size.x*.5 + TILE*.5 and absf(local.z) < size.z*.5 + TILE*.5:
					navigation.set_point_solid(Vector2i(x,y))

func _build_office() -> void:
	var shell := (load("res://assets/user_expansion_20261015/office.glb") as PackedScene).instantiate()
	shell.name = "用户电报房_双拱顶"
	# Separate the supplied floor from the ground to prevent depth-fighting rings.
	shell.position = Vector3(54, .035, 36)
	root.add_child(shell)
	for mesh: MeshInstance3D in shell.find_children("*", "MeshInstance3D", true, false):
		mesh.create_trimesh_collision()
		for shape: CollisionShape3D in mesh.find_children("*","CollisionShape3D",true,false): shape.shape.backface_collision = true
	_build_office_enclosure()
	box("电报房门框北",Vector3(41.7,1.55,35.6),Vector3(.22,3.1,1.4),"iron")
	box("电报房门框南",Vector3(41.7,1.55,40.3),Vector3(.22,3.1,1.2),"iron")
	for x in range(10, 17):
		navigation.set_point_solid(Vector2i(x, 6))
		navigation.set_point_solid(Vector2i(x, 11))
	for y in range(7, 11):
		navigation.set_point_solid(Vector2i(16, y))
		if y != 9: navigation.set_point_solid(Vector2i(10, y))
	_collision_only_box("办公桌", Vector3(54, 0.45, 40), Vector3(2.8, 0.9, 1.5), "wood")
	navigation.set_point_solid(Vector2i(13, 10))
	for x in [52.9, 55.1]:
		_collision_only_box("桌腿", Vector3(x, 0.4, 40), Vector3(0.14, 0.8, 1.1), "wood")
	_collision_only_box("电报机", Vector3(54.6, 1.05, 40), Vector3(0.55, 0.34, 0.4), "iron")
	box("电话柜", Vector3(63.5, 1.0, 29.4), Vector3(1.5, 2.0, 0.8), "wood")
	box("电源闸", Vector3(63.0, 1.55, 30.2), Vector3(0.6, 0.65, 0.3), "iron")

func _build_office_enclosure() -> void:
	# The supplied warehouse is a cutaway. Close its skin, keeping the existing
	# sliding door and the interior mission route at z=38 unobstructed.
	for entry in [
		[Vector3(41.25,1.65,30.2),Vector3(.35,3.3,12.4)],
		[Vector3(41.25,1.65,43.85),Vector3(.35,3.3,8.3)],
		[Vector3(41.25,3.15,38.05),Vector3(.35,.3,3.3)],
		[Vector3(66.85,1.65,36),Vector3(.35,3.3,24)],
		[Vector3(54,1.65,24.15),Vector3(26,3.3,.35)],
		[Vector3(54,1.65,47.85),Vector3(26,3.3,.35)]]:
		box("电报房封闭砖墙",entry[0],entry[1],"brick")
	for x in [41.25,66.85]:
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for center in [30.0,42.0]:
			for i in 24:
				var a := PI*i/24.0
				var b := PI*(i+1)/24.0
				for p in [Vector3(x,3.3,center),Vector3(x,3.3+sin(a)*2.94,center+cos(a)*6),Vector3(x,3.3+sin(b)*2.94,center+cos(b)*6)]: surface.add_vertex(p)
		surface.generate_normals()
		var gable := MeshInstance3D.new()
		gable.name = "电报房拱顶封檐"
		gable.mesh = surface.commit()
		var mat: StandardMaterial3D = materials.wood.duplicate()
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		gable.material_override = mat
		root.add_child(gable)
		gable.create_trimesh_collision()
		for shape: CollisionShape3D in gable.find_children("*","CollisionShape3D",true,false): shape.shape.backface_collision = true

func _build_yard() -> void:
	var crate_positions := [Vector3(14, 0, 62), Vector3(30, 0, 70), Vector3(46, 0, 66), Vector3(46, 0, 54), Vector3(62, 0, 54), Vector3(78, 0, 38)]
	for position in crate_positions:
		box("木货箱", position + Vector3(0, 0.85, 0), Vector3(2.4, 1.7, 2.3), "wood")
		for height in [0.1, 1.6]:
			box("货箱箍", position + Vector3(0, height, 0), Vector3(2.46, 0.12, 2.36), "iron")
		navigation.set_point_solid(cell_at(position))
	for z in [48, 50, 52]:
		box("铁路枕木", Vector3(72, 0.04, z), Vector3(3.0, 0.13, 0.35), "wood", false)
	for x in [71.2, 72.8]:
		# The route crosses the rail ends at the river gate. These shallow ground
		# details must not trap capsule feet or interrupt Lu Shan's escort path.
		box("钢轨", Vector3(x, 0.17, 46), Vector3(0.09, 0.13, 48), "iron", false)
	box("平板货车", Vector3(72, 0.9, 60), Vector3(3.8, 0.3, 7.5), "wood")
	for z in [57.5, 62.5]:
		for x in [70.5, 73.5]:
			var wheel := visual("车轮", Vector3(x, 0.55, z), CylinderMesh.new(), "iron")
			wheel.scale = Vector3(0.9, 0.2, 0.9)
			wheel.rotation.z = PI * 0.5
	for x in range(6):
		box("沙袋工事", Vector3(63 + x * 0.85, 0.65, 20), Vector3(0.9, 1.3, 0.65), "sandbag")
	box("检查口横梁", Vector3(22, 3.5, 74), Vector3(4.2, 0.3, 0.4), "wood")
	for z in [71.8, 76.2]:
		box("岗亭柱", Vector3(22, 1.75, z), Vector3(0.3, 3.5, 0.3), "wood")

func _build_river() -> void:
	var river := build_supplied_river(Vector3(103.7, 0, 48))
	water = river.find_child("SuppliedRiverWater", true, false) as MeshInstance3D
	build_supplied_dock(Vector3(76, 0, 14))
	box("栈桥入岸连接", Vector3(75.6, -.13, 14), Vector3(3.3, .24, 2.4), "wood")
	_build_boat(Vector3(91, -1.7, 18))
	for z in range(8, 91, 12):
		box("江堤柱", Vector3(85.8, 0.8, z), Vector3(0.3, 1.6, 0.3), "wood", false)

func build_supplied_river(at: Vector3, yaw: float = 0) -> Node3D:
	var river := (load("res://assets/user_expansion_20261015/river.glb") as PackedScene).instantiate() as Node3D
	river.name = "用户河道与砂石岸"
	river.set_meta("blockout_retained", true)
	river.set_meta("user_waterfront", "river")
	river.position = at
	river.rotation.y = yaw
	root.add_child(river)
	for mesh: MeshInstance3D in river.find_children("*", "MeshInstance3D", true, false):
		if str(mesh.name) == "SuppliedRiverWater":
			var material: ShaderMaterial = materials.water.duplicate()
			var downstream := Basis(Vector3.UP,yaw)*Vector3.BACK
			material.set_shader_parameter("current_direction",Vector2(downstream.x,downstream.z))
			mesh.material_override = material
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		elif str(mesh.name) in ["SuppliedRiverBank_2","SuppliedRiverBank_4"]:
			# The source bank's flat top shares y=0 with the playable ground.
			mesh.position.y -= .04
			var bank_material: StandardMaterial3D = materials.mud.duplicate()
			bank_material.cull_mode = BaseMaterial3D.CULL_DISABLED
			mesh.material_override = bank_material
	return river

func build_supplied_dock(at: Vector3, yaw: float = 0) -> Node3D:
	var dock := (load("res://assets/user_expansion_20261015/dock.glb") as PackedScene).instantiate() as Node3D
	dock.name = "用户渡口木栈桥"
	dock.set_meta("blockout_retained", true)
	dock.set_meta("user_waterfront", "dock")
	dock.position = at
	dock.position.y += .04
	dock.rotation.y = yaw
	root.add_child(dock)
	for mesh: MeshInstance3D in dock.find_children("*", "MeshInstance3D", true, false):
		mesh.create_trimesh_collision()
	return dock

func _build_reeds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1938
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 7:
		var base := Vector3(rng.randf_range(-0.28, 0.28), 0, rng.randf_range(-0.28, 0.28))
		var height := rng.randf_range(0.75, 1.5)
		var tip := base + Vector3(0.10, height, 0.04)
		_strip(surface, base, tip, 0.014, Color(0.6, 0.6, 0.6))
		for j in 3:
			var origin := base.lerp(tip, 0.24 + j * 0.2)
			var side := -1.0 if j % 2 == 0 else 1.0
			var end := origin + Vector3(side * 0.36, 0.2, 0.12)
			_triangle(surface, origin, origin.lerp(end, 0.5) + Vector3(0, 0.08, 0), end, Color(0.4, 0.4, 0.4))
		_strip(surface, tip, tip + Vector3(0.03, 0.23, 0), 0.04, Color(0.85, 0.85, 0.85))
	surface.generate_normals()
	var reed_mesh := surface.commit()
	for i in 36:
		# Reeds belong to the wet bank; scanned ferns define the close forest path.
		var position := Vector3(rng.randf_range(86.8, 90.2), -0.28, rng.randf_range(24, 86))
		var reed := visual("风动芦苇丛", position, reed_mesh, "reeds")
		reed.rotation.y = rng.randf_range(0, TAU)
		reed.scale = Vector3.ONE * rng.randf_range(0.45, 0.72)

func _build_distant_scene() -> void:
	for i in 4:
		var position := Vector3(142 + i * 18, 1.35, 20 + i * 19)
		box("对岸林舍", position, Vector3(8, 3.4, 6), "wood", false)
		_pitched_roof(position + Vector3(0, 1.7, 0), 9, 7, 1.4)
	for z in [24, 48, 72]:
		box("电报线杆", Vector3(82, 4.5, z), Vector3(0.25, 9, 0.25), "wood", false)
		box("横担", Vector3(82, 8.5, z), Vector3(2.4, 0.15, 0.15), "wood", false)
	for x in [81.4, 82.6]:
		box("电报线", Vector3(x, 8.2, 48), Vector3(0.025, 0.025, 48), "iron", false)

func _build_lamps() -> void:
	for position in [Vector3(22, 3.0, 74), Vector3(34, 3.0, 58), Vector3(48, 3.5, 36), Vector3(60, 3.5, 32), Vector3(78, 3, 14)]:
		var lamp := OmniLight3D.new()
		lamp.position = position
		lamp.light_color = Color("ffcc94")
		lamp.light_energy = 1.45
		lamp.omni_range = 7.2
		root.add_child(lamp)
		lights.append(lamp)
		cylinder("玻璃灯芯", position - Vector3(0, 0.08, 0), 0.023, 0.10, "glow")
		box("吊灯链", position + Vector3(0, 0.5, 0), Vector3(0.018, 0.6, 0.018), "iron", false)

func _setup_environment() -> void:
	var node := WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := PanoramaSkyMaterial.new()
	sky_material.panorama = load("res://assets/environment/hdris/kloofendal_overcast_puresky/kloofendal_overcast_puresky_2k.hdr")
	sky_material.energy_multiplier = 0.58
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b2b4a8")
	environment.ambient_light_energy = 0.46
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.fog_enabled = true
	environment.fog_light_color = Color("9da8a5")
	environment.fog_density = 0.0034
	environment.fog_sun_scatter = 0.08
	environment.fog_height = -0.2
	environment.fog_height_density = 0.022
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	node.environment = environment
	root.add_child(node)
	sunlight = DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-43, -38, 0)
	sunlight.light_color = Color("e5dfca")
	sunlight.light_energy = 0.62
	sunlight.shadow_enabled = true
	sunlight.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sunlight.directional_shadow_max_distance = 80
	sunlight.shadow_bias = 0.5
	sunlight.shadow_normal_bias = 1.5
	root.add_child(sunlight)

func _material(color: Color, pattern: String) -> StandardMaterial3D:
	var scanned: StandardMaterial3D = AssetDressing.material_for(pattern)
	if scanned != null:
		return scanned
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	material.uv1_scale = Vector3(0.65, 0.65, 0.65)
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if _texture_cache.has(pattern):
		material.albedo_texture = _texture_cache[pattern][0]
		material.normal_texture = _texture_cache[pattern][1]
		material.normal_enabled = true
		material.normal_scale = 0.18
		return material
	var image := Image.create(256, 256, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = pattern.hash()
	var noise := FastNoiseLite.new()
	noise.seed = absi(pattern.hash()) % 65535
	noise.frequency = 0.037
	noise.fractal_octaves = 3
	for y in 256:
		for x in 256:
			var weather := noise.get_noise_2d(x, y)
			var factor := 0.88 + weather * 0.16 + rng.randf_range(-0.035, 0.035)
			if pattern == "brick" and (y % 32 < 2 or (x + (32 if y / 32 % 2 == 0 else 0)) % 64 < 2):
				factor = 0.6
			if pattern == "wood" and x % 64 < 2:
				factor = 0.58
			if pattern == "wood":
				factor *= 0.88 + 0.12 * sin(x * 1.7 + sin(y * 0.028) * 3 + weather * 1.8)
				if x % 64 > 5 and x % 64 < 8 and (y + x / 64 * 39) % 128 < 3:
					factor = 0.25
			if pattern == "endgrain":
				var distance := Vector2(x - 128, y - 128).length()
				factor = 0.8 + sin(distance * 0.65 + weather * 3) * 0.1 + weather * 0.15
			if pattern == "birch" and y % 23 < 3 and sin(x * 0.1 + y) > 0:
				factor = 0.3
			if pattern == "mud":
				factor = 0.8 + weather * 0.3 + rng.randf_range(-0.025, 0.025)
			if pattern == "iron":
				factor = 0.75 + weather * 0.4 + rng.randf_range(-0.03, 0.03)
			if pattern == "tile" and (x % 16 < 2 or y % 32 < 2):
				factor = 0.65
			image.set_pixel(x, y, Color(factor, factor, factor))
	var normals := Image.create(256, 256, false, Image.FORMAT_RGB8)
	for y in 256:
		for x in 256:
			var dx := image.get_pixel((x + 1) % 256, y).r - image.get_pixel((x + 255) % 256, y).r
			var dy := image.get_pixel(x, (y + 1) % 256).r - image.get_pixel(x, (y + 255) % 256).r
			var normal := Vector3(-dx * 1.8, dy * 1.8, 1.0).normalized()
			normals.set_pixel(x, y, Color(normal.x * 0.5 + 0.5, normal.y * 0.5 + 0.5, normal.z * 0.5 + 0.5))
	image.generate_mipmaps()
	normals.generate_mipmaps()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.albedo_texture = ImageTexture.create_from_image(image)
	material.normal_enabled = true
	material.normal_texture = ImageTexture.create_from_image(normals)
	material.normal_scale = 0.18
	_texture_cache[pattern] = [material.albedo_texture, material.normal_texture]
	if pattern == "mud":
		material.uv1_scale = Vector3(0.18, 0.18, 0.18)
		material.normal_enabled = false
	if pattern == "iron":
		material.metallic = 0.55
		material.roughness = 0.6
	return material

func set_power(enabled: bool) -> void:
	for lamp in lights:
		lamp.visible = enabled
	glow_material.emission_enabled = enabled
	glow_material.albedo_color = Color("ffd69a") if enabled else Color("554f40")
	if asset_dressing != null:
		asset_dressing.set_power(enabled)

func cylinder(title: String, at: Vector3, radius: float, height: float, material: String, top_radius: float = -1) -> MeshInstance3D:
	var ratio := 1.0 if top_radius < 0 else top_radius / maxf(radius, 0.001)
	var key := "cylinder_%0.3f" % ratio
	if not _mesh_cache.has(key):
		var mesh := CylinderMesh.new()
		mesh.top_radius = ratio
		mesh.bottom_radius = 1
		mesh.height = 1
		mesh.radial_segments = 12
		_mesh_cache[key] = mesh
	var node := visual(title, at, _mesh_cache[key], material)
	node.scale = Vector3(radius, height, radius)
	return node

func _pitched_roof(at: Vector3, width: float, depth: float, rise: float) -> void:
	for side in [-1, 1]:
		var half := width * 0.5
		var roof := box("坡屋面", at + Vector3(side * half * 0.5, rise * 0.5, 0), Vector3(sqrt(half * half + rise * rise), 0.22, depth), "tile", false)
		roof.rotation.z = -side * atan2(rise, half)
		var lining := box("坡顶木板内衬", at + Vector3(side * half * 0.5, rise * 0.5 - 0.16, 0), Vector3(sqrt(half * half + rise * rise), 0.08, depth - 0.08), "wood", false)
		lining.rotation.z = roof.rotation.z
	box("屋脊", at + Vector3(0, rise, 0), Vector3(0.23, 0.22, depth + 0.2), "bark", false)
	for side in [-1, 1]:
		box("屋檐木封边", at + Vector3(side * width * 0.5, -0.05, 0), Vector3(0.15, 0.28, depth + 0.1), "wood", false)
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		_triangle(surface, Vector3(-width * 0.5, 0, 0), Vector3(width * 0.5, 0, 0), Vector3(0, rise, 0), Color.WHITE)
		_triangle(surface, Vector3(0, rise, 0), Vector3(width * 0.5, 0, 0), Vector3(-width * 0.5, 0, 0), Color.WHITE)
		surface.generate_normals()
		visual("山墙木板", at + Vector3(0, 0, side * (depth * 0.5 - 0.2)), surface.commit(), "wood")
	for rib in range(1, int(depth / 1.4)):
		for side in [-1, 1]:
			var half := width * 0.5
			var batten := box("屋面接缝", at + Vector3(side * half * 0.5, rise * 0.5 + 0.13, -depth * 0.5 + rib * 1.4), Vector3(sqrt(half * half + rise * rise), 0.04, 0.035), "iron", false)
			batten.rotation.z = -side * atan2(rise, half)

func _tree(at: Vector3, height: float, birch: bool = false) -> void:
	# Both land surfaces stop at the river; reject trunks and crowns over water.
	if at.x > 84 and at.x < 137:
		return
	for cabin in 4:
		if Vector2(at.x-142-cabin*18,at.z-20-cabin*19).length() < 10:
			return
	at.y = -0.38 if at.x < 0 or at.x > 88 or at.z < 0 or at.z > 96 else -0.03
	forest_positions.append(at)
	var first_child := root.get_child_count()
	cylinder("白桦" if birch else "松树干", at + Vector3.UP * height * 0.5, 0.16 if birch else 0.29, height, "birch" if birch else "bark", 0.075)
	var variant := absi(int(at.x * 3 + at.z)) % 3
	var crown := visual("疏枝秋桦" if birch else "层叠松针", at, _canopy_mesh(birch, variant), "leaf" if birch else "pine")
	crown.scale = Vector3.ONE * height / 10.0
	crown.rotation.y = at.x + at.z
	if birch:
		for i in 6:
			var angle := i * 2.4 + crown.rotation.y
			var branch := cylinder("桦树侧枝", at + Vector3(sin(angle) * 0.54, height * (0.55 + i * 0.06), cos(angle) * 0.54), 0.043, height * 0.23, "birch", 0.009)
			branch.rotation = Vector3(cos(angle) * 0.7, 0, -sin(angle) * 0.7)
	if route_blockout.overlaps_slot(at, 1.8):
		for index in range(first_child, root.get_child_count()):
			route_blockout.retain(root.get_child(index), "tree_crown_intersects_reserved_structure")

func _canopy_mesh(birch: bool, variant: int) -> ArrayMesh:
	var key := "canopy_%s_%d" % [birch, variant]
	if _mesh_cache.has(key):
		return _mesh_cache[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = 3871 + variant * 59 + (20 if birch else 0)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tier in (8 if birch else 7):
		var y := (5.5 + tier * 0.46) if birch else (2.5 + tier * 1.02)
		var radius := (1.9 - tier * 0.12) if birch else (2.55 - tier * 0.32)
		for limb in (5 if birch else 8):
			var angle := limb * TAU / (5.0 if birch else 8.0) + tier * 1.4 + rng.randf_range(-0.24, 0.24)
			var forward := Vector3(cos(angle), 0, sin(angle))
			var side := Vector3(-forward.z, 0, forward.x)
			var start := Vector3(0, y, 0)
			var end := start + forward * radius + Vector3.UP * (0.75 if birch else -0.12)
			_strip(surface, start, end, 0.032, Color(0.08, 0.08, 0.08))
			for spray in (12 if birch else 9):
				var t := rng.randf_range(0.3, 1.0)
				var origin := start.lerp(end, t) + side * rng.randf_range(-0.5, 0.5) * (1.1 - t)
				origin.y += rng.randf_range(-0.18, 0.23)
				var tone := rng.randf_range(0.18, 0.95)
				var color := Color(tone, tone, tone)
				if birch:
					var leaf_side := side * rng.randf_range(0.06, 0.13)
					var leaf_tip := origin + forward * 0.17 + Vector3.UP * rng.randf_range(-0.18, 0.08)
					_triangle(surface, origin, origin + leaf_side + Vector3.UP * 0.035, leaf_tip, color)
					_triangle(surface, origin, leaf_tip, origin - leaf_side + Vector3.UP * 0.035, color)
				else:
					var length := rng.randf_range(0.24, 0.5) * (1.0 - t * 0.4)
					for needle in 3:
						var spread := side * (needle - 1) * length * 0.65
						var tip := origin + forward * length + spread + Vector3.UP * rng.randf_range(-0.08, 0.13)
						_triangle(surface, origin - side * 0.09, origin + side * 0.09, tip, color)
						_triangle(surface, origin + Vector3.UP * 0.08, origin - Vector3.UP * 0.08, tip, color)
	surface.generate_normals()
	var mesh := surface.commit()
	_mesh_cache[key] = mesh
	return mesh

func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	surface.set_color(color)
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)

func _strip(surface: SurfaceTool, a: Vector3, b: Vector3, width: float, color: Color) -> void:
	var side := (b - a).cross(Vector3.FORWARD).normalized() * width
	if side.length_squared() < 0.00001:
		side = Vector3.RIGHT * width
	_triangle(surface, a - side, a + side, b + side * 0.3, color)
	_triangle(surface, a - side, b + side * 0.3, b - side * 0.3, color)

func _build_ground_cover() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3810
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 5:
		var a := i * TAU / 5
		var side := Vector3(cos(a), 0, sin(a)) * 0.023
		var middle := Vector3(sin(a) * 0.05, 0.19 + i * 0.018, cos(a) * 0.06)
		var tip := Vector3(sin(a) * 0.15, 0.26 + i * 0.025, cos(a) * 0.16)
		_triangle(surface, -side, side, middle + side * 0.5, Color.WHITE)
		_triangle(surface, -side, middle + side * 0.5, middle - side * 0.5, Color.WHITE)
		_triangle(surface, middle - side * 0.5, middle + side * 0.5, tip, Color.WHITE)
	surface.generate_normals()
	var grass := MultiMeshInstance3D.new()
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.use_colors = true
	instances.mesh = surface.commit()
	instances.instance_count = 3600
	for i in 3600:
		var at := Vector3(rng.randf_range(4.5, 83), 0.01, rng.randf_range(5, 91))
		while (at.x > 39 and at.x < 69 and at.z > 23 and at.z < 49) or _is_dock_deck(at) or (at.x < 20.0 and at.z > 58) or route_blockout.overlaps_slot(at,0.3) or Rect2(25,60,12,5).has_point(Vector2(at.x,at.z)):
			at = Vector3(rng.randf_range(4.5, 83), 0.01, rng.randf_range(5, 91))
		var basis := Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3.ONE * rng.randf_range(0.7, 1.6))
		instances.set_instance_transform(i, Transform3D(basis, at))
		instances.set_instance_color(i, Color("8a835b").lerp(Color("474e36"), rng.randf()))
	grass.multimesh = instances
	grass.name = "分级风动地表草"
	grass.material_override = materials["reeds"]
	grass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(grass)
	_ground_batches.append(grass)

func _is_dock_deck(at: Vector3) -> bool:
	# A small margin also clears the width of a blade, pebble or leaf.
	return at.x >= 73.5 and at.x <= 88.5 and at.z >= 8.5 and at.z <= 20.5

func _build_forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1938
	for i in 140:
		var at := Vector3(rng.randf_range(-45, 165), 0, rng.randf_range(-38, 132))
		if at.x > -2 and at.x < 91 and at.z > -2 and at.z < 98:
			continue
		_tree(at, rng.randf_range(8, 16), i % 5 == 0)
	for at in [Vector3(6, 0, 80), Vector3(18, 0, 85), Vector3(7, 0, 70), Vector3(18, 0, 60), Vector3(7, 0, 50), Vector3(80, 0, 72), Vector3(80, 0, 34)]:
		_tree(at, rng.randf_range(7, 10), true)
	for i in 180:
		var at := Vector3(rng.randf_range(5, 82), 0.015, rng.randf_range(5, 90))
		if _is_dock_deck(at) or (at.x < 20 and at.z > 58):
			continue
		var leaf := box("落叶", at, Vector3(rng.randf_range(0.12, 0.28), 0.008, 0.07), "leaf", false)
		leaf.rotation.y = rng.randf_range(0, TAU)
	_build_mountain_ridges()

func _build_mountain_ridges() -> void:
	# Broad, irregular slopes replace the former single row of vertical facets.
	# Bases sit below the distant floor; every ridge is outside the play area.
	for direction in 3:
		for layer in (3 if direction == 0 else 2):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			for x in 48:
				for row in 6:
					var a := _ridge_point(x,row,layer,direction)
					var b := _ridge_point(x+1,row,layer,direction)
					var c := _ridge_point(x+1,row+1,layer,direction)
					var d := _ridge_point(x,row+1,layer,direction)
					var tone := 0.91 + sin(x*0.47+row*0.82+layer)*0.035
					_triangle(surface,a,c,b,Color(tone,tone,tone))
					_triangle(surface,a,d,c,Color(tone,tone,tone))
			surface.generate_normals()
			var material: StandardMaterial3D = materials["distant_land"].duplicate()
			material.albedo_color = Color("566e72").lerp(Color("9baeb0"),float(layer)*0.32)
			var mountain := visual("S12山脊_%d_%d" % [direction,layer],Vector3.ZERO,surface.commit(),"distant_land")
			mountain.material_override = material
			mountain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _ridge_point(column: int, row: int, layer: int, direction: int) -> Vector3:
	var u := float(column)
	var depth := float(row)/6.0
	var ridge_height := 25.0 + layer*14.0 + sin(u*0.23+layer*1.8+direction)*8.0 + sin(u*0.61+layer)*3.0
	var elevation := -2.0 + pow(sin(depth*PI),1.3)*ridge_height
	var offset := sin(u*0.4+layer)*7.0
	if direction == 0:
		return Vector3(-170+u*11.0,elevation,-43-layer*55-depth*105+offset)
	if direction == 1:
		return Vector3(-98-layer*70-depth*100+offset,elevation,-170+u*11.0)
	return Vector3(265+layer*65+depth*95+offset,elevation,-170+u*11.0)

func _build_details() -> void:
	# Stove and shelves stay outside the tested walking corridor.
	cylinder("炉身", Vector3(61.5, 0.65, 41.4), 0.48, 1.3, "iron")
	cylinder("烟管", Vector3(61.5, 3.8, 41.4), 0.12, 6.4, "iron")
	box("炉口", Vector3(61.5, 0.5, 40.92), Vector3(0.3, 0.3, 0.025), "glow", false)
	for y in [0.5, 1.1, 1.7]:
		box("搁板", Vector3(58, y, 43.7), Vector3(5, 0.09, 0.4), "wood", false)
		for x in [56.4, 57.2, 58, 58.8]:
			box("案卷", Vector3(x, y + 0.16, 43.6), Vector3(0.32, 0.3, 0.21), "paper", false)
	box("墙上地图", Vector3(53, 2.4, 43.95), Vector3(3, 1.7, 0.02), "paper", false)
	for i in 5:
		var line := box("地图山脊", Vector3(52 + i * 0.42, 2.4, 43.93), Vector3(0.025, 1.3, 0.015), "pine", false)
		line.rotation.z = 0.3 + i * 0.2
	for z in [39.4, 39.6]:
		box("电报记录纸", Vector3(53, 0.925, z), Vector3(0.52, 0.01, 0.21), "paper", false)
	# Lin's shelter and rest area.
	var logger_house := (load("res://assets/user_expansion_20261015/camp_4.glb") as PackedScene).instantiate()
	logger_house.name = "合集木屋_林工休息处"
	logger_house.position = Vector3(10, 0, 65)
	root.add_child(logger_house)
	_collision_only_box("林工木屋碰撞", Vector3(10, 1.5, 65), Vector3(5.2, 3, 3.5), "wood")
	navigation.set_point_solid(Vector2i(2, 16))
	box("林工长凳", Vector3(8.4, 0.5, 65), Vector3(0.65, 0.12, 3), "wood", false)
	_sign("歇腳棚", Vector3(17.4, 2.8, 66.5), PI * 0.5)
	# Log stacks use already blocked cells, preserving navigation clearance.
	for at in [Vector3(30, 0, 70), Vector3(46, 0, 54), Vector3(62, 0, 54)]:
		for i in 3:
			var log := cylinder("运材圆木", at + Vector3((i - 1) * 0.57, 1.94, 0), 0.28, 3.7, "bark")
			log.rotation.x = PI * 0.5
			var end := cylinder("木材端面", at + Vector3((i - 1) * 0.57, 1.94, 1.86), 0.25, 0.02, "wood_end")
			end.rotation.x = PI * 0.5
	for z in range(26, 70, 2):
		box("运材轨枕", Vector3(72, 0.01, z), Vector3(3, 0.04, 0.3), "wood", false)
	for z in range(10, 19):
		box("栈桥木板缝", Vector3(80, 0.012, z), Vector3(11, 0.012, 0.025), "bark", false)
	for i in 8:
		var rock := SphereMesh.new()
		rock.radial_segments = 8
		rock.rings = 4
		var node := visual("河岸石", Vector3(87, -0.3, 24 + i * 8), rock, "stone")
		node.scale = Vector3(2, 1.7, 2.3)

func _foliage_material(dark: Color, light: Color, wind: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/forest_foliage.gdshader")
	material.set_shader_parameter("shade_color", dark)
	material.set_shader_parameter("sun_color", light)
	material.set_shader_parameter("wind_strength", wind)
	_foliage_materials.append(material)
	return material

func _build_boat(at: Vector3) -> void:
	var boat := (load("res://assets/user_expansion_20261015/boat.glb") as PackedScene).instantiate() as Node3D
	boat.name = "用户木船与船桨"
	boat.set_meta("blockout_retained", true)
	boat.set_meta("user_waterfront", "boat")
	boat.position = at
	root.add_child(boat)

func _build_close_details() -> void:
	# Visual-only detailing: physics and the established navigation corridor stay identical.
	for at in [Vector3(14, 0, 62), Vector3(30, 0, 70), Vector3(46, 0, 66), Vector3(46, 0, 54), Vector3(62, 0, 54), Vector3(78, 0, 38)]:
		for z in [-1.17, 1.17]:
			for side in [-1, 1]:
				box("货箱角铁", at + Vector3(side * 1.15, 0.85, z), Vector3(0.12, 1.65, 0.035), "iron", false)
			var brace := box("斜撑木板", at + Vector3(0, 0.85, z * 1.02), Vector3(2.7, 0.16, 0.07), "wood", false)
			brace.rotation.z = 0.51
		for x in [-1.03, 1.03]:
			for y in [0.22, 1.47]:
				for z in [-1.205, 1.205]:
					box("锻钉", at + Vector3(x, y, z), Vector3(0.05, 0.05, 0.028), "iron", false)
	for z in range(28, 69, 2):
		for x in [71.05, 71.36, 72.64, 72.94]:
			box("道钉底座", Vector3(x, 0.17, z), Vector3(0.13, 0.05, 0.23), "iron", false)
	for x in [70.5, 73.5]:
		box("矿车侧框", Vector3(x, 1.08, 60), Vector3(0.1, 0.22, 7.45), "iron", false)
		for z in [57.5, 62.5]:
			box("货车悬架", Vector3(x, 0.7, z), Vector3(0.16, 0.13, 1.15), "iron", false)
	for z in [29, 33, 42]:
		for y in [0.4, 4.1]:
			box("梁柱铁扣", Vector3(39.83, y, z), Vector3(0.08, 0.15, 0.27), "iron", false)
	box("电报房踢脚木", Vector3(39.88, 0.22, 31), Vector3(0.18, 0.44, 13.7), "bark", false)
	box("电报房踢脚木", Vector3(39.88, 0.22, 43), Vector3(0.18, 0.44, 6), "bark", false)
	for x in range(46, 65, 3):
		box("档案室地板接缝", Vector3(x, 0.018, 36), Vector3(0.025, 0.012, 15.6), "bark", false)
	for y in [0.29, 1.08]:
		cylinder("炉身铸铁圈", Vector3(61.5, y, 41.4), 0.495, 0.07, "iron")
	for x in [61.2, 61.8]:
		box("炉脚", Vector3(x, 0.14, 41.4), Vector3(0.13, 0.28, 0.52), "iron", false)
	for i in 3:
		box("炉门栅", Vector3(61.4 + i * 0.1, 0.5, 40.895), Vector3(0.025, 0.3, 0.018), "iron", false)
	for x in [52.6, 53.4]:
		box("电报纸压条", Vector3(x, 0.94, 33.4), Vector3(0.05, 0.025, 0.35), "iron", false)
	for z in range(11, 19, 2):
		for x in [75.2, 81.1, 84.8]:
			box("栈桥铁钉", Vector3(x, 0.017, z), Vector3(0.045, 0.009, 0.045), "iron", false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1038
	var pebble_mesh := SphereMesh.new()
	pebble_mesh.radial_segments = 6
	pebble_mesh.rings = 3
	for i in 230:
		var at := Vector3(rng.randf_range(5, 82), 0.025, rng.randf_range(6, 89))
		if (at.x > 39 and at.x < 69 and at.z > 23 and at.z < 49) or _is_dock_deck(at):
			continue
		var stone := visual("碎砾", at, pebble_mesh, "stone")
		stone.scale = Vector3(rng.randf_range(0.06, 0.24), rng.randf_range(0.025, 0.1), rng.randf_range(0.07, 0.19))
		stone.rotation.y = rng.randf_range(0, TAU)

func _build_atmosphere() -> void:
	var leaf_mesh := QuadMesh.new()
	leaf_mesh.size = Vector2(0.04, 0.075)
	var leaf_material := StandardMaterial3D.new()
	leaf_material.albedo_color = Color("a98a50")
	leaf_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaf_material.vertex_color_use_as_albedo = true
	leaf_mesh.material = leaf_material
	for at in [Vector3(78, 5, 34)]:
		var leaves := CPUParticles3D.new()
		leaves.name = "林间飘叶"
		leaves.position = at
		leaves.amount = 16
		leaves.lifetime = 10
		leaves.preprocess = 4
		leaves.mesh = leaf_mesh
		leaves.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		leaves.emission_box_extents = Vector3(5, 1.5, 5)
		leaves.direction = Vector3(1, -0.5, 0.3)
		leaves.spread = 30
		leaves.initial_velocity_min = 0.25
		leaves.initial_velocity_max = 0.65
		leaves.gravity = Vector3(0.025, -0.075, 0)
		leaves.angular_velocity_min = -65
		leaves.angular_velocity_max = 85
		leaves.scale_amount_min = 0.7
		leaves.scale_amount_max = 1.3
		leaves.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(leaves)
		_atmosphere.append(leaves)
	# Soft chimney smoke uses a small unshaded billboard texture instead of volumetric fog.
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var radius := Vector2(x - 31.5, y - 31.5).length() / 32.0
			image.set_pixel(x, y, Color(0.61, 0.63, 0.60, pow(maxf(0, 1 - radius), 2.2) * 0.24))
	var smoke_material := StandardMaterial3D.new()
	smoke_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	smoke_material.vertex_color_use_as_albedo = true
	smoke_material.albedo_texture = ImageTexture.create_from_image(image)
	var smoke_mesh := QuadMesh.new()
	smoke_mesh.size = Vector2(1.8, 1.8)
	smoke_mesh.material = smoke_material
	var smoke := CPUParticles3D.new()
	smoke.name = "烟囱薄烟"
	smoke.position = Vector3(61.5, 7.05, 41.4)
	smoke.amount = 14
	smoke.lifetime = 7
	smoke.preprocess = 4
	smoke.mesh = smoke_mesh
	smoke.direction = Vector3.UP
	smoke.spread = 6
	smoke.initial_velocity_min = 0.2
	smoke.initial_velocity_max = 0.4
	smoke.gravity = Vector3(0.035, 0.015, 0.01)
	smoke.scale_amount_min = 0.45
	smoke.scale_amount_max = 1.15
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.45))
	fade.set_color(1, Color(1, 1, 1, 0))
	smoke.color_ramp = fade
	smoke.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(smoke)
	_atmosphere.append(smoke)

func _batch_static_visuals() -> void:
	# Chunking keeps culling useful; instancing cuts thousands of submissions to shared batches.
	var batches: Dictionary = {}
	var candidates: Array[MeshInstance3D] = []
	for child in root.get_children():
		if child.has_meta("route_gate") or child.has_meta("blockout_retained"):
			continue
		if child is MeshInstance3D and child != water and child.visible:
			candidates.append(child)
		else:
			for part in child.get_children():
				if part is MeshInstance3D and part.visible:
					candidates.append(part)
	for mesh in candidates:
		if mesh.material_override == null: continue
		var at := mesh.global_position
		var chunk := Vector2i(floori(at.x / 32), floori(at.z / 32))
		var key := "%s_%s_%d_%d_%d" % [mesh.mesh.get_instance_id(), mesh.material_override.get_instance_id(), chunk.x, chunk.y, mesh.cast_shadow]
		if not batches.has(key):
			batches[key] = []
		batches[key].append(mesh)
	for key in batches:
		var parts: Array = batches[key]
		var first: MeshInstance3D = parts[0]
		var batch := MultiMeshInstance3D.new()
		batch.name = "静态合批_%s" % first.name
		var center := Vector3(floorf(first.global_position.x / 32) * 32 + 16, 0, floorf(first.global_position.z / 32) * 32 + 16)
		batch.position = root.global_transform.affine_inverse() * center
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = first.mesh
		instances.instance_count = parts.size()
		for i in parts.size():
			var instance: MeshInstance3D = parts[i]
			var placement := root.global_transform.affine_inverse() * instance.global_transform
			placement.origin -= batch.position
			instances.set_instance_transform(i, placement)
			instance.visible = false
			instance.queue_free()
		batch.multimesh = instances
		batch.material_override = first.material_override
		batch.cast_shadow = first.cast_shadow
		batch.set_meta("distant", first.global_position.x < -15 or first.global_position.x > 110 or first.global_position.z < -20 or first.global_position.z > GRID_SIZE.y*TILE+14)
		batch.set_meta("large_surface", (first.global_transform.basis * first.get_aabb().size).length() > 50)
		root.add_child(batch)
		static_batch_count += 1
		static_instance_count += parts.size()

func prepare_imported_materials(model: Node3D) -> void:
	for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh == null: continue
		mesh.visibility_range_end = 500.0
		mesh.visibility_range_end_margin = 24.0
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface)
			if material is BaseMaterial3D:
				material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC

func is_navigation_ready() -> bool:
	return first_level.ready and office_navigation_ready and village_world.navigation_ready

func is_world_ready() -> bool:
	return is_navigation_ready()

func apply_quality(level: int) -> void:
	quality_level = clampi(level, 0, 2)
	if not is_instance_valid(sunlight):
		return
	if asset_dressing != null:
		asset_dressing.apply_quality(quality_level)
	landscape.apply_quality(quality_level)
	sunlight.directional_shadow_max_distance = [42.0, 72.0, 96.0][quality_level]
	sunlight.directional_shadow_mode = [DirectionalLight3D.SHADOW_ORTHOGONAL,DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS,DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS][quality_level]
	sunlight.directional_shadow_split_1 = .16 if quality_level==1 else .1
	sunlight.directional_shadow_split_2 = .28
	sunlight.directional_shadow_split_3 = .55
	sunlight.directional_shadow_blend_splits = quality_level==2
	for material in _foliage_materials:
		material.set_shader_parameter("detail_wind", 0.0 if quality_level == 0 else 1.0)
	materials["water"].set_shader_parameter("wave_detail", 0.0 if quality_level == 0 else 1.0)
	for grass in _ground_batches:
		grass.multimesh.visible_instance_count = [1200, 2500, 3600][quality_level]
	for particles in _atmosphere:
		particles.visible = quality_level > 0
		particles.emitting = quality_level > 0
	for child in root.get_children():
		if child is MultiMeshInstance3D and child.has_meta("distant"):
			child.visibility_range_end = 0.0 if child.get_meta("large_surface") else [140.0, 200.0, 270.0][quality_level]
			if child.get_meta("distant"):
				child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for batch: MultiMeshInstance3D in root.find_children("*","MultiMeshInstance3D",true,false):
		if not batch.has_meta("vegetation_cell"): continue
		var casts: bool = batch.get_meta("vegetation_shadow")
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if casts and quality_level>0 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		batch.visibility_range_end = [240.0,380.0,460.0][quality_level]

func update(delta: float) -> void:
	clock += delta
	# Small irregular fluctuations retain the power-switch state and never toggle visibility.
	for i in lights.size():
		lights[i].light_energy = 1.45 + sin(clock * 3.1 + i * 1.7) * 0.035 + sin(clock * 8.2 + i) * 0.02

func _collision_only_box(object_name: String, position: Vector3, size: Vector3, material_name: String) -> Node3D:
	var node := box(object_name, position, size, material_name)
	(node.get_child(0) as MeshInstance3D).visible = false
	return node

func box(object_name: String, position: Vector3, size: Vector3, material_name: String, collision: bool = true) -> Node3D:
	var node: Node3D = StaticBody3D.new() if collision else Node3D.new()
	node.name = object_name
	node.position = position
	root.add_child(node)
	var mesh := MeshInstance3D.new()
	mesh.mesh = _unit_box
	mesh.scale = size
	mesh.material_override = materials[material_name]
	node.add_child(mesh)
	if collision:
		var collider := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		collider.shape = box_shape
		node.add_child(collider)
	return node

func visual(object_name: String, position: Vector3, mesh: Mesh, material_name: String) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = object_name
	node.position = position
	node.mesh = mesh
	node.material_override = materials[material_name]
	root.add_child(node)
	return node

func _sign(text: String, position: Vector3, yaw: float) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 72
	label.pixel_size = 0.006
	label.outline_size = 8
	label.modulate = Color("eef1d6")
	label.position = position
	label.rotation.y = yaw
	root.add_child(label)

extends RefCounted
## S09 scale/route study. These primitives are replaced by reviewed assets in S10/S11.
const SLOTS := {
	"D01": Rect2(-28, 57, 20, 20), "D02": Rect2(5, 48, 12, 10),
	"D03": Rect2(48, 63, 12, 21), "D04": Rect2(42, 4, 24, 12),
	"D05": Rect2(48, 49, 12, 6), "D06": Rect2(5, 76, 3, 5),
	"D07": Rect2(49, 50, 3, 3), "D08": Rect2(57, 39, 3, 3),
	"D09": Rect2(8, 61, 2, 2)}
var _world: WeakRef
var world: RefCounted:
	get: return _world.get_ref()
var container: Node3D
var enabled := false
var configured := false
var bodies: Array[StaticBody3D] = []
var footprints: Array[Rect2] = []
var original_cells: Dictionary = {}
var retained: Array[Dictionary] = []
var adjustments: Array[Dictionary] = []

func overlaps_slot(at: Vector3, margin: float = 0.0) -> bool:
	for bounds: Rect2 in SLOTS.values():
		if bounds.grow(margin).has_point(Vector2(at.x, at.z)): return true
	return false

func retain(node: Node3D, reason: String) -> void:
	node.set_meta("blockout_retained", true)
	retained.append({"node": node, "visible": node.visible})
	adjustments.append({"name": str(node.name), "position": [node.position.x,node.position.y,node.position.z], "action": "hidden_while_blockout_enabled", "reason": reason})

func build(owner_world: RefCounted) -> void:
	_world = weakref(owner_world)
	container = Node3D.new()
	container.name = "S09_路线简化结构"
	world.root.add_child(container)
	# S10 reviewed exteriors replace the S09 scale blocks. Collision remains
	# deliberately coarse and follows the reviewed footprint measurements.
	_reviewed_building("D01", Vector3(-18,0,67), Vector3.ONE, Vector3(-18,2.75,67), Vector3(12.7,5.5,11.8))
	_reviewed_building("D02", Vector3(11,-.819,53), Vector3.ONE, Vector3(11,1.45,53), Vector3(6,2.9,5.9))
	_reviewed_building("D03", Vector3(54,0,73.5), Vector3.ONE, Vector3(54,3.6,73.5), Vector3(10,7.2,17))
	_reviewed_building("D04", Vector3(54,0,10), Vector3.ONE, Vector3(54,2.4,10), Vector3(23.6,4.8,11.6))
	# D05 is an open shelter: use the adapted visual shell and eight low-post
	# colliders. D07 shares this roof and keeps its own stock collision.
	var d05_visual_position := Vector3(53.616, -1.964, 56.496)
	var d05_visual_scale := Vector3(1.7, 1.0, 1.75)
	_reviewed_model("D05", d05_visual_position, d05_visual_scale)
	var post_x := [-2.822854, -0.790666, 1.241522, 3.273710]
	var post_index := 0
	for local_x in post_x:
		for local_z in [-1.158019, -3.915762]:
			var post_position := Vector3(d05_visual_position.x + local_x * d05_visual_scale.x, .496, d05_visual_position.z + local_z * d05_visual_scale.z)
			_reviewed_collision("D05_post_" + str(post_index), post_position, Vector3(.374, .992, .385))
			post_index += 1
	_piece("D07_stock",Vector3(50.5,.7,51.5),Vector3(3,1.4,3),"wood")
	_piece("D06_counter",Vector3(6.5,.5,78.5),Vector3(2.2,1,3.8),"wood")
	_piece("D06_canopy",Vector3(6.5,2.3,78.5),Vector3(3,.22,5),"sandbag")
	for z in [76.2,80.8]: _piece("D06_post",Vector3(5.3,1.1,z),Vector3(.18,2.2,.18),"wood")
	_piece("D08_screen",Vector3(59.8,.8,40.5),Vector3(.2,1.6,3),"wood")
	_piece("D08_chest",Vector3(58.8,.4,41.5),Vector3(1.8,.8,1),"wood")
	_piece("D09_table",Vector3(9,.25,62),Vector3(2,.5,2),"wood")
	for item in world.asset_dressing.dressing_root.get_children():
		if item is Node3D and overlaps_slot(item.position, .3):
			retain(item, "scan_prop_intersects_reserved_structure")
	if "--qa" in OS.get_cmdline_user_args() or "--blockout-labels" in OS.get_cmdline_user_args():
		for id in SLOTS:
			var bounds: Rect2 = SLOTS[id]
			var label := Label3D.new()
			label.text = id + " · 简化结构"
			var label_height: float = {"D01":5.8,"D02":4.0,"D03":8.8,"D04":7.8,"D05":5.6,"D06":2.8,"D07":2.0,"D08":2.3,"D09":1.3}[id]
			label.position = Vector3(bounds.get_center().x,label_height,bounds.get_center().y)
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.font_size = 36
			label.pixel_size = .012
			container.add_child(label)
	set_enabled(bool(ProjectSettings.get_setting("development/route_blockout_enabled", true)) and "--no-route-blockout" not in OS.get_cmdline_user_args())

func _piece(id: String, at: Vector3, size: Vector3, material: String, collides: bool = true) -> Node3D:
	var node: Node3D = world.box(id, at, size, material, collides)
	node.reparent(container)
	if collides:
		bodies.append(node)
		if at.y - size.y*.5 < 1.9:
			footprints.append(Rect2(at.x-size.x*.5, at.z-size.z*.5, size.x, size.z))
	return node

func _building(id: String, base: Vector3, size: Vector3, rise: float) -> void:
	_piece(id+"_volume",base+Vector3.UP*size.y*.5,size,"wood" if id in ["D01","D02"] else "brick")
	var half := size.x*.5
	for side in [-1,1]:
		var roof := _piece(id+"_roof",base+Vector3(side*half*.5,size.y+rise*.5,0),Vector3(sqrt(half*half+rise*rise),.18,size.z),"tile",false)
		roof.rotation.z = -side*atan2(rise,half)
	# Plain openings are visual scale references; these buildings have no interiors.
	_piece(id+"_door",base+Vector3(0,1.15,size.z*.5+.02),Vector3(1.5,2.3,.04),"iron",false)
	for x in [-size.x*.3,size.x*.3]:
		_piece(id+"_window",base+Vector3(x,1.8,size.z*.5+.025),Vector3(1.3,.9,.05),"window",false)

func _reviewed_model(id: String, position: Vector3, scale: Vector3) -> Node3D:
	var assembly := Node3D.new()
	assembly.name = id + "_reviewed_model"
	assembly.position = position
	assembly.scale = scale
	var supplied := {"D01": "camp_1", "D02": "camp_2", "D03": "camp_3", "D04": "camp_1", "D05": "camp_4"}
	var scene := load("res://assets/user_expansion_20261015/" + supplied[id] + ".glb") as PackedScene
	if scene == null:
		push_error("Missing reviewed building scene: " + id)
	else:
		var model := scene.instantiate()
		model.name = id + "_model"
		var original_sizes := {"D01": Vector3(4.9344, 5.2, 10.3585), "D02": Vector3(2.9968, 3.5, 4.1938), "D03": Vector3(7.0731, 5.4, 12.5778), "D04": Vector3(4.9344, 5.2, 10.3585), "D05": Vector3(5.3297, 4.4, 3.6678)}
		var fit := {"D01": Vector3(12.7, 5.5, 11.8), "D02": Vector3(6, 3.7, 5.9), "D03": Vector3(10, 7.2, 17), "D04": Vector3(23.6, 5.2, 11.6), "D05": Vector3(6.0, 4.0, 3.0)}
		model.scale = fit[id] / original_sizes[id]
		if id == "D02": model.position.y = .819
		if id == "D05": model.position.y = 1.964
		assembly.add_child(model)
	container.add_child(assembly)
	return assembly

func _reviewed_building(id: String, visual_position: Vector3, visual_scale: Vector3, collision_position: Vector3, collision_size: Vector3) -> void:
	_reviewed_model(id, visual_position, visual_scale)
	_reviewed_collision(id + "_collision", collision_position, collision_size)

func _reviewed_collision(id: String, position: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = id
	body.position = position
	container.add_child(body)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	bodies.append(body)
	footprints.append(Rect2(position.x - size.x*.5, position.z - size.z*.5, size.x, size.z))
	return body

func set_enabled(value: bool) -> void:
	if value == enabled and configured: return
	configured = true
	enabled = value
	container.visible = value
	for body in bodies:
		body.collision_layer = 1 if value else 0
		for child in body.get_children():
			if child is CollisionShape3D: child.set_deferred("disabled", not value)
	for entry in retained: entry.node.visible = false if value else entry.visible
	if value:
		original_cells.clear()
		# Conservatively reserve each intersected 4 m cell, including capsule clearance.
		for y in range(1,world.GRID_SIZE.y-1):
			for x in range(1,world.GRID_SIZE.x-1):
				var cell := Vector2i(x,y)
				var area := Rect2(x*world.TILE,y*world.TILE,world.TILE,world.TILE)
				for bounds in footprints:
					if bounds.grow(.35).intersects(area):
						original_cells[cell] = world.navigation.is_point_solid(cell)
						world.navigation.set_point_solid(cell,true)
						break
	else:
		for cell in original_cells: world.navigation.set_point_solid(cell,original_cells[cell])
		original_cells.clear()

func hide_s11_slot_visuals() -> void:
	# Keep the coarse S09/S10 bodies for cover and navigation while removing
	# their placeholder meshes once S11 production dressing is present.
	if container == null:
		return
	var prefixes := ["D06_counter", "D06_canopy", "D06_post", "D07_stock", "D08_screen", "D08_chest", "D09_table"]
	for child in container.get_children():
		if not child is StaticBody3D:
			continue
		var name := str(child.name)
		var matched := false
		for prefix in prefixes:
			if name.begins_with(prefix):
				matched = true
				break
		if not matched:
			continue
		for mesh in child.find_children("*", "MeshInstance3D", true, false):
			(mesh as MeshInstance3D).visible = false
		child.set_meta("s11_visual_replaced", true)

func restore_position(point: Vector3) -> Vector3:
	if enabled:
		for bounds in footprints:
			if bounds.grow(.4).has_point(Vector2(point.x,point.z)):
				return world.relocate_to_walkable(point)
	return point

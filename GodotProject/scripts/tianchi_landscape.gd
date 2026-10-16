extends Node3D
## Decorations are sampled from the imported triangles, never a second height formula.

const ROCK_SHADER = preload("res://shaders/tianchi_rock.gdshader")
const PINE = preload("res://assets/environment/landscape/far_pine.glb")
const ROCK_COLOR = preload("res://assets/environment/textures/gravel_road/gravel_road_diff_2k.jpg")
var placements: Array[Dictionary] = []
var batches: Array[MultiMeshInstance3D] = []
var triangles: Array[Dictionary] = []
var total_area := 0.0
var near_details: Node3D
var rock_material: ShaderMaterial
var rng := RandomNumberGenerator.new()

func build(lake: Node3D, terrace: Node3D, routes: Array) -> void:
	name = "Changbai_Woodland_And_Rock"
	rng.seed = 19381015
	rock_material = ShaderMaterial.new()
	rock_material.shader = ROCK_SHADER
	rock_material.set_shader_parameter("rock_color", ROCK_COLOR)
	_collect_ground(lake)
	var noise := FastNoiseLite.new()
	noise.seed = 1938
	noise.frequency = 0.035
	var occupied: Dictionary = {}
	var groups: Dictionary = {}
	for attempt in 9000:
		if placements.size() >= 680: break
		var triangle := _pick_triangle()
		var u := sqrt(rng.randf())
		var v := rng.randf()
		var at: Vector3 = triangle.a * (1.0 - u) + triangle.b * u * (1.0 - v) + triangle.c * u * v
		var radius := Vector2(at.x - 564.0, at.z - 119.5).length()
		if radius < 57.0 or radius > 165.0 or at.y < 7.0 or at.y > 34.0: continue
		if triangle.normal.y < 0.70 or _near_route(at, routes, 6.5): continue
		var patch := noise.get_noise_2d(at.x, at.z)
		if patch < -0.25 or rng.randf() > smoothstep(36.0, 24.0, at.y): continue
		var cell := Vector2i(floori(at.x / 4.0), floori(at.z / 4.0))
		if occupied.has(cell): continue
		occupied[cell] = true
		var height := rng.randf_range(4.3, 8.6) * lerpf(0.65, 1.0, smoothstep(34.0, 20.0, at.y))
		var transform := Transform3D(Basis(Vector3.UP, rng.randf_range(0, TAU)).scaled(Vector3.ONE * height), at - Vector3.UP * 0.05)
		var key := Vector2i(floori(at.x / 64.0), floori(at.z / 64.0))
		if not groups.has(key): groups[key] = []
		groups[key].append({"transform":transform, "color":Color("a6b39d").lerp(Color("d2d0af"), rng.randf() * 0.6)})
		placements.append({"at":at, "height":height, "normal":triangle.normal, "sector":triangle.sector, "cell":cell})
	_build_pines(groups)
	_build_scree()
	near_details = Node3D.new()
	near_details.name = "Changbai_Terrace_Detail"
	terrace.add_child(near_details)
	_build_terrace(terrace)
	_set_layer(self)
	_set_layer(near_details)
	set_process(false)

func _collect_ground(lake: Node3D) -> void:
	var ledge := lake.find_child("S21_Talk_Platform_Base", true, false) as MeshInstance3D
	ledge.material_override = rock_material
	for child in lake.find_children("S21_Crater_*", "MeshInstance3D", true, false):
		var node := child as MeshInstance3D
		node.material_override = rock_material
		for surface in node.mesh.get_surface_count():
			var arrays := node.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for i in range(0, indices.size(), 3):
				var a: Vector3 = node.global_transform * vertices[indices[i]]
				var b: Vector3 = node.global_transform * vertices[indices[i + 1]]
				var c: Vector3 = node.global_transform * vertices[indices[i + 2]]
				var cross := (b - a).cross(c - a)
				var area := absf(cross.y) * 0.5
				if area < 0.00001: continue
				total_area += area
				var normal := cross.normalized()
				if normal.y < 0: normal = -normal
				triangles.append({"a":a, "b":b, "c":c, "normal":normal, "area_end":total_area, "sector":str(node.name)})

func _pick_triangle() -> Dictionary:
	var value := rng.randf() * total_area
	var lo := 0
	var hi := triangles.size() - 1
	while lo < hi:
		var mid := (lo + hi) / 2
		if float(triangles[mid].area_end) < value: lo = mid + 1
		else: hi = mid
	return triangles[lo]

func _near_route(at: Vector3, routes: Array, clearance: float) -> bool:
	if Vector2(at.x - 501.0, at.z - 145.5).length() < 13.0: return true
	for route in routes:
		for i in range(route.size() - 1):
			var a := Vector2(route[i].x, route[i].z)
			var b := Vector2(route[i + 1].x, route[i + 1].z)
			if Geometry2D.get_closest_point_to_segment(Vector2(at.x, at.z), a, b).distance_to(Vector2(at.x, at.z)) < clearance: return true
	return false

func _collect_parts(node: Node3D, transform: Transform3D, parts: Array[Dictionary]) -> void:
	var current := transform * node.transform
	if node is MeshInstance3D: parts.append({"mesh":node.mesh, "transform":current})
	for child in node.get_children():
		if child is Node3D: _collect_parts(child, current, parts)

func _build_pines(groups: Dictionary) -> void:
	var source := PINE.instantiate() as Node3D
	var parts: Array[Dictionary] = []
	_collect_parts(source, Transform3D.IDENTITY, parts)
	var bounds := AABB()
	for part in parts:
		var box: AABB = part.transform * part.mesh.get_aabb()
		bounds = box if bounds.size == Vector3.ZERO else bounds.merge(box)
	var normalize := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE / bounds.size.y), -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) / bounds.size.y)
	for part in parts:
		var mesh: Mesh = part.mesh.duplicate()
		for surface in mesh.get_surface_count():
			var mat := mesh.surface_get_material(surface).duplicate() as StandardMaterial3D
			mat.vertex_color_use_as_albedo = true
			mat.albedo_color = Color("97ad90")
			mat.roughness = 1.0
			mat.metallic_specular = 0.1
			if mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				mat.alpha_scissor_threshold = 0.43
				mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			mesh.surface_set_material(surface, mat)
		for key: Vector2i in groups:
			var center := Vector3(key.x * 64 + 32, 0, key.y * 64 + 32)
			var batch := _batch("Changbai_Pines", mesh, groups[key], center, normalize * part.transform)
			batch.set_meta("tree_batch", true)
	source.free()

func _batch(label: String, mesh: Mesh, group: Array, center: Vector3, offset: Transform3D = Transform3D.IDENTITY) -> MultiMeshInstance3D:
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = group.size()
	for i in group.size():
		var transform: Transform3D = group[i].transform * offset
		transform.origin -= center
		multi.set_instance_transform(i, transform)
		multi.set_instance_color(i, group[i].get("color", Color.WHITE))
	var node := MultiMeshInstance3D.new()
	node.name = label
	node.position = center
	node.multimesh = multi
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	batches.append(node)
	return node

func _boulder_mesh() -> ArrayMesh:
	var sphere := SphereMesh.new()
	sphere.radial_segments = 10
	sphere.rings = 5
	var arrays := sphere.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in vertices.size():
		var p := vertices[i]
		vertices[i] = p * (1.0 + sin(p.x * 13.0 + p.y * 7.0 + p.z * 9.0) * 0.18)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, rock_material)
	return mesh

func _build_scree() -> void:
	var stones: Array = []
	for i in 520:
		var triangle := _pick_triangle()
		var at: Vector3 = (triangle.a + triangle.b + triangle.c) / 3.0
		var radius := Vector2(at.x - 564.0, at.z - 119.5).length()
		if at.y < 12.7 or at.y > 40 or radius > 122.0: continue
		var size := rng.randf_range(0.25, 1.15)
		stones.append({"transform":Transform3D(Basis.from_euler(Vector3(rng.randf() * 0.3, rng.randf() * TAU, 0)).scaled(Vector3(size * 1.4, size, size * 1.1)), at)})
	_batch("Changbai_Shore_Scree", _boulder_mesh(), stones, Vector3(564, 12, 119.5))

func _build_terrace(terrace: Node3D) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector3(501, 26.01, 145.5)
	for i in 48:
		var angle0 := TAU * i / 48.0
		var angle1 := TAU * (i + 1) / 48.0
		var p0 := center + Vector3(cos(angle0) * 9.0, 0, sin(angle0) * 6.6) * (1.0 + 0.055 * sin(angle0 * 7))
		var p1 := center + Vector3(cos(angle1) * 9.0, 0, sin(angle1) * 6.6) * (1.0 + 0.055 * sin(angle1 * 7))
		for p in [center, p0, p1, p0, p1 - Vector3.UP * 2.6, p1, p0, p0 - Vector3.UP * 2.6, p1 - Vector3.UP * 2.6]:
			surface.set_uv(Vector2(p.x, p.z) * 0.2)
			surface.add_vertex(p)
	surface.generate_normals()
	var cap := MeshInstance3D.new()
	cap.name = "Changbai_Natural_Ledge"
	cap.mesh = surface.commit()
	cap.material_override = rock_material
	near_details.add_child(cap)
	var floor_node := terrace.get_node("S22_talk_platform_floor")
	for visual in floor_node.get_children():
		if visual is MeshInstance3D: visual.visible = false
	for node in terrace.find_children("*", "MeshInstance3D", true, false):
		if node.get_parent() == terrace: node.visible = false
		elif node.get_parent() is StaticBody3D: node.material_override = rock_material
	var rock_mesh := _boulder_mesh()
	for i in 26:
		var angle := TAU * i / 26.0
		if absf(angle - 3.5) < 0.6 or absf(angle - 4.1) < 0.45: continue
		var rock := MeshInstance3D.new()
		rock.name = "Changbai_Ledge_Boulder"
		rock.mesh = rock_mesh
		rock.position = center + Vector3(cos(angle) * rng.randf_range(8.3, 9.4), -0.1, sin(angle) * rng.randf_range(5.7, 6.6))
		rock.scale = Vector3(rng.randf_range(1.0, 2.2), rng.randf_range(0.45, 1.1), rng.randf_range(0.8, 1.5))
		rock.rotation.y = rng.randf() * TAU
		near_details.add_child(rock)
	_build_low_growth(center)

func _build_low_growth(center: Vector3) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 72:
		var angle := rng.randf() * TAU
		var at := center + Vector3(cos(angle) * rng.randf_range(7.8, 9.0), 0.03, sin(angle) * rng.randf_range(5.5, 6.3))
		if at.distance_to(Vector3(496.5, 26, 140.5)) < 2.0: continue
		for blade in 4:
			var yaw := rng.randf() * TAU
			var side := Vector3(cos(yaw), 0, sin(yaw)) * 0.08
			var tip := at + Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0.18, 0.55), rng.randf_range(-0.2, 0.2))
			for point in [at - side, at + side, tip]:
				surface.set_color(Color("667258").lerp(Color("969477"), rng.randf() * 0.6))
				surface.add_vertex(point)
	surface.generate_normals()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var node := MeshInstance3D.new()
	node.name = "Changbai_Alpine_Grass"
	node.mesh = surface.commit()
	node.material_override = material
	near_details.add_child(node)

func _set_layer(node: Node) -> void:
	if node is VisualInstance3D: node.layers = 2
	for child in node.get_children(): _set_layer(child)

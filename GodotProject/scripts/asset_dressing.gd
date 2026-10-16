extends RefCounted

# Selected CC0 Poly Haven sources. Coordinates are visual dressing only: the
# established navigation grid, story anchors and physics bodies remain owned by world.gd.
const BASE := "res://assets/environment/"
const S11_ASSET_PATHS := {
	"village_market": "res://assets/environment/models/s11/village_market/village_market.glb",
	"market_stalls": "res://assets/environment/models/s11/market_stalls/market_stalls.glb",
	"chinese_screen_panels": "res://assets/environment/models/s11/chinese_screen_panels/chinese_screen_panels_2k.gltf",
	"chinese_tea_table": "res://assets/environment/models/s11/chinese_tea_table/chinese_tea_table_2k.gltf",
	"wicker_basket_01": "res://assets/environment/models/s11/wicker_basket_01/wicker_basket_01_2k.gltf"
}
var dressing_root: Node3D
var scene_cache: Dictionary = {}
var meshes: Array[MeshInstance3D] = []
var fixture_lights: Array[OmniLight3D] = []
var emissive_materials: Array[StandardMaterial3D] = []
var imported_instance_count := 0

static func pbr(asset: String, uv_scale: float = 0.5, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var path := BASE + "textures/" + asset + "/" + asset
	mat.albedo_texture = load(path + ("_diffuse_2k.jpg" if asset == "brick_wall_001" else "_diff_2k.jpg"))
	mat.normal_texture = load(path + "_nor_gl_2k.jpg")
	mat.roughness_texture = load(path + "_rough_2k.jpg")
	mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	mat.normal_enabled = true
	mat.normal_scale = 0.28
	mat.roughness = 1.0
	mat.metallic_specular = 0.22
	mat.albedo_color = tint
	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3.ONE * uv_scale
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return mat

static func material_for(pattern: String) -> StandardMaterial3D:
	match pattern:
		"wood": return pbr("weathered_brown_planks", 0.47, Color("bfc4c2"))
		"brick": return pbr("brick_wall_001", 0.5, Color("b4b6ad"))
		"mud": return pbr("forest_ground_04", 0.22, Color("91998d"))
		"tile": return pbr("grey_roof_tiles", 0.55, Color("a4b0ae"))
		"iron":
			var mat := pbr("rusty_metal_04", 0.8, Color("7d898a"))
			mat.metallic = 0.45
			return mat
	return null

func build(parent: Node3D) -> void:
	dressing_root = Node3D.new()
	dressing_root.name = "扫描资源场景细节"
	parent.add_child(dressing_root)
	_ground_surfaces()
	_forest_edge()
	_shelter()
	_office()
	for at in [Vector3(22, 2.70, 74), Vector3(34, 2.70, 58), Vector3(48, 3.20, 36), Vector3(60, 3.20, 32), Vector3(78, 2.70, 14)]:
		_spawn("Lantern_01", at, 0.43, 0.15, "", 0, Vector3.ZERO, 44)

func build_s11() -> void:
	# S11 visual dressing is added after the S09/S10 route container has built.
	# Coarse route bodies remain the gameplay boundary; these props add readable
	# life and production use without changing navigation cells.
	var d06 := _spawn("village_market", Vector3(6.5, 0, 78.5), 0, 0, "", 0, Vector3(2.7, 2.35, 1.45), 42)
	_mark_s11(d06, "D06", "检查口外侧生活摊棚")
	_mark_s11(_wood_box("D06木凳_东", Vector3(7.55, 0.22, 80.0), Vector3(0.48, 0.44, 0.48), 34), "D06", "摊棚座凳")
	_mark_s11(_wood_box("D06木凳_西", Vector3(5.45, 0.22, 80.0), Vector3(0.48, 0.44, 0.48), 34), "D06", "摊棚座凳")
	_mark_s11(_spawn("wicker_basket_01", Vector3(5.65, 0.27, 79.25), 0, 0.10, "", 0, Vector3(0.48, 0.36, 0.48), 32), "D06", "生活筐")
	_mark_s11(_spawn("wicker_basket_01", Vector3(7.25, 0.27, 79.25), 0, -0.15, "", 0, Vector3(0.48, 0.36, 0.48), 32), "D06", "生活筐")
	_spawn("Lantern_01", Vector3(6.5, 2.08, 78.5), 0.30, 0.2, "", 0, Vector3.ZERO, 34)
	_fixture(Vector3(6.5, 2.14, 78.5), 0.65, 3.5)

	var d07 := _spawn("market_stalls", Vector3(50.5, 0, 51.5), 0, 0.04, "", 0, Vector3(2.55, 2.10, 1.45), 40)
	_mark_s11(d07, "D07", "D05棚内生产摊台")
	_mark_s11(_spawn("wooden_crate_01", Vector3(49.35, 0.52, 52.35), 0, 0.18, "", 0.62, Vector3.ZERO, 32), "D07", "木料周转箱")
	_mark_s11(_spawn("wine_barrel_01", Vector3(51.85, 0.46, 52.35), 0.88, -0.15, "", 0, Vector3.ZERO, 34), "D07", "生产储桶")
	_mark_s11(_spawn("wooden_axe_02", Vector3(52.65, 0.72, 51.95), 0.68, -0.45, "", 0, Vector3.ZERO, 30), "D07", "木工工具")
	_log_bundle(Vector3(50.35, 0.34, 52.65), 3, "D07")
	_log_bundle(Vector3(50.35, 0.82, 52.65), 3, "D07")

	var d08 := _spawn("chinese_screen_panels", Vector3(59.15, 0, 40.55), 0, PI * 0.5, "", 0, Vector3(0.18, 1.70, 2.25), 40)
	_mark_s11(d08, "D08", "电报房东南屏风")
	_mark_s11(_spawn("wicker_basket_01", Vector3(58.05, 0.27, 41.15), 0, 0.2, "", 0, Vector3(0.44, 0.33, 0.44), 30), "D08", "档案传递筐")
	_mark_s11(_spawn("wicker_basket_01", Vector3(59.05, 0.27, 41.55), 0, -0.1, "", 0, Vector3(0.44, 0.33, 0.44), 30), "D08", "档案传递筐")

	var d09 := _spawn("chinese_tea_table", Vector3(9.0, 0, 62.15), 0, 0.1, "", 0, Vector3(1.28, 0.55, 0.82), 38)
	_mark_s11(d09, "D09", "林工棚谈话低桌")
	var d09_screen := _spawn("chinese_screen_panels", Vector3(8.55, 0, 62.15), 0, PI * 0.5, "", 0, Vector3(0.14, 1.55, 1.20), 34)
	_mark_s11(d09_screen, "D09", "林工棚半遮屏风")
	_mark_s11(_spawn("wicker_basket_01", Vector3(9.55, 0.22, 61.45), 0, 0.15, "", 0, Vector3(0.42, 0.32, 0.42), 30), "D09", "补给筐")
	_mark_s11(_spawn("wicker_basket_01", Vector3(8.55, 0.22, 61.45), 0, -0.15, "", 0, Vector3(0.42, 0.32, 0.42), 30), "D09", "补给筐")
	_spawn("Lantern_01", Vector3(9.0, 1.58, 62.15), 0.26, 0.1, "", 0, Vector3.ZERO, 30)

	# A small shared production table and stacked timber make the D05 roof read
	# as a work space while leaving its tested player/AI corridor unchanged.
	_mark_s11(_spawn("WoodenTable_01", Vector3(55.85, 0, 52.75), 0, PI * 0.5, "", 0, Vector3(1.45, 0.82, 0.78), 36), "D05", "棚内加工桌")
	_mark_s11(_spawn("wooden_bucket_01", Vector3(56.95, 0.35, 52.72), 0.40, 0.2, "", 0, Vector3.ZERO, 30), "D05", "棚内取水桶")
	_log_bundle(Vector3(54.75, 0.33, 53.55), 3, "D05")
	_log_bundle(Vector3(54.75, 0.81, 53.55), 3, "D05")

func build_s12() -> void:
	# Two distinct ground materials make the timber lane and approach readable
	# while staying 2 cm above the existing floor plane.
	var chips := pbr("wood_chips", 0.23, Color("a08b6c"))
	_ground_patch("S12木料巷木屑", Vector3(49.2, 0.020, 53.0), Vector2(7.0, 3.1), chips, 48)
	_ground_patch("S12木料巷木屑_返程", Vector3(31.0, 0.020, 62.5), Vector2(5.8, 2.2), chips, 42)
	var gravel := pbr("gravel_road", 0.20, Color("8d9187"))
	_ground_patch("S12检查口碎石", Vector3(17.5, 0.019, 76.0), Vector2(5.4, 2.0), gravel, 52)
	_ground_patch("S12渡口碎石", Vector3(70.0, 0.019, 20.8), Vector2(5.2, 1.8), gravel, 52)

func _mark_s11(node: Node3D, slot: String, purpose: String) -> void:
	if node == null:
		return
	node.set_meta("s11_dressing", true)
	node.set_meta("s11_slot", slot)
	node.set_meta("s11_purpose", purpose)

func _wood_box(title: String, at: Vector3, size: Vector3, view_range: float) -> Node3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _visual(title, mesh, pbr("weathered_brown_planks", 0.52, Color("9f896e")), at, view_range)

func _log_bundle(origin: Vector3, count: int, slot: String) -> void:
	for i in count:
		var offset := (float(i) - float(count - 1) * 0.5) * 0.48
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.22
		mesh.bottom_radius = 0.25
		mesh.height = 2.35
		mesh.radial_segments = 10
		var log := _visual("S11_%s木材" % slot, mesh, pbr("pine_bark", 0.62, Color("8c7355")), origin + Vector3(offset, 0, 0), 34)
		log.rotation.z = PI * 0.5
		log.set_meta("s11_dressing", true)
		log.set_meta("s11_slot", slot)
		log.set_meta("s11_purpose", "叠放木材")

func _ground_surfaces() -> void:
	# A worn trail with irregular edges; stays only 14 mm above the existing floor.
	var trail_mat := pbr("muddy_tracks", 0.25, Color("969b92"))
	trail_mat.roughness = 0.80
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 32:
		var z0 := 59.0 + i
		var z1 := z0 + 1.0
		var c0 := 11.5 + sin(z0 * 0.22) * 0.7
		var c1 := 11.5 + sin(z1 * 0.22) * 0.7
		var w0 := 2.15 + sin(z0 * 1.43) * 0.23
		var w1 := 2.15 + sin(z1 * 1.43) * 0.23
		_quad(surface, Vector3(c0-w0, 0.014, z0), Vector3(c0+w0, 0.014, z0), Vector3(c1+w1, 0.014, z1), Vector3(c1-w1, 0.014, z1))
	surface.generate_normals()
	_visual("林道泥辙", surface.commit(), trail_mat, Vector3.ZERO, 100)
	var leaf_mat := pbr("brown_mud_leaves_01", 0.43, Color("a6aaa1"))
	for at in [Vector3(7.2, 0.018, 84), Vector3(17.0, 0.018, 80), Vector3(7.6, 0.018, 74), Vector3(17.8, 0.018, 59), Vector3(36.8, 0.018, 41.5)]:
		_ground_patch("潮湿落叶堆", at, Vector2(1.6, 2.2), leaf_mat, 43)
	var wet_mat := StandardMaterial3D.new()
	wet_mat.albedo_color = Color("293333")
	wet_mat.roughness = 0.13
	wet_mat.metallic = 0.25
	wet_mat.normal_enabled = true
	wet_mat.normal_texture = load(BASE + "textures/muddy_tracks/muddy_tracks_nor_gl_2k.jpg")
	wet_mat.normal_scale = 0.055
	wet_mat.uv1_triplanar = true
	wet_mat.uv1_world_triplanar = true
	wet_mat.uv1_scale = Vector3.ONE * 0.8
	for item in [Vector4(10.3, 88.1, 0.56, 1.5), Vector4(12.6, 77.8, 0.48, 1.1), Vector4(10.2, 70.1, 0.70, 1.4), Vector4(31.2, 61.2, 1.1, 0.62), Vector4(37.5, 38.5, 0.68, 0.9)]:
		_ground_patch("浅积水", Vector3(item.x, 0.022, item.y), Vector2(item.z, item.w), wet_mat, 47)
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(19.9, 15.9)
	_visual("电报房旧木地板", floor_mesh, pbr("weathered_brown_planks", 0.34, Color("a69b86")), Vector3(54, 0.027, 36), 70)

func _forest_edge() -> void:
	_spawn("dead_tree_trunk", Vector3(6.9, 0.01, 85.8), 0, 0.65, "", 3.7, Vector3.ZERO, 38)
	_spawn("dead_tree_trunk", Vector3(17.3, 0.01, 76.8), 0, 1.5, "", 3.1, Vector3.ZERO, 36)
	for item in [Vector3(7.4, 0, 78.0), Vector3(17.3, 0, 87.5), Vector3(18, 0, 61.4)]:
		_spawn("tree_stump_01", item, 0.48, item.z * 0.14, "", 0, Vector3.ZERO, 34)
	var rocks := [Vector4(5.2, 88.7, 0.60, 0.2), Vector4(18.7, 82.4, 0.75, 2.4), Vector4(5.6, 71.5, 0.45, 1.1), Vector4(37.1, 42.5, 0.68, 0.5)]
	for i in rocks.size():
		var at: Vector4 = rocks[i]
		_spawn("rock_moss_set_01", Vector3(at.x, -0.04, at.y), at.z, at.w, "rock_moss_set_01_rock0%d" % (i + 1), 0, Vector3.ZERO, 45)
	# Two detailed young pines only; the existing instanced trees carry the distant canopy.
	_spawn("pine_sapling_small", Vector3(5.5, -0.03, 81.8), 3.7, -0.6, "", 0, Vector3.ZERO, 29)
	_spawn("pine_sapling_small", Vector3(18.1, -0.03, 73.2), 3.0, 1.7, "", 0, Vector3.ZERO, 27)
	var rng := RandomNumberGenerator.new()
	rng.seed = 193804
	for i in 28:
		var at := Vector3(rng.randf_range(5.3, 7.4) if i % 2 == 0 else rng.randf_range(17.3, 19.2), 0.01, rng.randf_range(71.2, 90.1))
		_spawn("fern_02", at, rng.randf_range(0.32, 0.63), rng.randf_range(0, TAU), "fern_02_%s" % ["a", "b", "c", "d"][i % 4], 0, Vector3.ZERO, 26)

func _shelter() -> void:
	for at in [Vector3(8.5, 0, 62), Vector3(8.5, 0, 67)]:
		_spawn("wine_barrel_01", at, 1.0, 0.2, "", 0, Vector3.ZERO, 44)
	_spawn("wooden_crate_01", Vector3(8.45, 0.56, 65), 0, 0.1, "", 0.88, Vector3.ZERO, 36)
	_spawn("wooden_bucket_01", Vector3(8.8, 0, 68.0), 0.50, 0.6, "", 0, Vector3.ZERO, 30)
	_spawn("wooden_axe_02", Vector3(8.0, 0.65, 63.3), 0.65, -0.4, "", 0, Vector3.ZERO, 27)
	_spawn("Lantern_01", Vector3(8.6, 0.56, 64.1), 0.34, 0.35, "", 0, Vector3.ZERO, 30)
	_fixture(Vector3(8.6, 0.82, 64.1), 1.45, 5.6)
	# These small chests sit inside the footprint of existing cargo cover.
	_spawn("wooden_crate_01", Vector3(46.0, 1.70, 66.0), 0, 0.30, "", 1.12, Vector3.ZERO, 38)
	_spawn("wooden_crate_01", Vector3(46.0, 1.70, 54.0), 0, -0.15, "", 0.98, Vector3.ZERO, 38)

func _office() -> void:
	# Exact desktop elevation preserves the codebook anchor and the tested route around it.
	_spawn("WoodenTable_01", Vector3(54, 0, 40), 0, 0, "", 0, Vector3(2.8, 0.90, 1.5), 60)
	_spawn("vintage_radio_transceiver", Vector3(54.65, 0.905, 40.05), 0, 0.05, "", 0.93, Vector3.ZERO, 35)
	_spawn("Lantern_01", Vector3(55.0, 0.905, 40.43), 0.33, 0.25, "", 0, Vector3.ZERO, 32)
	_fixture(Vector3(54.94, 1.17, 40.39), 0.80, 4.0)
	_spawn("WoodenTable_01", Vector3(45.35, 0, 28.95), 0, PI * 0.5, "", 0, Vector3(1.25, 0.76, 0.64), 38)
	_spawn("Lantern_01", Vector3(45.35, 0.76, 29.0), 0.34, 0, "", 0, Vector3.ZERO, 35)
	_fixture(Vector3(45.35, 1.06, 29.0), 1.65, 4.8)
	_spawn("wooden_bucket_01", Vector3(45.3, 0.03, 31.55), 0.44, 0.7, "", 0, Vector3.ZERO, 27)
	_spawn("wooden_crate_01", Vector3(45.0, 0.03, 33.3), 0, PI * 0.5, "", 0.9, Vector3.ZERO, 32)

func _spawn(asset: String, at: Vector3, height: float, yaw: float, piece: String = "", width: float = 0.0, fit_size: Vector3 = Vector3.ZERO, view_range: float = 40.0) -> Node3D:
	if not scene_cache.has(asset):
		var path: String = S11_ASSET_PATHS.get(asset, BASE + "models/" + asset + "/" + asset + "_2k.gltf")
		scene_cache[asset] = load(path) as PackedScene
	var packed: PackedScene = scene_cache[asset]
	if packed == null:
		push_error("Environment source failed to load: " + asset)
		return null
	var instance: Node3D = packed.instantiate()
	if not piece.is_empty():
		var chosen := instance.find_child(piece, true, false) as MeshInstance3D
		if chosen == null:
			push_error("Missing environment mesh: " + piece)
			instance.free()
			return null
		var chosen_copy := chosen.duplicate() as MeshInstance3D
		instance.free()
		instance = Node3D.new()
		instance.add_child(chosen_copy)
	var bounds := _bounds(instance)
	var factor := Vector3.ONE
	if fit_size != Vector3.ZERO:
		factor = fit_size / bounds.size.max(Vector3.ONE * 0.001)
	elif height > 0:
		factor *= height / maxf(bounds.size.y, 0.001)
	elif width > 0:
		factor *= width / maxf(maxf(bounds.size.x, bounds.size.z), 0.001)
	var holder := Node3D.new()
	holder.name = asset + "_实物"
	dressing_root.add_child(holder)
	holder.add_child(instance)
	instance.scale = factor
	instance.position = -Vector3(bounds.position.x + bounds.size.x * 0.5, bounds.position.y, bounds.position.z + bounds.size.z * 0.5) * factor
	holder.position = at
	holder.rotation.y = yaw
	for mesh in _meshes(instance):
		mesh.visibility_range_end = view_range
		mesh.visibility_range_end_margin = 3
		mesh.set_meta("environment_range", view_range)
		mesh.set_meta("environment_small", asset in ["fern_02", "Lantern_01", "wooden_axe_02"])
		mesh.set_meta("environment_foliage", asset in ["fern_02", "pine_sapling_small"])
		mesh.lod_bias = 1.0
		meshes.append(mesh)
	imported_instance_count += 1
	return holder

func _bounds(node: Node3D, transform: Transform3D = Transform3D.IDENTITY) -> AABB:
	var result := AABB()
	var current := transform * node.transform
	if node is MeshInstance3D:
		result = current * node.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			var child_bounds := _bounds(child, current)
			if child_bounds.size != Vector3.ZERO:
				result = child_bounds if result.size == Vector3.ZERO else result.merge(child_bounds)
	return result

func _meshes(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_meshes(child))
	return result

func _visual(title: String, mesh: Mesh, mat: Material, at: Vector3, view_range: float) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = title
	visual.mesh = mesh
	visual.material_override = mat
	visual.position = at
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visual.set_meta("environment_range", view_range)
	visual.set_meta("environment_small", false)
	dressing_root.add_child(visual)
	meshes.append(visual)
	return visual

func _ground_patch(title: String, at: Vector3, radii: Vector2, material: Material, view_range: float) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 18:
		var a := i * TAU / 18.0
		var b := (i + 1) * TAU / 18.0
		var ra := 0.91 + sin(a * 5.0 + at.x) * 0.08 + cos(a * 3.0) * 0.04
		var rb := 0.91 + sin(b * 5.0 + at.x) * 0.08 + cos(b * 3.0) * 0.04
		surface.add_vertex(Vector3.ZERO)
		surface.add_vertex(Vector3(cos(b) * radii.x * rb, 0, sin(b) * radii.y * rb))
		surface.add_vertex(Vector3(cos(a) * radii.x * ra, 0, sin(a) * radii.y * ra))
	surface.generate_normals()
	_visual(title, surface.commit(), material, at, view_range)

func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for point in [a, c, b, a, d, c]:
		surface.add_vertex(point)

func _fixture(at: Vector3, energy: float, radius: float) -> void:
	var lamp := OmniLight3D.new()
	lamp.name = "煤油灯暖光"
	lamp.position = at
	lamp.light_color = Color("ffc68d")
	lamp.light_energy = energy
	lamp.omni_range = radius
	lamp.omni_attenuation = 1.5
	lamp.shadow_enabled = false
	dressing_root.add_child(lamp)
	fixture_lights.append(lamp)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color("ffce94")
	glow.emission_enabled = true
	glow.emission = Color("ffc182")
	glow.emission_energy_multiplier = 1.7
	var core := SphereMesh.new()
	core.radius = 0.023
	core.height = 0.07
	core.radial_segments = 8
	core.rings = 4
	_visual("灯芯", core, glow, at - Vector3(0, 0.06, 0), 28)
	emissive_materials.append(glow)

func set_power(enabled: bool) -> void:
	for light in fixture_lights:
		light.visible = enabled
	for material in emissive_materials:
		material.emission_enabled = enabled

func apply_quality(level: int) -> void:
	for mesh in meshes:
		mesh.visibility_range_end = float(mesh.get_meta("environment_range")) * [0.76, 1.0, 1.22][level]
		if mesh.get_meta("environment_small"):
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if level == 0 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if mesh.get_meta("environment_foliage", false):
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if level == 2 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh.lod_bias = [0.65, 1.0, 1.3][level]

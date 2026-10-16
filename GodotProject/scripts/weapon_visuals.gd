extends RefCounted
## Original weapon geometry with continuous imported skinned hands.
## Static gun pieces stay baked; wrists, fingers, bolt and clip animate separately.

const FPHands = preload("res://scripts/fp_hands.gd")

# Camera-space framing from the user's 2026-10-15 reference. Move the complete
# weapon/hand assembly: its geometry, grip contacts and mechanisms keep one scale.
const HIP_POSITIONS := [Vector3(0.24, -0.255, -0.35), Vector3(0.16, -0.20, -0.45)]
const HIP_ROTATION := Vector3(0.015, 0.06, 0.0)
const AIM_POSITIONS := [Vector3(0.0, -0.093, -0.53), Vector3(0.0, -0.085, -0.53)]
const SAFE_POSITION := Vector3(0.27, -0.16, -0.42)
const SAFE_ROTATION := Vector3(-0.72, 0.40, -0.12)

static var materials: Dictionary = {}

static func build(index: int) -> Dictionary:
	_ensure_materials()
	if index == 0:
		return _supplied_rifle()
	var root := Node3D.new()
	root.name = "Rifle" if index == 0 else "MauserPistol"
	var body: Dictionary = {}
	var mechanism := Node3D.new()
	mechanism.name = "Bolt"
	root.add_child(mechanism)
	var bolt_parts: Dictionary = {}
	var clip := Node3D.new()
	clip.name = "StripperClip"
	root.add_child(clip)
	var clip_parts: Dictionary = {}
	if index == 0:
		# A bevelled full-length wooden stock, separate handguard, round barrel.
		_loft(body, "wood", [Vector4(-0.53, -0.004, 0.025, 0.023), Vector4(-0.32, -0.008, 0.032, 0.032), Vector4(-0.10, -0.018, 0.036, 0.042), Vector4(0.035, -0.027, 0.034, 0.043), Vector4(0.115, -0.063, 0.027, 0.038), Vector4(0.21, -0.095, 0.038, 0.07), Vector4(0.43, -0.085, 0.044, 0.084)])
		_loft(body, "wood", [Vector4(-0.50, 0.035, 0.023, 0.014), Vector4(-0.24, 0.041, 0.028, 0.022), Vector4(-0.15, 0.04, 0.027, 0.016)])
		_rod(body, "steel", Vector3(0, 0.044, -0.16), Vector3(0, 0.044, -0.72), 0.015, 16)
		_rod(body, "edge", Vector3(0, 0.044, -0.705), Vector3(0, 0.044, -0.723), 0.016, 16)
		_rod(body, "black", Vector3(0, 0.044, -0.724), Vector3(0, 0.044, -0.726), 0.009, 12)
		_loft(body, "steel", [Vector4(-0.163, 0.027, 0.039, 0.024), Vector4(0.067, 0.027, 0.039, 0.024)])
		_rod(body, "steel", Vector3(0, 0.054, -0.17), Vector3(0, 0.054, -0.04), 0.028, 12)
		_box(body, "black", Vector3(0, 0.05, -0.025), Vector3(0.05, 0.013, 0.105))
		_rod(bolt_parts, "edge", Vector3(0.004, 0.058, -0.08), Vector3(0.004, 0.058, 0.045), 0.016, 12)
		_rod(bolt_parts, "steel", Vector3(0.012, 0.051, 0.035), Vector3(0.074, 0.014, 0.035), 0.009, 10)
		_ellipsoid(bolt_parts, "edge", Vector3(0.078, 0.01, 0.035), Vector3(0.017, 0.018, 0.017))
		for z in [-0.48, -0.25]:
			_loft(body, "steel", [Vector4(z - 0.009, 0.005, 0.034 if z > -0.3 else 0.029, 0.044), Vector4(z + 0.009, 0.005, 0.034 if z > -0.3 else 0.029, 0.044)])
		_box(body, "steel", Vector3(0, -0.087, 0.438), Vector3(0.086, 0.16, 0.013), Vector3(0.07, 0, 0))
		# Raised tangent rear sight with a genuine notch, and front sight ears.
		_box(body, "steel", Vector3(0, 0.075, -0.18), Vector3(0.033, 0.012, 0.083), Vector3(-0.06, 0, 0))
		for x in [-0.014, 0.014]:
			_box(body, "edge", Vector3(x, 0.091, -0.142), Vector3(0.017, 0.017, 0.014))
		_box(body, "steel", Vector3(0, 0.068, -0.67), Vector3(0.036, 0.014, 0.042))
		_box(body, "edge", Vector3(0, 0.086, -0.67), Vector3(0.006, 0.025, 0.013))
		for x in [-0.018, 0.018]:
			_box(body, "steel", Vector3(x, 0.084, -0.67), Vector3(0.005, 0.031, 0.027))
		_loop(body, "steel", Vector3(0, -0.05, 0.015), Vector2(0.035, 0.048), 0.006)
		_rod(body, "edge", Vector3(0, -0.035, 0.008), Vector3(0, -0.07, 0.0), 0.004, 8)
		for z in [-0.105, 0.07]:
			_rod(body, "edge", Vector3(-0.037, -0.007, z), Vector3(0.037, -0.007, z), 0.008, 10)
		_clip_geometry(clip_parts, 5, 0.014, 0.056)
	else:
		_loft(body, "steel", [Vector4(-0.15, 0.019, 0.029, 0.038), Vector4(0.012, 0.019, 0.034, 0.036), Vector4(0.045, 0.012, 0.027, 0.029)])
		_rod(body, "steel", Vector3(0, 0.043, -0.115), Vector3(0, 0.043, -0.385), 0.014, 16)
		_rod(body, "edge", Vector3(0, 0.043, -0.37), Vector3(0, 0.043, -0.388), 0.015, 16)
		_rod(body, "black", Vector3(0, 0.043, -0.389), Vector3(0, 0.043, -0.390), 0.008, 12)
		_box(body, "steel", Vector3(0, -0.048, -0.106), Vector3(0.055, 0.088, 0.08), Vector3(0.05, 0, 0))
		_box(body, "edge", Vector3(0, -0.095, -0.106), Vector3(0.06, 0.008, 0.084))
		_box(body, "steel", Vector3(0, -0.072, 0.043), Vector3(0.061, 0.169, 0.065), Vector3(-0.23, 0, 0))
		for x in [-0.033, 0.033]:
			_ellipsoid(body, "wood", Vector3(x, -0.08, 0.047), Vector3(0.013, 0.075, 0.033), Vector3(-0.23, 0, 0))
			for n in 11:
				_box(body, "wood_dark", Vector3(x * 1.31, -0.141 + n * 0.012, 0.047 + (-0.141 + n * 0.012 + 0.08) * -0.2), Vector3(0.003, 0.002, 0.046))
			_rod(body, "edge", Vector3(x, -0.08, 0.047), Vector3(x * 1.44, -0.08, 0.047), 0.007, 10)
		_loop(body, "steel", Vector3(0, -0.043, -0.021), Vector2(0.03, 0.028), 0.005)
		_rod(body, "edge", Vector3(0, -0.016, -0.01), Vector3(0, -0.052, -0.024), 0.004, 8)
		_box(body, "black", Vector3(0, 0.057, -0.058), Vector3(0.039, 0.008, 0.077))
		_box(bolt_parts, "edge", Vector3(0, 0.06, -0.044), Vector3(0.033, 0.013, 0.10))
		_box(bolt_parts, "steel", Vector3(0, 0.052, 0.037), Vector3(0.064, 0.019, 0.019))
		_box(body, "steel", Vector3(0, 0.062, 0.058), Vector3(0.012, 0.03, 0.025), Vector3(-0.3, 0, 0))
		_box(body, "steel", Vector3(0, 0.072, -0.009), Vector3(0.035, 0.012, 0.066))
		for x in [-0.013, 0.013]:
			_box(body, "edge", Vector3(x, 0.084, 0.015), Vector3(0.014, 0.013, 0.012))
		_box(body, "edge", Vector3(0, 0.069, -0.359), Vector3(0.006, 0.036, 0.018))
		_clip_geometry(clip_parts, 10, 0.008, 0.033)
	_bake(root, body)
	_bake(mechanism, bolt_parts)
	_bake(clip, clip_parts)
	clip.visible = false
	var left := _hand(false, index)
	var right := _hand(true, index)
	root.add_child(left)
	root.add_child(right)
	return {"root": root, "bolt": mechanism, "clip": clip, "left": left, "right": right, "muzzle": Vector3(0, 0.044, -0.729 if index == 0 else -0.393)}

static func _hand(right: bool, index: int) -> Node3D:
	return FPHands.create(right,index,materials.cloth,materials.cuff)

static func _supplied_rifle() -> Dictionary:
	var root := Node3D.new()
	root.name = "Kar98k"
	var bolt := Node3D.new()
	bolt.name = "Bolt"
	root.add_child(bolt)
	var clip := Node3D.new()
	clip.name = "StripperClip"
	root.add_child(clip)
	var source := (load("res://assets/user_expansion_20261015/kar98k.glb") as PackedScene).instantiate()
	_copy_supplied_parts(source, Transform3D.IDENTITY, root, bolt, clip)
	source.free()
	clip.visible = false
	var left := _hand(false, 0)
	var right := _hand(true, 0)
	root.add_child(left)
	root.add_child(right)
	return {"root": root, "bolt": bolt, "clip": clip, "left": left, "right": right, "muzzle": Vector3(0, 0.044, -0.729), "bolt_contact": Vector3(.025, .059, .085)}

static func _copy_supplied_parts(node: Node3D, inherited: Transform3D, root: Node3D, bolt: Node3D, clip: Node3D) -> void:
	var placement := inherited * node.transform
	if node is MeshInstance3D:
		var part := node.duplicate() as MeshInstance3D
		part.transform = placement
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var parent := bolt if str(node.name).begins_with("Bolt_") else clip if str(node.name).begins_with("Clip_") else root
		parent.add_child(part)
	for child in node.get_children():
		if child is Node3D: _copy_supplied_parts(child, placement, root, bolt, clip)

static func _clip_geometry(parts: Dictionary, count: int, spacing: float, length: float) -> void:
	_box(parts, "steel", Vector3(0, 0.04, 0), Vector3(count * spacing + 0.007, 0.007, 0.015))
	for n in count:
		var x := (n - (count - 1) * 0.5) * spacing
		_rod(parts, "brass", Vector3(x, 0.04, 0), Vector3(x, 0.04 - length, 0), spacing * 0.38, 8)
		_rod(parts, "copper", Vector3(x, 0.04 - length, 0), Vector3(x, 0.028 - length, 0), spacing * 0.35, 8, 0.0)

static func _ensure_materials() -> void:
	if not materials.is_empty():
		return
	for entry in [["wood", "755039", 0.0, 0.73], ["wood_dark", "483020", 0.0, 0.83], ["steel", "414d53", 0.73, 0.38], ["edge", "758085", 0.82, 0.32], ["black", "11191b", 0.30, 0.78], ["cloth", "7c8083", 0.0, 0.94], ["cuff", "505559", 0.0, 0.98], ["skin", "b9977c", 0.0, 0.80], ["brass", "bda166", 0.70, 0.32], ["copper", "b17955", 0.66, 0.35]]:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(entry[1])
		mat.metallic = entry[2]
		mat.roughness = entry[3]
		materials[entry[0]] = mat
	var wood_image := Image.create(128, 128, false, Image.FORMAT_RGB8)
	var steel_image := Image.create(64, 64, false, Image.FORMAT_RGB8)
	var cloth_image := Image.create(64, 64, false, Image.FORMAT_RGB8)
	var grain := FastNoiseLite.new()
	grain.seed = 1938
	grain.frequency = 0.055
	for y in 128:
		for x in 128:
			var wave := sin(x * 0.85 + grain.get_noise_2d(x * 0.42, y * 0.075) * 7.0)
			var value := 0.83 + wave * 0.075 + grain.get_noise_2d(x * 1.9, y * 0.14) * 0.15
			wood_image.set_pixel(x, y, Color(value, value, value))
	for y in 64:
		for x in 64:
			var value := 0.90 + grain.get_noise_2d(x * 3, y * 3) * 0.06
			steel_image.set_pixel(x, y, Color(value, value, value))
			var weave := 0.84 + (0.11 if (x + y) % 3 == 0 else 0.0) + grain.get_noise_2d(x * 5, y * 5) * 0.08
			cloth_image.set_pixel(x, y, Color(weave, weave, weave))
	wood_image.generate_mipmaps()
	steel_image.generate_mipmaps()
	cloth_image.generate_mipmaps()
	materials.wood.albedo_texture = ImageTexture.create_from_image(wood_image)
	materials.steel.albedo_texture = ImageTexture.create_from_image(steel_image)
	materials.cloth.albedo_texture = ImageTexture.create_from_image(cloth_image)
	materials.cloth.uv1_scale = Vector3(3, 3, 3)
	materials.cuff.albedo_texture = materials.cloth.albedo_texture
	materials.cuff.uv1_scale = Vector3(3, 1, 1)

static func _append(parts: Dictionary, kind: String, mesh: Mesh, transform: Transform3D) -> void:
	if not parts.has(kind):
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		parts[kind] = surface
	parts[kind].append_from(mesh, 0, transform)

static func _bake(parent: Node3D, parts: Dictionary) -> void:
	for kind in parts:
		var node := MeshInstance3D.new()
		node.name = "Baked_" + kind
		node.mesh = parts[kind].commit()
		node.material_override = materials[kind]
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(node)

static func _box(parts: Dictionary, kind: String, at: Vector3, size: Vector3, rotation := Vector3.ZERO) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	_append(parts, kind, mesh, Transform3D(Basis.from_euler(rotation), at))

static func _ellipsoid(parts: Dictionary, kind: String, at: Vector3, radii: Vector3, rotation := Vector3.ZERO) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	_append(parts, kind, mesh, Transform3D(Basis.from_euler(rotation).scaled(radii), at))

static func _rod(parts: Dictionary, kind: String, a: Vector3, b: Vector3, radius: float, segments := 12, end_radius := -1.0) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius if end_radius < 0 else end_radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = segments
	var direction := (b - a).normalized()
	var tangent := Vector3.RIGHT if absf(direction.dot(Vector3.RIGHT)) < 0.95 else Vector3.FORWARD
	var z := tangent.cross(direction).normalized()
	var x := direction.cross(z).normalized()
	_append(parts, kind, mesh, Transform3D(Basis(x, direction, z), (a + b) * 0.5))

static func _loop(parts: Dictionary, kind: String, center: Vector3, radii: Vector2, radius: float) -> void:
	for n in 16:
		var a := TAU * n / 16.0
		var b := TAU * (n + 1) / 16.0
		_rod(parts, kind, center + Vector3(0, sin(a) * radii.x, cos(a) * radii.y), center + Vector3(0, sin(b) * radii.x, cos(b) * radii.y), radius, 6)

static func _loft(parts: Dictionary, kind: String, sections: Array) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for section: Vector4 in sections:
		var ring := PackedVector3Array()
		for n in 8:
			var angle := TAU * n / 8.0 + PI / 8.0
			ring.append(Vector3(cos(angle) * section.z, section.y + sin(angle) * section.w, section.x))
		rings.append(ring)
	for segment in rings.size() - 1:
		for n in 8:
			var k := (n + 1) % 8
			_triangle(surface, rings[segment][n], rings[segment + 1][n], rings[segment + 1][k])
			_triangle(surface, rings[segment][n], rings[segment + 1][k], rings[segment][k])
	for n in range(1, 7):
		_triangle(surface, rings[0][0], rings[0][n], rings[0][n + 1])
		_triangle(surface, rings[-1][0], rings[-1][n + 1], rings[-1][n])
	surface.generate_normals()
	_append(parts, kind, surface.commit(), Transform3D.IDENTITY)

static func _triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	for point in [a, b, c]:
		surface.set_uv(Vector2(point.x * 5.0 + point.y * 2.0, point.z * 2.0))
		surface.add_vertex(point)

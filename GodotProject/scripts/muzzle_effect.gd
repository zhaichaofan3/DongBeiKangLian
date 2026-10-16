extends Node3D
## S26: bounded, depth-tested flash, detached smoke and shadow-free short light.

const FLASH_SECONDS := 0.065
const SMOKE_SECONDS := 0.38
const TOTAL_SECONDS := 0.46
static var smoke_texture: ImageTexture
static var flare_texture: ImageTexture
var flash: MeshInstance3D
var smoke: CPUParticles3D
var light: OmniLight3D
var age := 0.0
var anchor: Node3D
var anchor_offset := Vector3(0, 0.025, -0.59)

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	flash = make_flash(1.25)
	add_child(flash)
	smoke = make_smoke(7, 0.24)
	add_child(smoke)
	light = OmniLight3D.new()
	light.light_color = Color("ffcd75")
	light.omni_range = 4.2
	light.shadow_enabled = false
	light.light_energy = 0.0
	add_child(light)

func trigger(origin: Vector3, target: Vector3, gun: Node3D = null) -> void:
	anchor = gun
	global_position = origin
	if origin.distance_squared_to(target) > 0.0001:
		look_at(target, Vector3.UP if absf((target-origin).normalized().y) < 0.98 else Vector3.RIGHT)
	flash.rotation.z = randf() * TAU
	flash.visible = true
	light.light_energy = 2.8
	smoke.visible = true
	smoke.restart()
	smoke.emitting = true
	age = 0.0

func _process(delta: float) -> void:
	age += delta
	if is_instance_valid(anchor): global_position = anchor.to_global(anchor_offset)
	var ratio := clampf(1.0 - age / FLASH_SECONDS, 0.0, 1.0)
	flash.visible = ratio > 0.0
	flash.scale = Vector3.ONE * (0.7 + ratio * 0.55)
	light.light_energy = 2.8 * ratio
	if age >= TOTAL_SECONDS: queue_free()

static func make_flash(size: float = 1.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = "MuzzleFlash"
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for angle in [0.0, PI * 0.5, PI * 0.25]:
		var axis := Vector3(cos(angle), sin(angle), 0)
		for side in [-1.0, 1.0]:
			surface.set_color(Color(1, 0.98, 0.77, 0.95))
			surface.add_vertex(Vector3.ZERO)
			surface.set_color(Color(1, 0.57, 0.13, 0.65))
			surface.add_vertex((axis * 0.033 * side + Vector3(0, 0, -0.055)) * size)
			surface.set_color(Color(1, 0.25, 0.03, 0))
			surface.add_vertex(Vector3(0, 0, -0.22) * size)
	surface.generate_normals()
	node.mesh = surface.commit()
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# A small soft star remains visible when looking directly down a remote barrel.
	if flare_texture == null: flare_texture = _texture(true)
	var face := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 0.115 * size
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.cull_mode = BaseMaterial3D.CULL_DISABLED
	glow.albedo_texture = flare_texture
	quad.material = glow
	face.mesh = quad
	face.position.z = -0.035
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(face)
	node.visible = false
	return node

static func make_smoke(count: int, width: float) -> CPUParticles3D:
	if smoke_texture == null: smoke_texture = _texture(false)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.vertex_color_use_as_albedo = true
	material.albedo_texture = smoke_texture
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * width
	quad.material = material
	var particles := CPUParticles3D.new()
	particles.name = "MuzzleSmoke"
	particles.emitting = false
	particles.visible = false
	particles.amount = count
	particles.lifetime = SMOKE_SECONDS
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.local_coords = false
	particles.mesh = quad
	particles.direction = Vector3(0, 0.18, -1)
	particles.spread = 22.0
	particles.initial_velocity_min = 0.35
	particles.initial_velocity_max = 0.75
	particles.gravity = Vector3(0.08, 0.22, 0)
	particles.scale_amount_min = 0.55
	particles.scale_amount_max = 1.1
	var growth := Curve.new()
	growth.add_point(Vector2(0, 0.35))
	growth.add_point(Vector2(1, 1.0))
	particles.scale_amount_curve = growth
	var fade := Gradient.new()
	fade.set_color(0, Color(0.62, 0.64, 0.61, 0.36))
	fade.set_color(1, Color(0.62, 0.64, 0.61, 0))
	particles.color_ramp = fade
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles

static func _texture(flame: bool) -> ImageTexture:
	var bitmap := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var uv := Vector2(x - 31.5, y - 31.5) / 31.5
			var radius := uv.length()
			var alpha := pow(maxf(0, 1.0 - radius), 1.7)
			if flame:
				alpha *= 0.7 + 0.3 * cos(atan2(uv.y, uv.x) * 6)
				bitmap.set_pixel(x, y, Color(1, lerpf(0.4, 1, alpha), 0.25 + alpha * 0.65, alpha))
			else:
				alpha *= 0.8 + 0.2 * sin(uv.x * 13 + sin(uv.y * 11))
				bitmap.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(bitmap)

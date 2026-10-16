extends Node3D
## Deterministic visual-only artillery. sample() is seekable and has no damage side effects.
const MuzzleEffect = preload("res://scripts/muzzle_effect.gd")
const DURATION := 4.2
const LEAD_SECONDS := 0.8
var dust: Array[MeshInstance3D] = []
var stones: Array[MeshInstance3D] = []
var flash: MeshInstance3D
var projectile: MeshInstance3D
var light: OmniLight3D
var sound: AudioStreamPlayer3D
var age := -10.0
var strength := 1.0

func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if MuzzleEffect.smoke_texture == null: MuzzleEffect.smoke_texture = MuzzleEffect._texture(false)
	for i in 12:
		var puff := MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2.ONE * (2.2 if i < 7 else 3.0)
		puff.mesh = quad
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.albedo_texture = MuzzleEffect.smoke_texture
		puff.material_override = mat
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(puff)
		dust.append(puff)
	var stone_material := StandardMaterial3D.new()
	stone_material.albedo_color = Color("514a39")
	for i in 10:
		var stone := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.09,0.07,0.13) * (0.6 + (i%3)*0.3)
		stone.mesh = mesh
		stone.material_override = stone_material
		stone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(stone)
		stones.append(stone)
	flash = MeshInstance3D.new()
	var fire := QuadMesh.new()
	fire.size = Vector2(2.3,2.7)
	flash.mesh = fire
	var fire_mat := StandardMaterial3D.new()
	fire_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fire_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fire_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fire_mat.albedo_texture = MuzzleEffect.smoke_texture
	flash.material_override = fire_mat
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flash)
	projectile = MeshInstance3D.new()
	var shell := SphereMesh.new()
	shell.radius = 0.04
	shell.height = 0.08
	shell.radial_segments = 8
	shell.rings = 4
	projectile.mesh = shell
	var shell_mat := StandardMaterial3D.new()
	shell_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shell_mat.albedo_color = Color("edb872")
	projectile.material_override = shell_mat
	projectile.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(projectile)
	light = OmniLight3D.new()
	light.omni_range = 9.0
	light.light_color = Color("ffb05b")
	light.shadow_enabled = false
	light.position.y = 1.0
	add_child(light)
	sound = AudioStreamPlayer3D.new()
	sound.bus = &"Weapons"
	sound.stream = load("res://scripts/audio_factory.gd").make_sound("explosion")
	sound.max_distance = 90
	sound.unit_size = 10
	sound.volume_db = -14
	add_child(sound)
	sample(-10)

func sample(seconds: float) -> void:
	age = seconds
	visible = seconds >= -LEAD_SECONDS and seconds < DURATION
	if not visible:
		light.light_energy = 0
		return
	projectile.visible = seconds < 0
	if projectile.visible:
		var t := clampf(1.0 + seconds / LEAD_SECONDS,0,1)
		projectile.position = Vector3(12,20,-18) * (1.0-t)
		projectile.basis = Basis.looking_at(Vector3(-12,-20,18)).scaled(Vector3(1,1,14))
	flash.visible = seconds >= 0 and seconds < 0.22
	flash.position.y = 0.7
	flash.scale = Vector3.ONE * strength * (0.35 + maxf(0, seconds) * 6)
	flash.material_override.albedo_color = Color(1,0.65,0.22,clampf(1.0-seconds/0.22,0,1))
	light.light_energy = 5.0 * strength * clampf(1.0-seconds/0.18,0,1) if seconds >= 0 else 0.0
	for i in dust.size():
		var puff := dust[i]
		var delay := 0.02 + i * 0.012
		var t := maxf(0, seconds-delay)
		puff.visible = seconds >= delay
		var angle := float(i) * 2.39996
		var ring := i < 7
		var spread := (1-exp(-t*3)) * (2.1 if ring else 1.0) * strength
		puff.position = Vector3(cos(angle)*spread + t*0.14, (0.22+t*0.16 if ring else 0.6+t*(1.1+(i%3)*0.19)) * strength, sin(angle)*spread)
		puff.scale = Vector3.ONE * (0.22 + t*(0.65 if ring else 0.42)) * strength
		var alpha := smoothstep(0,0.12,t) * (1-smoothstep(1.2 if ring else 2.0,DURATION,t))
		puff.material_override.albedo_color = Color(0.38,0.31,0.23,alpha*0.72) if ring else Color(0.23,0.25,0.24,alpha*0.78)
	for i in stones.size():
		var stone := stones[i]
		stone.visible = seconds >= 0 and seconds < 1.8
		var t := maxf(0, seconds)
		var angle := i * 2.39996
		var speed := 1.0 + (i%4)*0.6
		stone.position = Vector3(cos(angle)*t*speed,maxf(0.03,0.18+(3.4+(i%3))*t-4.9*t*t),sin(angle)*t*speed)*strength
		stone.rotation = Vector3(t*5+i,t*3,t*4)

func play_impact() -> void:
	sound.play()

func cancel() -> void:
	sample(-10)
	sound.stream_paused = false
	sound.stop()

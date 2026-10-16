extends Node3D
## Integrated opening; current acceptance is recorded in PROGRESS.md.

const Explosion = preload("res://scripts/explosion_effect.gd")
const MuzzleEffect = preload("res://scripts/muzzle_effect.gd")
const BARRAGE := [{"time":33.4,"at":Vector3(44,0.08,130),"scale":0.8},{"time":35.9,"at":Vector3(42,0.08,133),"scale":0.9},{"time":38.0,"at":Vector3(38.8,0.08,127.8),"scale":1.0},{"time":38.5,"at":Vector3(35,0.08,125),"scale":2.2}]
const HISTORY_AUDIO = preload("res://assets/audio/opening_history_20261015.mp3")
const Human = preload("res://scripts/human_model.gd")
const Weapons = preload("res://scripts/weapon_visuals.gd")
const AudioFactory = preload("res://scripts/audio_factory.gd")
const TIANCHI_WATER_SHADER = preload("res://shaders/tianchi_water.gdshader")
const TIANCHI_MIST_SHADER = preload("res://shaders/tianchi_mist.gdshader")
const OPENING_SNOW_SHADER = preload("res://shaders/opening_snow.gdshader")
const TianchiLandscape = preload("res://scripts/tianchi_landscape.gd")
const DATA_PATH := "res://assets/opening/opening.json"
const ARTISTIC_TIANCHI_PATH := "res://assets/opening/tianchi_artistic.glb"

var main: Node3D
var data: Dictionary
var part := "A"
var clock := 0.0
var active := false
var paused := false
var shot: Dictionary = {}
var shot_id := ""
var seen_shots: Array[String] = []
var seen_cues: Array[String] = []
var current_cue := ""
var camera: Camera3D
var lake_environment: Environment
var tianchi_environment_root: Node3D
var tianchi_water: MeshInstance3D
var tianchi_mist: Node3D
var tianchi_backdrop: Node3D
var tianchi_fill: DirectionalLight3D
var tianchi_rim_light: OmniLight3D
var tianchi_water_material: ShaderMaterial
var tianchi_water_original: Material
var tianchi_mist_material: ShaderMaterial
var tianchi_landscape: Node3D
var actors: Dictionary = {}
var stage_root: Node3D
var snow: MeshInstance3D
var snow_material: ShaderMaterial
var lake: Node3D
var terrace: Node3D
var arrival_route: Array[Vector3] = []
var departure_route: Array[Vector3] = []
var tianchi_origin := Vector3(560, 12, 121.5)
var effects: Node3D
var flashes: Array[MeshInstance3D] = []
var blasts: Array[Node3D] = []
var distant_flashes: Array[MeshInstance3D] = []
var hands: Node3D
var office_showcase_lights: Node3D
var hand_rig: Dictionary
var ui: CanvasLayer
var caption: Label
var title: Label
var badge: Label
var controls: HBoxContainer
var fade: ColorRect
var shot_audio: AudioStreamPlayer
var step_audio: AudioStreamPlayer
var metal_audio: AudioStreamPlayer
var hidden_nodes: Array[Node3D] = []
var fired_sounds: Dictionary = {}
var voice_streams: Dictionary = {}
var handoff_count := 0
var handoff_state := "idle"
var handoff_elapsed := 0.0
const HANDOFF_TRANSITION_SECONDS := 0.20
var last_skip_ms := -1000
var s24_active_cue := ""
var s24_peer_visible := false

func initialize(owner_node: Node3D) -> void:
	main = owner_node
	data = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	_load_dialogue_voice()
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_build_stage()
	_build_ui()
	visible = false
	ui.visible = false

func _build_stage() -> void:
	stage_root = Node3D.new()
	add_child(stage_root)
	camera = Camera3D.new()
	camera.near = 0.04
	camera.far = 1300
	lake_environment = main.world.environment.duplicate()
	lake_environment.background_mode = Environment.BG_SKY
	lake_environment.ambient_light_color = Color("9dbbc5")
	lake_environment.ambient_light_energy = 0.52
	lake_environment.fog_enabled = true
	lake_environment.fog_light_color = Color("91b4bd")
	lake_environment.fog_density = 0.0011
	lake_environment.fog_sun_scatter = 0.18
	lake_environment.fog_height = 3.0
	lake_environment.fog_height_density = 0.025
	lake_environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	camera.environment = main.world.environment
	add_child(camera)
	hands = Node3D.new()
	camera.add_child(hands)
	hands.position = Weapons.HIP_POSITIONS[0]
	hands.rotation = Weapons.HIP_ROTATION
	hand_rig = Weapons.build(0)
	hands.add_child(hand_rig.root)
	hand_rig.clip.visible = false
	hand_rig.left.pose("grip", 1.0, 1.0)
	hand_rig.right.pose("grip", 1.0, 1.0)
	hand_rig.left.update_sleeve()
	hand_rig.right.update_sleeve()
	_set_visual_layer(hands, 4)
	office_showcase_lights = Node3D.new()
	office_showcase_lights.name = "OfficeShowcaseLighting"
	stage_root.add_child(office_showcase_lights)
	for index in 2:
		var light := SpotLight3D.new()
		light.position = Vector3(50, 3.7, 36) if index == 0 else Vector3(60, 3.6, 39)
		light.look_at_from_position(light.position, Vector3(54, 0.7, 34) if index == 0 else Vector3(52, 1, 38))
		light.light_color = Color("ffd49d") if index == 0 else Color("b4cedc")
		light.light_energy = 1.4 if index == 0 else 0.8
		light.light_cull_mask = 1
		light.spot_range = 14
		light.spot_angle = 46
		light.shadow_enabled = true
		office_showcase_lights.add_child(light)
	office_showcase_lights.visible = false
	for id in ["ally1", "ally2", "enemy1", "enemy2", "scout", "worker"]:
		var model := Human.new()
		stage_root.add_child(model)
		model.build("logger" if id == "worker" else "scout" if id == "scout" else "guard", "ally" if id.begins_with("ally") else "")
		actors[id] = model
		model.visible = false
	lake = (load(ARTISTIC_TIANCHI_PATH) as PackedScene).instantiate()
	lake.name = "S21_Artistic_Tianchi"
	lake.position = tianchi_origin
	stage_root.add_child(lake)
	_set_visual_layer(lake, 2)
	_build_tianchi_environment()
	var lake_sun := DirectionalLight3D.new()
	lake_sun.layers = 2
	lake_sun.light_cull_mask = 6
	lake_sun.rotation = main.world.sunlight.rotation
	lake_sun.light_color = main.world.sunlight.light_color
	lake_sun.light_energy = main.world.sunlight.light_energy
	tianchi_environment_root.add_child(lake_sun)
	# The forest sun must not also illuminate the isolated lake layer.
	main.world.sunlight.light_cull_mask = main.world.sunlight.light_cull_mask & ~2
	terrace = Node3D.new()
	stage_root.add_child(terrace)
	_build_tianchi_access()
	_set_visual_layer(terrace, 2)
	tianchi_landscape = TianchiLandscape.new()
	tianchi_environment_root.add_child(tianchi_landscape)
	tianchi_landscape.build(lake, terrace, [arrival_route, departure_route])
	# A07 uses the same authored path as the actors. The top is at y=.08,
	# matching their foot anchors so the shot no longer floats over a flat tint.
	snow = _box(stage_root, Vector3(11.5,0.05,280), Vector3(8,0.06,17), Color("b9cbd3"))
	snow_material = ShaderMaterial.new()
	snow_material.shader = OPENING_SNOW_SHADER
	snow.material_override = snow_material
	snow.set_meta("surface", "procedural_snow_grain")
	snow.visible = false
	effects = Node3D.new()
	stage_root.add_child(effects)
	for i in 4:
		var flash := MuzzleEffect.make_flash()
		effects.add_child(flash)
		flashes.append(flash)
	for event in BARRAGE:
		var blast := Explosion.new()
		effects.add_child(blast)
		blast.position = event.at
		blast.strength = event.scale
		blasts.append(blast)
	for i in 4:
		var flash := MuzzleEffect.make_flash(2.0)
		flash.position = Vector3(29+i*3,1.5,124)
		effects.add_child(flash)
		distant_flashes.append(flash)
	shot_audio = _audio(AudioFactory.make_sound("rifle"), -22)
	step_audio = _audio(AudioFactory.make_sound("step"), -28)
	metal_audio = _audio(AudioFactory.make_sound("reload"), -25)
	shot_audio.bus = &"Weapons"
	step_audio.bus = &"Foley"
	metal_audio.bus = &"Foley"

func _build_tianchi_environment() -> void:
	# S23 owns the visible environment treatment. Everything is parented under
	# one switch so non-lake shots and the playable forest never pay for it.
	tianchi_environment_root = Node3D.new()
	tianchi_environment_root.name = "S23_Tianchi_Environment"
	stage_root.add_child(tianchi_environment_root)
	_build_tianchi_water()
	_build_tianchi_mist()
	_build_tianchi_backdrop()
	tianchi_fill = DirectionalLight3D.new()
	tianchi_fill.name = "S23_Tianchi_Fill"
	tianchi_fill.layers = 2
	tianchi_fill.light_cull_mask = 2
	tianchi_fill.rotation_degrees = Vector3(-38, 32, 0)
	tianchi_fill.light_color = Color("c2dbe0")
	tianchi_fill.light_energy = 0.34
	tianchi_fill.shadow_enabled = false
	tianchi_environment_root.add_child(tianchi_fill)
	tianchi_rim_light = OmniLight3D.new()
	tianchi_rim_light.name = "S23_Tianchi_Rim"
	tianchi_rim_light.light_cull_mask = 2
	tianchi_rim_light.position = Vector3(501, 29, 145.5)
	tianchi_rim_light.light_color = Color("9fc9d0")
	tianchi_rim_light.light_energy = 0.42
	tianchi_rim_light.omni_range = 54.0
	tianchi_rim_light.shadow_enabled = false
	tianchi_environment_root.add_child(tianchi_rim_light)
	_set_visual_layer(tianchi_environment_root, 2)

func _build_tianchi_water() -> void:
	# Reuse the imported disk; overlapping opaque surfaces flicker at distance.
	tianchi_water = lake.find_child("S21_Deep_Blue_Lake", true, false) as MeshInstance3D
	assert(tianchi_water != null, "S21 lake surface is required")
	tianchi_water_original = tianchi_water.get_active_material(0)
	tianchi_water_material = ShaderMaterial.new()
	tianchi_water_material.shader = TIANCHI_WATER_SHADER
	tianchi_water.material_override = tianchi_water_material
	tianchi_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _build_tianchi_mist() -> void:
	tianchi_mist = Node3D.new()
	tianchi_mist.name = "S23_Tianchi_Mist_Bands"
	tianchi_environment_root.add_child(tianchi_mist)
	tianchi_mist_material = ShaderMaterial.new()
	tianchi_mist_material.shader = TIANCHI_MIST_SHADER
	tianchi_mist_material.set_shader_parameter("mist_color", Color("a9c5c5"))
	tianchi_mist_material.set_shader_parameter("opacity", 0.13)
	for i in 3:
		var band := MeshInstance3D.new()
		band.name = "S23_Mist_%02d" % i
		var quad := QuadMesh.new()
		quad.size = Vector2(150.0 + i * 34.0, 17.0 + i * 2.5)
		band.mesh = quad
		band.material_override = tianchi_mist_material
		band.position = Vector3(564.0 + (i - 1) * 22.0, 13.5 + i * 4.8, 111.0 - i * 22.0)
		band.rotation_degrees = Vector3(-90, 0, 0)
		band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		band.set_meta("s23_mist_band", i)
		tianchi_mist.add_child(band)

func _build_tianchi_backdrop() -> void:
	tianchi_backdrop = Node3D.new()
	tianchi_backdrop.name = "S23_Tianchi_Distant_Mountains"
	tianchi_environment_root.add_child(tianchi_backdrop)
	var layers := [
		{"name":"S23_Ridge_Near", "radius":205.0, "height":20.0, "color":Color("40585b"), "alpha":1.0},
		{"name":"S23_Ridge_Mid", "radius":260.0, "height":30.0, "color":Color("5b7477"), "alpha":1.0},
		{"name":"S23_Ridge_Far", "radius":325.0, "height":42.0, "color":Color("748b8e"), "alpha":0.96}
	]
	for layer in layers:
		var ridge := _make_tianchi_ridge(layer.name, float(layer.radius), float(layer.height), layer.color)
		tianchi_backdrop.add_child(ridge)

func _make_tianchi_ridge(node_name: String, radius: float, height: float, color: Color) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector2(564.0, 119.5)
	var segments := 128
	for ring in 2:
		for i in segments:
			var corners: Array[Vector3] = []
			for item: Vector2i in [Vector2i(ring, i), Vector2i(ring + 1, i), Vector2i(ring + 1, i + 1), Vector2i(ring, i + 1)]:
				var angle := TAU * float(item.y) / segments
				var distance := radius + (item.x - 1) * 65.0
				var crest := height + sin(angle * 3.0 + radius * 0.02) * 9.0 + sin(angle * 7.0 - radius * 0.03) * 4.0 + sin(angle * 13.0) * 1.8
				corners.append(Vector3(center.x + cos(angle) * distance, crest if item.x == 1 else -8.0, center.y + sin(angle) * distance))
			for index in [0, 2, 1, 0, 3, 2]:
				var point := corners[index]
				surface.set_color(color.lightened(0.025 * sin(point.x * 0.07 + point.z * 0.06)))
				surface.add_vertex(point)
	surface.generate_normals()
	var ridge := MeshInstance3D.new()
	ridge.name = node_name
	ridge.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.roughness = 1.0
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	ridge.material_override = material
	ridge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ridge.set_meta("s23_backdrop_radius", radius)
	ridge.set_meta("s23_backdrop_height", height)
	return ridge

func _audio(stream: AudioStream, volume: float) -> AudioStreamPlayer:
	var node := AudioStreamPlayer.new()
	node.stream = stream
	node.volume_db = volume
	add_child(node)
	return node

func _load_dialogue_voice() -> void:
	# Only explicitly supplied takes may play. Missing recordings stay silent.
	voice_streams.clear()
	for cue in data.cues.B:
		if cue.get("voice_status") != "user_supplied_recording": continue
		var stream := load(str(cue.audio_source)) as AudioStream
		if stream != null:
			voice_streams[cue.id] = stream

func _set_visual_layer(node: Node, layer: int) -> void:
	if node is VisualInstance3D: node.layers = layer
	for child in node.get_children(): _set_visual_layer(child, layer)

func _box(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _mesh(parent, mesh, at, color)

func _sphere(parent: Node3D, at: Vector3, color: Color, emissive: bool = false) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 12
	mesh.rings = 6
	var node := _mesh(parent, mesh, at, color)
	if emissive:
		var mat := node.material_override as StandardMaterial3D
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return node

func _mesh(parent: Node3D, mesh: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	node.material_override = material
	parent.add_child(node)
	node.position = at
	return node

func _build_tianchi_access() -> void:
	# S22 owns the gameplay surface around the S21 visual asset. Coordinates are
	# in the opening stage, with the platform top aligned to the B1--B3 actors.
	arrival_route = [
		Vector3(484, 18.0, 199.5), Vector3(487, 20.0, 184.0),
		Vector3(492, 22.0, 169.0), Vector3(497, 24.0, 156.0),
		Vector3(501, 26.0, 145.5)]
	departure_route = [
		Vector3(501, 26.0, 145.5), Vector3(496.5, 26.0, 140.5),
		Vector3(497, 24.7, 135), Vector3(490, 18.5, 87.5),
		Vector3(512, 16.0, 63.5)]
	for index in arrival_route.size():
		_access_step("S22_arrival_%02d" % index, arrival_route[index], "arrival")
	for index in departure_route.size():
		if index in [1, 2]:
			_access_box("S22_departure_%02d" % index, departure_route[index] - Vector3.UP * .08, Vector3(2.2, .16, .3), "path")
		else:
			_access_step("S22_departure_%02d" % index, departure_route[index], "departure")
	# A single level surface gives both speakers a stable root and leaves a
	# narrow perimeter for the later S24 gestures and S25 camera blocking.
	_access_box("S22_talk_platform_floor", Vector3(501, 25.75, 145.5), Vector3(14, .5, 10), "platform")
	# The visible departure insert crosses a continuous ramp above the imported
	# slope. The former long two-second move went through the crater wall.
	var ramp_start: Vector3 = departure_route[1]
	var ramp_end: Vector3 = departure_route[2]
	var ramp := _access_box("S36_departure_ramp", (ramp_start + ramp_end) * .5, Vector3(2.2, .16, ramp_start.distance_to(ramp_end)), "path")
	ramp.look_at(ramp_end, Vector3.UP)
	ramp.position -= ramp.transform.basis.y * .08
	# Low rocks and reed-like marker clumps reserve the near edge without making
	# a collision wall. S23 can replace these markers with fog and final foliage.
	for item in [
		Vector3(492, 26.5, 139.5), Vector3(510, 26.1, 139.0),
		Vector3(514, 24.3, 151.0), Vector3(488, 24.7, 151.5)]:
		var rock := _sphere(terrace, item, Color("5e6866"))
		rock.scale = Vector3(1.6, .75, 1.15)
	for item in [Vector3(493,26.3,138.3), Vector3(511,26.1,138.1), Vector3(515,24.0,152.3)]:
		var reed := _box(terrace, item, Vector3(.22, 1.8, .22), Color("697658"))
		reed.rotation.z = -.16

func _access_step(node_name: String, at: Vector3, route_kind: String) -> void:
	_access_box(node_name, at - Vector3(0, .28, 0), Vector3(5.2, .56, 5.0), "path")
	var marker := _box(terrace, at - Vector3(0, .27, 0), Vector3(4.9, .12, 4.7), Color("4f5550"))
	marker.set_meta("s22_route", route_kind)

func _access_box(node_name: String, at: Vector3, size: Vector3, visual_kind: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = at
	body.set_meta("s22_access", true)
	if node_name.begins_with("S22_arrival"):
		body.set_meta("s22_route", "arrival")
	elif node_name.begins_with("S22_departure"):
		body.set_meta("s22_route", "departure")
	terrace.add_child(body)
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = _access_material(Color("5f655d") if visual_kind == "path" else Color("6b6254"))
	body.add_child(visual)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	return body

func _access_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = .92
	return mat

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 5
	add_child(ui)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = main.hud.root.theme
	ui.add_child(root)
	for bottom in [false,true]:
		var bar := ColorRect.new()
		bar.color = Color(0.025,0.035,0.04,0.91)
		bar.anchor_right = 1.0
		bar.anchor_top = 0.80 if bottom else 0.0
		bar.anchor_bottom = 1.0 if bottom else 0.09
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(bar)
	badge = _label(root, 15, Vector4(.025,.018,.65,.075))
	badge.modulate = Color("c9d2cb")
	caption = _label(root, 24, Vector4(.09,.825,.91,.955))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title = _label(root, 32, Vector4(.12,.30,.88,.66))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fade = ColorRect.new()
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0,0,0,0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade)
	controls = HBoxContainer.new()
	controls.anchor_left = .68
	controls.anchor_right = .98
	controls.anchor_top = .014
	controls.anchor_bottom = .075
	controls.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(controls)
	for text in ["暂停  Esc", "跳过本段  Enter"]:
		var button := Button.new()
		button.text = text
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func(): set_paused(true) if text.begins_with("暂停") else skip(part))
		controls.add_child(button)

func _label(parent: Control, font_size: int, anchors: Vector4) -> Label:
	var label := Label.new()
	label.anchor_left = anchors.x
	label.anchor_top = anchors.y
	label.anchor_right = anchors.z
	label.anchor_bottom = anchors.w
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0,0,0,.95))
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func start(which: String = "A") -> void:
	main.audio_mix.reset_transients()
	active = true
	paused = false
	visible = true
	ui.visible = true
	hidden_nodes.clear()
	for node in main.guards + main.story.people.values():
		if node.visible:
			hidden_nodes.append(node)
			node.visible = false
	# World interaction and construction labels belong to gameplay, not the film.
	for label in main.find_children("*", "Label3D", true, false):
		if label.visible and not is_ancestor_of(label):
			hidden_nodes.append(label)
			label.visible = false
	main.player.model.visible = false
	main.player.sound.stop()
	main.player.footsteps.stop()
	main.enemy_audio.stop()
	seen_shots.clear()
	seen_cues.clear()
	handoff_count = 0
	handoff_state = "idle"
	handoff_elapsed = 0.0
	last_skip_ms = -1000
	_set_access_collisions(true)
	main.mode = "cinematic"
	_enter_part(which, false)
	camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _enter_part(which: String, save: bool = true) -> void:
	_stop_cue_audio()
	for blast in blasts: blast.cancel()
	part = which
	clock = 0
	shot_id = ""
	fired_sounds.clear()
	main.opening_phase = "history" if part == "A" else "task"
	if part == "A":
		# No crossfade here: the supplied recording already contains its own score.
		main.audio_mix.stop_music_immediate()
		main.audio_mix.play_voice(HISTORY_AUDIO, 0.0, true)
	else:
		main.audio_mix.start_global_music()
	if save and not main._save_checkpoint():
		set_paused(true)
		main.notify("开场进度暂未保存，可继续观看；退出后从上次成功检查点恢复。", 8)
	_update_view(0.016)

func _process(delta: float) -> void:
	if active and not paused:
		advance(delta)

func advance(delta: float) -> void:
	if not active or paused:
		return
	if handoff_state == "transition":
		handoff_elapsed += delta
		fade.color.a = smoothstep(0.0, 1.0, handoff_elapsed / HANDOFF_TRANSITION_SECONDS)
		if handoff_elapsed + 0.0001 >= HANDOFF_TRANSITION_SECONDS:
			finish()
		return
	clock += delta
	if clock * 1000.0 >= float(data.durations_ms[part]):
		if part == "A":
			_enter_part("B")
		else:
			_begin_handoff()
		return
	_update_view(delta)

func _update_view(delta: float) -> void:
	var ms := clock * 1000.0
	for candidate in data.shots:
		if candidate.part == part and ms >= candidate.start_ms and ms < candidate.end_ms:
			if shot_id != candidate.id:
				shot = candidate
				shot_id = candidate.id
				if shot_id not in seen_shots: seen_shots.append(shot_id)
				for model in actors.values():
					model.visible = false
					model._death_time = -1.0
					model.clock = float(shot.start_ms) * .001
				for id in ["ally1", "ally2"]:
					var rig = actors[id].detailed_rig
					if rig != null:
						rig.find_child("Hands",true,false).visible = shot_id == "A-10" or not rig.has_guard_hands
						if rig.has_guard_hands: rig.find_child("GuardHands",true,false).visible = shot_id != "A-10"
			break
	if shot.is_empty(): return
	var progress := clampf((ms - shot.start_ms) / float(shot.end_ms-shot.start_ms),0,1)
	var smooth := smoothstep(0.0,1.0,progress)
	var in_lake: bool = shot.segment in ["A5","B1","B2","B3"] or shot_id == "B-07"
	camera.cull_mask = (2 if in_lake else 1) | 4
	camera.environment = lake_environment if in_lake else main.world.environment
	if shot.get("environment") == "songling_village":
		camera.environment = main.world.village_world.environment
	camera.position = _v(shot.camera_from).lerp(_v(shot.camera_to),smooth)
	camera.look_at(_v(shot.look_at).lerp(_v(shot.get("look_at_to",shot.look_at)),smooth),Vector3.UP)
	if shot_id == "B-06":
		camera.look_at(_v(shot.look_at).lerp(departure_route[1] + Vector3.UP, smooth), Vector3.UP)
	if shot_id == "B-07":
		var departure_actor: Vector3 = departure_route[1].lerp(departure_route[2], progress)
		camera.position = _v(shot.camera_from).lerp(_v(shot.camera_to), progress)
		camera.look_at(departure_actor + Vector3.UP * .95, Vector3.UP)
	camera.fov = shot.fov
	if shot_id in ["A-07","B-08"]:
		var foot_block: Dictionary = shot.actors[0]
		camera.look_at(_v(foot_block.start).lerp(_v(foot_block.end),progress)+Vector3.UP*.22)
	if shot_id == "B-01" and clock < 2.0:
		camera.look_at(Vector3(500,27,132).lerp(_v(shot.look_at),smoothstep(0,2,clock)))
	if shot_id == "B-15": camera.fov = lerpf(70,74,smooth)
	if shot_id == "B-16":
		var align := smoothstep(74.9,78.5,clock)
		camera.quaternion = camera.quaternion.slerp(Quaternion.from_euler(Vector3(0,-0.6,0)),align)
		camera.fov = lerpf(74,78,align)
	for block in shot.actors:
		var model: Node3D = actors[block.id]
		var visual_layer := 4 if shot_id == "A-10" else 2 if in_lake else 1
		if model.get_meta("opening_layer",0) != visual_layer:
			_set_visual_layer(model,visual_layer)
			model.set_meta("opening_layer",visual_layer)
		model.visible = true
		model.position = _v(block.start).lerp(_v(block.end),progress)
		model.rotation.y = float(block.yaw)
		var speed := _v(block.start).distance_to(_v(block.end)) / (float(shot.end_ms-shot.start_ms)*.001)
		var conversation: bool = part == "B" and shot.segment in ["B1","B2","B3","B5","B6"]
		var talking := bool(not conversation and block.id == "scout" and _speaker_at(ms) == "scout")
		model.set_motion_context(false,0,shot.segment == "A4")
		var actor_role: String = model.role
		if shot_id == "A-10": model.role = "scout"
		model.animate(delta,speed,talking)
		model.role = actor_role
		if shot_id == "A-10":
			# Sling the rifle on the pack so a normal walking cycle can move both arms.
			model.rifle.position = Vector3(0.15, 0.04, 0.36)
			model.rifle.rotation = Vector3(1.4, 0, 0.18)
			model._sync_detailed_model()
		if shot_id == "A-13" and block.id == "enemy1":
			if model._death_time < 0: model.fall()
			model._death_time = maxf(0,clock-54.6)
			model.animate_death(0)
	_apply_conversation_performance(ms, delta, in_lake)
	hands.visible = part == "B" and shot.segment != "B4"
	hands.position = Weapons.SAFE_POSITION + Vector3(0,sin(clock*1.6)*.003,0)
	hands.rotation = Weapons.SAFE_ROTATION
	office_showcase_lights.visible = shot_id in ["A-09T","A-10"]
	lake.visible = in_lake
	if is_instance_valid(tianchi_environment_root):
		tianchi_environment_root.visible = in_lake
		tianchi_water_material.set_shader_parameter("environment_time", clock)
		tianchi_mist_material.set_shader_parameter("environment_time", clock)
	terrace.visible = lake.visible and shot_id not in ["A-16","A-17"]
	snow.visible = shot_id == "A-07"
	effects.visible = shot.segment == "A4"
	_update_effects(ms)
	_update_captions(ms)
	_update_sound(ms)
	fade.color.a = 1.0-smoothstep(0,1,clock) if part=="A" and clock<1 else 0
	badge.text = "历史序章" if part == "A" else "任务序幕"
	if "--qa" in OS.get_cmdline_user_args(): badge.text += " · " + shot_id

func _update_effects(ms: float) -> void:
	for flash in flashes: flash.visible = false
	if shot.segment != "A4":
		for blast in blasts: blast.cancel()
		return
	var index := 0
	for block in shot.actors:
		var model: Node3D = actors[block.id]
		if model.rifle == null or model._death_time >= 0: continue
		var flash: MeshInstance3D = flashes[index]
		var phase := fmod((ms-32740)*.001 + index*.29,1.25)
		flash.global_transform = model.rifle.global_transform
		flash.global_position = model.rifle.to_global(Vector3(0,.025,-.59))
		flash.visible = phase < .065
		if phase < .065: model.fire()
		index += 1
	for i in blasts.size():
		var age := ms*0.001 - float(BARRAGE[i].time)
		blasts[i].sample(age)
		if age >= 0 and age < 0.22:
			for block in shot.actors:
				var model: Node3D = actors[block.id]
				if model._death_time < 0 and model.position.distance_to(BARRAGE[i].at) < 7.0: model.flinch()
			var shake := (1.0-age/0.22)*0.025*float(main.presentation.motion_strength)
			camera.position += Vector3(sin(ms*.08),cos(ms*.07),0)*shake
	for i in distant_flashes.size():
		distant_flashes[i].visible = fmod(ms*0.001+i*.37,1.7) < .065

func _speaker_at(ms: float) -> String:
	if part != "B": return ""
	for cue in data.cues.B:
		if ms >= cue.start_ms and ms < cue.end_ms: return cue.speaker
	return ""

func _conversation_cue(ms: float) -> Dictionary:
	if part != "B": return {}
	for cue in data.cues.B:
		if ms >= float(cue.start_ms) and ms < float(cue.end_ms):
			return cue
	return {}

func _apply_conversation_performance(ms: float, delta: float, in_lake: bool) -> void:
	# S24 adds a visible peer only during the authored conversation windows.
	# It is a cinematic copy and never enters mission AI, damage or inventory.
	var peer: Node3D = actors.get("ally1")
	var scout: Node3D = actors.get("scout")
	var cue := _conversation_cue(ms)
	var active: bool = part == "B" and shot.segment in ["B1", "B2", "B3", "B5", "B6"]
	if not active or peer == null or scout == null:
		# ally1 is also an authored history actor. B-only cleanup must not hide it in A.
		if part == "B" and peer != null: peer.visible = false
		s24_peer_visible = false
		s24_active_cue = ""
		return
	var forest_stage: bool = shot.segment in ["B5", "B6"]
	var peer_position := Vector3(497.2, 26.0, 146.3) if in_lake else Vector3(9.4, 0.08, 282.35)
	var peer_yaw := 0.25 if in_lake else -0.55
	peer.visible = true
	peer.position = peer_position
	peer.rotation.y = peer_yaw
	_set_visual_layer(peer, 2 if in_lake else 1)
	peer.set_meta("opening_layer", 2 if in_lake else 1)
	peer.set_motion_context(false, 0, false)
	peer.animate(delta, 0.0, false)
	for actor in [scout, peer]:
		var other: Node3D = peer if actor == scout else scout
		var gaze: Vector3 = actor.to_local(other.position + Vector3.UP * 1.55)
		var gaze_yaw := clampf(atan2(-gaze.x, -gaze.z), -0.38, 0.38)
		actor.chest.rotation.y += gaze_yaw * 0.12
		actor.head.rotation.y = gaze_yaw * 0.80 + sin(clock * 0.55 + (0.8 if actor == peer else 0.0)) * 0.012
		for i in 2:
			var side := -1.0 if i == 0 else 1.0
			actor.arms[i].rotation = Vector3(0.025, 0, side * 0.115)
			actor.elbows[i].rotation = Vector3(0.14, 0, 0)
	if cue.is_empty():
		scout._sync_detailed_model()
		peer._sync_detailed_model()
		s24_peer_visible = true
		s24_active_cue = ""
		return
	var cue_id: String = cue.id
	var cue_progress := clampf((ms - float(cue.start_ms)) / maxf(1.0, float(cue.end_ms - cue.start_ms)), 0.0, 1.0)
	var speaking_scout: bool = cue.speaker == "scout"
	var speaker: Node3D = scout if speaking_scout else peer
	var listener: Node3D = peer if speaking_scout else scout
	# One restrained gesture per line, with a soft preparation and full release.
	var gesture := smoothstep(0.06, 0.30, cue_progress) * (1.0 - smoothstep(0.60, 0.94, cue_progress))
	var nod := sin(smoothstep(0.42, 0.78, cue_progress) * PI)
	listener.head.rotation.x += nod * 0.045
	speaker.head.rotation.x += sin(cue_progress * PI * 2.0) * 0.018
	speaker.chest.rotation.z += sin(cue_progress * PI) * (0.008 if forest_stage else 0.012)
	if cue_id == "B1-L01":
		speaker.head.rotation.x += gesture * 0.07
		_conversation_hand(speaker, 1, gesture, 0.16, 0.56)
	elif cue_id == "B2-L01":
		speaker.head.rotation.y -= gesture * 0.16
	elif cue_id == "B2-L02":
		_conversation_hand(speaker, 1, gesture, 0.13, 0.48)
	elif cue_id == "B2-L03":
		speaker.head.rotation.y -= gesture * 0.09
	elif cue_id == "B3-L01":
		speaker.head.rotation.y -= gesture * 0.12
		_conversation_hand(speaker, 0, gesture, 0.25, 0.65)
	elif cue_id == "B3-L02":
		speaker.head.rotation.x -= gesture * 0.035
	elif cue_id in ["B5-L01", "B5-L03", "B5-L04", "B5-L06", "B6-L01"]:
		_conversation_hand(speaker, 0, gesture, 0.18, 0.54)
		speaker.head.rotation.y -= gesture * (0.10 if cue_id != "B5-L04" else 0.16)
	elif cue_id in ["B5-L02", "B5-L05", "B6-L02"]:
		speaker.head.rotation.x -= gesture * 0.025
	# Keep the detailed imported rig synchronized after the authored offsets.
	if speaker.has_method("_sync_detailed_model"): speaker._sync_detailed_model()
	if listener.has_method("_sync_detailed_model"): listener._sync_detailed_model()
	s24_peer_visible = true
	s24_active_cue = cue_id

func _conversation_hand(actor: Node3D, index: int, weight: float, shoulder: float, elbow: float) -> void:
	actor.arms[index].rotation.x += shoulder * weight
	actor.elbows[index].rotation.x += elbow * weight
	actor.arms[index].rotation.z += (-0.035 if index == 0 else 0.035) * weight

func _update_captions(ms: float) -> void:
	caption.text = ""
	current_cue = ""
	for cue in data.cues[part]:
		var start_ms: float = cue.subtitle_start_ms if part=="A" else cue.start_ms
		var end_ms: float = cue.subtitle_end_ms if part=="A" else cue.end_ms
		if ms >= start_ms and ms < end_ms:
			current_cue = cue.id
			if current_cue not in seen_cues: seen_cues.append(current_cue)
			caption.text = "\n".join(cue.lines) if part=="A" else ("姜岚：" if cue.speaker=="scout" else "沈砚：") + cue.text
			break
	title.text = ""
	for event in data.events:
		if event.part == part and event.kind in ["place_card","title"] and ms >= event.start_ms and ms < event.end_ms:
			title.text = event.text
	# Time/place cards stay above faces and never overlap dialogue.
	title.anchor_top = .11 if part=="B" else .3
	title.anchor_bottom = .30 if part=="B" else .66

func _update_sound(ms: float) -> void:
	if part == "B" and not current_cue.is_empty():
		var voice_key := "voice_" + current_cue
		if not fired_sounds.has(voice_key):
			fired_sounds[voice_key] = true
			var voice_stream: AudioStream = voice_streams.get(current_cue)
			var at_seconds := 0.0
			for cue in data.cues.B:
				if cue.id == current_cue:
					at_seconds = maxf(0.0, (ms - float(cue.start_ms)) * 0.001)
					break
			main.audio_mix.play_voice(voice_stream, at_seconds)
	if part == "A" and shot.segment == "A4":
		for i in BARRAGE.size():
			var key := "blast_%d" % i
			var age := ms*0.001-float(BARRAGE[i].time)
			if age >= 0 and age < 0.15 and not fired_sounds.has(key):
				fired_sounds[key] = true
				blasts[i].play_impact()
	if part == "B" and ms >= 51650 and not fired_sounds.has("metal"):
		fired_sounds.metal = true
		metal_audio.play()
	if shot.segment == "A4":
		var beat := int((ms-32740)/1250)
		var key := "shot_%d" % beat
		if not fired_sounds.has(key):
			fired_sounds[key] = true
			shot_audio.play()
	if shot_id in ["A-02","A-08","B-08","B-09","B-10"]:
		var key := "step_%d" % int(ms/650)
		if not fired_sounds.has(key):
			fired_sounds[key] = true
			step_audio.play()

func skip(expected_part: String) -> void:
	if not active or paused or expected_part != part or Time.get_ticks_msec()-last_skip_ms<350: return
	last_skip_ms = Time.get_ticks_msec()
	if part == "A": _enter_part("B")
	else: finish()

func set_paused(value: bool) -> void:
	if not active: return
	paused = value
	main.mode = "cinematic_paused" if value else "cinematic"
	ui.visible = not value
	for sound in [shot_audio,step_audio,metal_audio,main.ambience]: sound.stream_paused = value
	main.audio_mix.voice.stream_paused = value
	for sound in main.audio_mix.music: sound.stream_paused = value
	for blast in blasts: blast.sound.stream_paused = value
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func handle_input(event: InputEvent) -> bool:
	if not active: return false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			set_paused(not paused)
			return true
		if event.physical_keycode == KEY_ENTER and not paused:
			skip(part)
			return true
	return false

func finish() -> void:
	if not active: return
	handoff_state = "committing"
	handoff_count += 1
	main.player.restore({"position":[main.START.x,main.START.y,main.START.z],"yaw":-.6,"health":100.0,"magazines":[5,10],"reserves":[35,50],"weapon":0})
	main.story.met_scout = true
	main.story.people.scout.rotation.y = 2.7
	main.opening_phase = "gameplay"
	abort()
	if not main._save_checkpoint():
		main.mode = "opening_save_error"
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	main.resume()
	main.notify("取回名册，再切断电话中继，接上陆山去渡口。木棚可找林师傅帮忙，J查看记录。",9)
	handoff_state = "committed"

func _begin_handoff() -> void:
	if not active or handoff_state != "idle": return
	handoff_state = "transition"
	handoff_elapsed = 0.0
	# Keep the final B16 composition and lock input while the aligned player
	# camera is covered. The actual save and control restore happen once.
	main.mode = "cinematic"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func abort() -> void:
	for blast in blasts: blast.cancel()
	active = false
	paused = false
	visible = false
	ui.visible = false
	for node in hidden_nodes:
		if is_instance_valid(node): node.visible = true
	hidden_nodes.clear()
	_stop_cue_audio()
	main.ambience.stream_paused = false
	main.player.model.visible = true
	main.player.camera.make_current()
	_set_access_collisions(false)

func _stop_cue_audio() -> void:
	for sound in [shot_audio,step_audio,metal_audio]:
		sound.stream_paused = false
		sound.stop()
	main.audio_mix.play_voice(null)

func _set_access_collisions(enabled: bool) -> void:
	if not is_instance_valid(terrace): return
	for body in terrace.find_children("*", "StaticBody3D", true, false):
		body.collision_layer = 1 if enabled else 0
		body.collision_mask = 1 if enabled else 0

func preview_at(which: String, seconds: float) -> void:
	# Explicit QA-only seeking; player controls cannot silently jump time.
	if "--qa" not in OS.get_cmdline_user_args(): return
	if which != part:
		_enter_part(which, false)
	part = which
	clock = seconds
	if part == "A": main.audio_mix.play_voice(HISTORY_AUDIO, seconds, true)
	shot_id = ""
	_update_view(.1)

func _v(value: Array) -> Vector3:
	return Vector3(value[0],value[1],value[2])

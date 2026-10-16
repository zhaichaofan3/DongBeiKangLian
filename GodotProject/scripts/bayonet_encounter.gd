extends Node3D
## Shared turn, charge and grapple animation; the last office defender uses it.
## The pre-grapple checkpoint survives interruption, defeat and retry.

const SHOUT = preload("res://assets/audio/bayonet_charge.mp3")
const Hands = preload("res://scripts/fp_hands.gd")
const WeaponVisuals = preload("res://scripts/weapon_visuals.gd")
const TURN_TIME := 0.65
const CHARGE_TIME := 1.15
const STRUGGLE_TIME := 8.0
const GAIN := 0.075
const DECAY := 0.105
const PLAYER_MARK := Vector3(34, 0.08, 124)
const ENEMY_MARK := Vector3(34, 0.08, 123.02)
const MAX_ARM_REACH := 0.82
var main: Node3D
var active := false
var phase := "idle"
var clock := 0.0
var pressure := 0.25
var taps := 0
var space_down := false
var pulse := 0.0
var enemy: CharacterBody3D
var camera: Camera3D
var hands: Array[Node3D] = []
var blade: Node3D
var close_rifle: Node3D
var hidden_rifle_parts: Array[Node3D] = []
var overlay: CanvasLayer
var panel: Control
var caption: Label
var progress: ProgressBar
var danger: ColorRect
var starting_camera := Transform3D.IDENTITY
var starting_enemy := Transform3D.IDENTITY
var starting_player := Transform3D.IDENTITY
var starting_position := Vector3.ZERO
var starting_yaw := 0.0
var death_started := false
var charge_seconds := CHARGE_TIME
var enemy_interpolation := Node.PHYSICS_INTERPOLATION_MODE_INHERIT
var player_mark := PLAYER_MARK
var enemy_mark := ENEMY_MARK
var player_yaw := 0.0
var enemy_yaw := PI
var charge_path := PackedVector3Array()
var charge_length := 0.0
var encounter_kind := "door"

func initialize(owner_node: Node3D) -> void:
	main = owner_node
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera = Camera3D.new()
	camera.near = 0.04
	camera.fov = 74
	add_child(camera)
	var cloth := StandardMaterial3D.new()
	cloth.albedo_color = Color("7c8083")
	cloth.roughness = 0.9
	var cuff := cloth.duplicate() as StandardMaterial3D
	cuff.albedo_color = Color("505559")
	for i in 2:
		var hand: Node3D = Hands.create(i == 1, 1, cloth, cuff)
		camera.add_child(hand)
		hand.sleeve_endpoint = Vector3(-0.42 if i == 0 else 0.42, -0.66, 0.12)
		hand.visible = false
		hands.append(hand)
	_build_hud()

func can_begin(kind: String = "office") -> bool:
	if active or not main.linear.enabled: return false
	if main.encounter_revision >= 2 and kind == "office":
		var remaining := 0
		for id in ["office_guard", "office_guard_2", "office_guard_3", "office_guard_4"]:
			if not main.defeated.has(id): remaining += 1
		if remaining != 1: return false
		for guard in main.guards:
			if is_instance_valid(guard) and guard.guard_id.begins_with("office_guard") and guard.state != "dead":
				return main.player.position.distance_to(guard.position) < 14 and main.world._path_segment_clear(guard.position, main.player.position)
		return false
	var id := "door_ambusher" if main.encounter_revision >= 2 else "office_guard"
	if main.defeated.has(id): return false
	for guard in main.guards:
		if is_instance_valid(guard) and guard.guard_id == id and guard.state != "dead": return true
	return false

func needs_office_approach(guard: CharacterBody3D) -> bool:
	if active or main.encounter_revision < 2 or not main.linear.enabled or not main.story.door_open or "yard" not in main.linear.opened:
		return false
	if not guard.guard_id.begins_with("office_guard"): return false
	var remaining := 0
	for id in ["office_guard", "office_guard_2", "office_guard_3", "office_guard_4"]:
		if not main.defeated.has(id): remaining += 1
	# Approach normally until a capsule-wide straight charge corridor opens.
	return remaining == 1 and (guard.position.distance_to(main.player.position) >= 14 or not main.world._path_segment_clear(guard.position, main.player.position))

func begin(kind: String = "office") -> void:
	if not can_begin(kind): return
	encounter_kind = kind if main.encounter_revision >= 2 else "door"
	var id := "door_ambusher" if main.encounter_revision >= 2 else "office_guard"
	for guard in main.guards:
		if is_instance_valid(guard) and guard.state != "dead" and (guard.guard_id.begins_with("office_guard") if encounter_kind == "office" else guard.guard_id == id): enemy = guard
	player_mark = PLAYER_MARK
	enemy_mark = ENEMY_MARK
	player_yaw = 0
	enemy_yaw = PI
	if encounter_kind == "office":
		player_mark = main.player.position
		var forward := enemy.position - player_mark
		forward.y = 0
		if forward.length() < 0.1: forward = Vector3.FORWARD
		forward = forward.normalized()
		enemy_mark = player_mark + forward * 0.98
		player_yaw = atan2(-forward.x, -forward.z)
		enemy_yaw = player_yaw + PI
	active = true
	phase = "turn"
	clock = 0
	pressure = 0.25
	taps = 0
	pulse = 0
	space_down = Input.is_physical_key_pressed(KEY_SPACE)
	death_started = false
	starting_camera = main.player.camera.global_transform
	starting_enemy = enemy.transform
	starting_player = main.player.transform
	starting_position = enemy.position
	charge_path = PackedVector3Array([starting_position, enemy_mark])
	charge_length = starting_position.distance_to(enemy_mark)
	charge_seconds = maxf(CHARGE_TIME, charge_length / 4.3)
	starting_yaw = enemy.rotation.y
	enemy_interpolation = enemy.physics_interpolation_mode
	enemy.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	main.mode = "melee"
	main.player.velocity = Vector3.ZERO
	main.player.fire_requested = false
	main.player.model.visible = false
	enemy.velocity = Vector3.ZERO
	enemy.collision_layer = 0
	camera.global_transform = starting_camera
	camera.current = true
	_add_bayonet()
	panel.visible = true
	main.audio_mix.play_voice(SHOUT)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func handle_input(event: InputEvent) -> bool:
	if not active: return false
	if event.is_action_pressed("pause"):
		set_paused(main.mode == "melee")
		return true
	if event is InputEventKey and (event.physical_keycode == KEY_SPACE or event.keycode == KEY_SPACE):
		if not event.pressed:
			space_down = false
		elif not event.echo and not space_down:
			space_down = true
			if phase == "struggle" and main.mode == "melee":
				taps += 1
				pressure = minf(1.0, pressure + GAIN)
				pulse = 1.0
				if pressure >= 1.0: _phase("counter")
		return true
	return main.mode == "melee"

func set_paused(value: bool) -> void:
	if not active: return
	main.mode = "paused" if value else "melee"
	panel.visible = not value
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED
	main.audio_mix.update_mix(0)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and active and main.mode == "melee": set_paused(true)

func _process(delta: float) -> void:
	if not active or main.mode != "melee": return
	clock += delta
	pulse = maxf(0, pulse - delta * 5)
	match phase:
		"turn":
			var t := smoothstep(0, TURN_TIME, clock)
			enemy.rotation.y = lerp_angle(starting_yaw, enemy_yaw, t)
			main.player.position = starting_player.origin.lerp(player_mark, t)
			_pose(delta, 0, 0)
			var target := Transform3D(Basis.IDENTITY, player_mark + Vector3(0, 1.57, 0))
			target = target.looking_at(enemy.position + Vector3(0, 1.4, 0))
			camera.global_transform = starting_camera.interpolate_with(target, t)
			caption.text = "日军突然转身，挺起刺刀！"
			if clock >= TURN_TIME: _phase("charge")
		"charge":
			var t := clampf(clock / charge_seconds, 0, 1)
			enemy.position = _charge_position(t)
			enemy.rotation.y = enemy_yaw
			_pose(delta, 4.3, smoothstep(0.65, 1.0, t))
			_frame(0.0)
			_place_hands(smoothstep(1.75, 1.05, enemy.position.distance_to(player_mark)))
			caption.text = "挡住刺刀！准备连续按空格"
			if clock >= charge_seconds: _phase("struggle")
		"struggle":
			pressure = maxf(0, pressure - delta * DECAY)
			_pose(delta, 0, 1)
			_frame(0.012)
			caption.text = "连续按【空格】挣脱并反杀\n每次松开再按 · 长按无效 · Esc 暂停"
			if clock >= STRUGGLE_TIME or (clock > 1.5 and pressure <= 0): _phase("failure")
		"counter":
			_pose(delta, 0, 1)
			var twist := smoothstep(0, 0.55, clock)
			enemy.model.rifle.rotation.y = lerpf(1.3, PI, twist)
			enemy.model.rifle.position.z = lerpf(-0.53, -0.03, smoothstep(0.45, 0.85, clock))
			enemy.model._pose_guard_grip()
			enemy.model._sync_detailed_model()
			_frame(0.015)
			caption.text = "夺下枪身，反制！"
			if clock >= 0.85:
				enemy.take_damage(1000)
				death_started = true
				_phase("fall")
		"fall":
			enemy.model.animate_death(delta)
			for hand in hands: hand.visible = false
			caption.text = "已挣脱"
			if clock >= 1.05: _finish()
		"failure":
			_pose(delta, 0, 1)
			enemy.model.rifle.rotation.y = lerpf(1.3, 0, smoothstep(0, 0.45, clock))
			enemy.model._pose_guard_grip()
			enemy.model._sync_detailed_model()
			_frame(0.025)
			caption.text = "没能挡住刺刀……"
			if clock >= 0.65:
				abort()
				main.player.health = 0
				main.lose()
	progress.visible = phase == "struggle"
	progress.value = pressure * 100
	danger.color.a = minf(0.55, clock * 0.7) if phase == "failure" else (1.0-pressure)*0.13 if phase == "struggle" else 0.0

func _phase(value: String) -> void:
	phase = value
	clock = 0

func _charge_position(weight: float) -> Vector3:
	return starting_position.lerp(enemy_mark, clampf(weight, 0, 1))

func _pose(delta: float, speed: float, grapple: float) -> void:
	var model: Node3D = enemy.model
	model.set_motion_context(false, 0, true)
	model.animate(delta, speed)
	model.chest.rotation.x = -0.04 + (sin(clock * 13) * 0.012 + (pressure-0.5)*0.05) * grapple
	model.rifle.position = Vector3(lerpf(0.11, 0.0, grapple), 0.28 + pulse*0.018, lerpf(-0.29,-0.53,grapple) + (pressure-0.5)*0.035*grapple)
	model.rifle.rotation = Vector3(0.02, grapple*1.3, sin(clock*14)*0.025*grapple)
	model._pose_guard_grip()
	model._sync_detailed_model()

func _frame(shake: float) -> void:
	shake *= main.presentation.motion_strength
	camera.position = player_mark + Vector3(sin(clock*18)*shake, 1.57+cos(clock*16)*shake, pulse*0.018)
	camera.look_at(enemy_mark + Vector3(0, 1.35, 0))
	camera.rotation.z = sin(clock*11)*shake*0.7
	if phase in ["struggle", "counter", "failure"]: _place_hands(1)

func _place_hands(weight: float) -> void:
	for i in 2:
		var hand := hands[i]
		var grip := Vector3(0, -0.075 if i == 0 else -0.035, 0.15 if i == 0 else -0.38)
		var target: Vector3 = camera.to_local(enemy.model.rifle.to_global(grip))
		var reach: Vector3 = target - hand.sleeve_endpoint
		# Raise the arms only when the rifle enters reach, then keep a fixed arm budget.
		hand.visible = weight > 0.01 and reach.length() <= MAX_ARM_REACH + 0.22
		target = hand.sleeve_endpoint + reach.limit_length(MAX_ARM_REACH)
		var up: Vector3 = (target - hand.sleeve_endpoint).normalized()
		var back: Vector3 = Vector3.BACK - up * up.dot(Vector3.BACK)
		back = back.normalized()
		hand.basis = Basis(up.cross(back).normalized(), up, back)
		hand.position = target - up * 0.065 + Vector3(0, -0.25, 0.18) * (1-weight)
		hand.pose("grip", 1, 1)
		hand.update_sleeve()

func _add_bayonet() -> void:
	# The close shot uses the existing detailed rifle instead of the distant
	# guard's box silhouette. Keep the same attachment and grip coordinate frame.
	hidden_rifle_parts.clear()
	for child in enemy.model.rifle.get_children():
		if child is MeshInstance3D and child.visible:
			child.visible = false
			hidden_rifle_parts.append(child)
	var rig: Dictionary = WeaponVisuals.build(0)
	rig.left.free()
	rig.right.free()
	close_rifle = rig.root
	close_rifle.scale = Vector3.ONE * 0.8
	enemy.model.rifle.add_child(close_rifle)
	blade = Node3D.new()
	blade.name = "EncounterBayonet"
	enemy.model.rifle.add_child(blade)
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color("b5b9b6")
	metal.metallic = 0.72
	metal.roughness = 0.3
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := [Vector3(-0.022,-0.015,-0.56),Vector3(0.022,-0.015,-0.56),Vector3(0,-0.009,-0.56),Vector3(0,-0.021,-0.56),Vector3(0,-0.015,-0.97)]
	for triangle in [[0,2,4],[2,1,4],[1,3,4],[3,0,4],[0,3,2],[2,3,1]]:
		for index in triangle: surface.add_vertex(points[index])
	surface.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = surface.commit()
	mesh.material_override = metal
	blade.add_child(mesh)
	var guard_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.082,0.012,0.015)
	guard_mesh.mesh = box
	guard_mesh.position = Vector3(0,-0.015,-0.56)
	guard_mesh.material_override = metal
	blade.add_child(guard_mesh)

func _finish() -> void:
	abort(false)
	main.player.position = player_mark
	main.player.rotation.y = player_yaw
	main.player.pitch = 0
	main.player.camera.rotation = Vector3.ZERO
	main.player.reset_physics_interpolation()
	main.resume()
	if not main._save_checkpoint(): main.notify("已挣脱，但保存失败。" + main.last_save_error, 7)
	else: main.notify("电报房守卫已全部清除，继续寻找名册并接应陆山。" if encounter_kind == "office" else "已反杀突袭守卫。电报房在右前方，继续寻找名册。", 6)

func abort(restore_actors: bool = true) -> void:
	if not active: return
	active = false
	phase = "idle"
	main.audio_mix.voice.stream_paused = false
	main.audio_mix.voice.stop()
	panel.visible = false
	for hand in hands: hand.visible = false
	if is_instance_valid(blade): blade.queue_free()
	if is_instance_valid(close_rifle): close_rifle.queue_free()
	for part in hidden_rifle_parts:
		if is_instance_valid(part): part.visible = true
	hidden_rifle_parts.clear()
	if is_instance_valid(enemy) and not death_started:
		enemy.collision_layer = 4
		if restore_actors: enemy.transform = starting_enemy
	if is_instance_valid(enemy):
		enemy.physics_interpolation_mode = enemy_interpolation
		enemy.reset_physics_interpolation()
	if restore_actors: main.player.transform = starting_player
	main.player.camera.current = true
	main.player.model.visible = true
	main.player.velocity = Vector3.ZERO
	main.player.reset_physics_interpolation()
	space_down = false

func _build_hud() -> void:
	overlay = CanvasLayer.new()
	overlay.layer = 4
	add_child(overlay)
	panel = Control.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.theme = main.hud.root.theme
	overlay.add_child(panel)
	danger = ColorRect.new()
	danger.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	danger.color = Color(0.4,0.015,0.005,0)
	danger.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(danger)
	caption = Label.new()
	caption.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	caption.position = Vector2(-440,-126)
	caption.size = Vector2(880,70)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size",24)
	caption.add_theme_color_override("font_shadow_color",Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x",2)
	caption.add_theme_constant_override("shadow_offset_y",2)
	panel.add_child(caption)
	progress = ProgressBar.new()
	progress.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	progress.position = Vector2(-220,-48)
	progress.size = Vector2(440,18)
	progress.show_percentage = false
	panel.add_child(progress)
	panel.visible = false

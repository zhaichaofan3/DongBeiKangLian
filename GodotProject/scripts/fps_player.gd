extends CharacterBody3D

const AudioFactory = preload("res://scripts/audio_factory.gd")
const MuzzleEffect = preload("res://scripts/muzzle_effect.gd")
const WeaponVisuals = preload("res://scripts/weapon_visuals.gd")
const WEAPONS := [
	{"name": "98k步枪", "capacity": 5, "damage": 80.0, "interval": 0.85, "reload": 2.1, "sound": "rifle"},
	{"name": "驳壳枪", "capacity": 10, "damage": 36.0, "interval": 0.24, "reload": 1.5, "sound": "pistol"}
]
var main: Node3D
var camera: Camera3D
var collider: CollisionShape3D
var health := 100.0
var magazines: Array[int] = [5, 10]
var reserves: Array[int] = [35, 50]
var weapon_index := 0
var pitch := 0.0
var sensitivity := 0.002
var reload_timer := 0.0
var shot_timer := 0.0
var recoil := 0.0
var damage_flash := 0.0
var crouching := false
var aiming := false
var fire_requested := false
var step_clock := 0.0
var walk_clock := 0.0
var horizontal_velocity := Vector2.ZERO
var model: Node3D
var models: Array[Node3D] = []
var muzzle_light: OmniLight3D
var sound: AudioStreamPlayer
var bolt_sound: AudioStreamPlayer
var bolt_pending := false
var footsteps: AudioStreamPlayer
var sounds: Dictionary = {}
var weapon_rigs: Array[Dictionary] = []
var hand_rest: Array[Dictionary] = []
var muzzle_flash: MeshInstance3D
var muzzle_smoke: CPUParticles3D
var flash_time := 0.0
var smoke_age := 1.0
var breath_clock := 0.0
var movement_blend := 0.0
var sprint_blend := 0.0
var aim_blend := 0.0
var mouse_impulse := Vector2.ZERO
var mouse_sway := Vector2.ZERO
var view_kick := 0.0
var visual_fire_age := 2.0
var switch_age := 1.0

func initialize(owner_node: Node3D, spawn: Vector3) -> void:
	main = owner_node
	position = spawn
	name = "Player"
	collision_layer = 2
	collision_mask = 1 | 4
	collider = CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.72
	collider.shape = shape
	collider.position.y = 0.86
	add_child(collider)
	camera = Camera3D.new()
	camera.position.y = 1.57
	camera.fov = 78.0
	camera.near = 0.04
	camera.current = true
	add_child(camera)
	model = Node3D.new()
	model.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	model.position = WeaponVisuals.HIP_POSITIONS[0]
	model.rotation = WeaponVisuals.HIP_ROTATION
	camera.add_child(model)
	_build_weapons()
	sound = AudioStreamPlayer.new()
	sound.volume_db = -12
	add_child(sound)
	bolt_sound = AudioStreamPlayer.new()
	bolt_sound.stream = AudioFactory.USER_RELOAD
	bolt_sound.volume_db = -12
	add_child(bolt_sound)
	footsteps = AudioStreamPlayer.new()
	footsteps.volume_db = -21
	add_child(footsteps)
	for kind in ["rifle", "pistol", "reload", "hit", "step", "step_run"]:
		sounds[kind] = AudioFactory.make_sound(kind)

func _unhandled_input(event: InputEvent) -> void:
	if main.mode != "playing":
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensitivity * (0.55 if aiming else 1.0))
		pitch = clampf(pitch - event.relative.y * sensitivity * (0.55 if aiming else 1.0), -1.4, 1.4)
		mouse_impulse += event.relative * 0.00012
		mouse_impulse = mouse_impulse.clamp(Vector2(-0.025, -0.02), Vector2(0.025, 0.02))
	if event.is_action_pressed("fire"):
		fire_requested = true
	if event.is_action_pressed("reload"):
		start_reload()
	if event.is_action_pressed("weapon_1"):
		switch_weapon(0)
	if event.is_action_pressed("weapon_2"):
		switch_weapon(1)
	if event.is_action_pressed("interact"):
		main.interact()

func _physics_process(delta: float) -> void:
	if main.mode != "playing":
		return
	shot_timer = maxf(0.0, shot_timer - delta)
	if bolt_pending and visual_fire_age >= 0.235:
		bolt_pending = false
		bolt_sound.play()
	damage_flash = maxf(0.0, damage_flash - delta * 1.8)
	recoil = move_toward(recoil, 0, delta * 0.12)
	aiming = Input.is_action_pressed("aim")
	var requested_crouch := Input.is_action_pressed("crouch")
	if requested_crouch or _can_stand():
		crouching = requested_crouch
	(collider.shape as CapsuleShape3D).height = 1.05 if crouching else 1.72
	collider.position.y = 0.525 if crouching else 0.86
	camera.position.y = lerpf(camera.position.y, 0.95 if crouching else 1.57, minf(1.0, delta * 12))
	var axis := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(axis.x, 0, axis.y)).normalized()
	var speed := 1.7 if crouching else 3.8
	if Input.is_action_pressed("sprint") and not crouching and not aiming:
		speed = 6.0
	if aiming:
		speed *= 0.65
	var target_horizontal := Vector2(direction.x, direction.z) * speed
	var acceleration := 22.0 if target_horizontal.length() > 0.1 else 30.0
	horizontal_velocity = horizontal_velocity.move_toward(target_horizontal, acceleration * delta)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.y
	if is_on_floor():
		velocity.y = 5.0 if Input.is_action_just_pressed("jump") and not crouching else -0.2
	else:
		velocity.y -= 20.0 * delta
	_block_wire_edge_climb(delta)
	move_and_slide()
	var actual_speed := horizontal_velocity.length()
	if actual_speed > 0.1 and is_on_floor():
		walk_clock += delta * actual_speed * 2.0
		var step_stream: AudioStream = sounds["step_run"] if actual_speed >= 4.8 else sounds["step"]
		if footsteps.stream != step_stream: step_clock = minf(step_clock, 0.08)
		step_clock -= delta
		if step_clock <= 0.0:
			step_clock = 2.0 / maxf(actual_speed, 3.8)
			footsteps.stream = step_stream
			footsteps.play()
	else:
		step_clock = minf(step_clock, 0.08)
		footsteps.stop()
	if reload_timer > 0:
		reload_timer -= delta
		if reload_timer <= 0:
			var count := mini(WEAPONS[weapon_index]["capacity"] - magazines[weapon_index], reserves[weapon_index])
			magazines[weapon_index] += count
			reserves[weapon_index] -= count
	if fire_requested:
		fire_requested = false
		fire()
	camera.rotation.x = pitch + recoil

func _block_wire_edge_climb(delta: float) -> void:
	var motion := Vector3(velocity.x,0,velocity.z)
	if motion.length_squared()<.001: return
	# A round capsule must not ride up barbed wire while its feet are below it.
	var feet := global_position+Vector3.UP*.04
	var query := PhysicsRayQueryParameters3D.create(feet,feet+motion.normalized()*(.34+motion.length()*delta),1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or not hit.collider.has_meta("low_side_wire"): return
	var normal: Vector3 = hit.normal
	normal.y = 0
	if normal.length_squared()<.001: return
	motion = motion.slide(normal.normalized())
	velocity.x = motion.x
	velocity.z = motion.z
	horizontal_velocity = Vector2(motion.x,motion.z)

func _process(delta: float) -> void:
	if not is_instance_valid(main) or not is_instance_valid(model):
		return
	if main.mode != "playing":
		if main.mode == "dialogue":
			model.position = model.position.lerp(WeaponVisuals.SAFE_POSITION, 1.0 - exp(-delta * 12))
			model.rotation = model.rotation.lerp(WeaponVisuals.SAFE_ROTATION, 1.0 - exp(-delta * 12))
		muzzle_flash.visible = false
		muzzle_light.light_energy = 0.0
		muzzle_smoke.emitting = false
		muzzle_smoke.visible = false
		flash_time = 0.0
		return
	# View-model motion never changes the camera basis used by fire().
	var motion := 0.65
	var presentation: Variant = main.get("presentation")
	if presentation != null:
		motion = float(presentation.motion_strength)
	var smooth := 1.0 - exp(-delta * 12.0)
	breath_clock += delta
	visual_fire_age += delta
	switch_age += delta
	flash_time = maxf(0.0, flash_time - delta)
	smoke_age += delta
	if smoke_age >= MuzzleEffect.TOTAL_SECONDS: muzzle_smoke.visible = false
	view_kick *= exp(-delta * 14.0)
	mouse_impulse *= exp(-delta * 7.0)
	mouse_sway = mouse_sway.lerp(mouse_impulse, 1.0 - exp(-delta * 10.0))
	var moving := Vector2(velocity.x, velocity.z).length()
	movement_blend = lerpf(movement_blend, clampf(moving / 3.8, 0.0, 1.0) if is_on_floor() else 0.0, smooth)
	sprint_blend = lerpf(sprint_blend, 1.0 if moving > 4.5 and not aiming else 0.0, smooth)
	aim_blend = lerpf(aim_blend, 1.0 if aiming else 0.0, 1.0 - exp(-delta * 13.0))
	camera.fov = lerpf(78.0, 54.0, aim_blend)
	var held: Vector3 = WeaponVisuals.HIP_POSITIONS[weapon_index]
	var aimed: Vector3 = WeaponVisuals.AIM_POSITIONS[weapon_index]
	var target := held.lerp(aimed, aim_blend)
	var sway_scale := motion * lerpf(1.0, 0.14, aim_blend)
	var stride := Vector3(sin(walk_clock * 0.5) * 0.009, cos(walk_clock) * 0.011, sin(walk_clock) * 0.004) * movement_blend
	var breath := Vector3(sin(breath_clock * 1.4) * 0.0025, sin(breath_clock * 2.8) * 0.003, 0)
	target += (stride + breath + Vector3(-mouse_sway.x, mouse_sway.y, 0)) * sway_scale
	target += Vector3(0.018, -0.035, 0.045) * sprint_blend
	target.z += view_kick * 1.6
	var target_rotation := WeaponVisuals.HIP_ROTATION * (1.0 - aim_blend)
	if weapon_index == 0 and reload_timer <= 0.0:
		# Lower the supplied high-mounted handle clear of the sight line while cycling.
		var cycling := _envelope(visual_fire_age, 0.055, 0.145, 0.765, 0.90)
		target += Vector3(0.13, -0.11, -0.08) * cycling
		target_rotation += Vector3(-0.08, 0.05, -0.10) * cycling
	target_rotation.x += view_kick * 0.9
	target_rotation += Vector3(mouse_sway.y, mouse_sway.x, -sin(walk_clock * 0.5) * 0.016 * movement_blend) * sway_scale
	target_rotation += Vector3(-0.26, 0.20, 0.20) * sprint_blend
	var switch_weight := pow(maxf(0.0, 1.0 - switch_age / 0.27), 2.0)
	target += Vector3(0.055, -0.27, 0.12) * switch_weight
	target_rotation += Vector3(-0.45, -0.15, -0.13) * switch_weight
	if reload_timer > 0.0:
		var progress := clampf(1.0 - reload_timer / float(WEAPONS[weapon_index]["reload"]), 0.0, 1.0)
		var reload_weight := _envelope(progress, 0.0, 0.13, 0.83, 1.0)
		target += Vector3(-0.055, -0.022, -0.005) * reload_weight
		target_rotation += Vector3(-0.10, -0.25, 0.29) * reload_weight
	model.position = model.position.lerp(target, smooth)
	model.rotation = model.rotation.lerp(target_rotation, smooth)
	_animate_mechanism(delta)
	muzzle_flash.visible = flash_time > 0.0
	muzzle_flash.position = weapon_rigs[weapon_index].muzzle
	muzzle_flash.scale = Vector3.ONE * (0.75 + flash_time * 5.0)
	muzzle_light.position = weapon_rigs[weapon_index].muzzle
	muzzle_light.light_energy = 2.7 * clampf(flash_time / 0.045, 0.0, 1.0)
	muzzle_smoke.position = weapon_rigs[weapon_index].muzzle

func _animate_mechanism(delta: float) -> void:
	var rig: Dictionary = weapon_rigs[weapon_index]
	var rest: Dictionary = hand_rest[weapon_index]
	var bolt: Node3D = rig.bolt
	var left: Node3D = rig.left
	var right: Node3D = rig.right
	var clip: Node3D = rig.clip
	var left_at: Vector3 = rest.left_position
	var right_at: Vector3 = rest.right_position
	var left_basis := Basis.from_euler(rest.left_rotation)
	var right_basis := Basis.from_euler(rest.right_rotation)
	var bolt_pull := 0.0
	var bolt_lift := 0.0
	var handle := 0.0
	var reach := 0.0
	var insert := 0.0
	var left_action := "grip"
	var loading := reload_timer > 0.0
	clip.visible = false
	if loading:
		var t := clampf(1.0 - reload_timer / float(WEAPONS[weapon_index]["reload"]), 0.0, 1.0)
		bolt_lift = _envelope(t, 0.02, 0.12, 0.80, 0.93)
		bolt_pull = _envelope(t, 0.08, 0.21, 0.73, 0.89)
		reach = _envelope(t, 0.15, 0.30, 0.70, 0.86)
		insert = smoothstep(0.38, 0.60, t)
		handle = minf(1.0, _envelope(t, 0.01, 0.09, 0.22, 0.31) + _envelope(t, 0.72, 0.79, 0.89, 0.98)) if weapon_index == 0 else 0.0
		clip.visible = t > 0.26 and t < 0.72
		clip.position = Vector3(0, 0.15 - insert * 0.094, -0.046)
		# Wrist and curled fingers track the same loading contact as the clip.
		var load_basis := Basis(Vector3.FORWARD,Vector3.RIGHT,Vector3.DOWN)
		var load_wrist := Vector3(-0.094,clip.position.y + 0.052,-0.028)
		left_at = left_at.lerp(load_wrist,reach)
		left_basis = left_basis.slerp(load_basis,reach)
		left_action = "push" if t > 0.43 and t < 0.69 else "clip"
		if t > 0.69: left_action = "release"
	elif weapon_index == 0:
		# Reach first, lift the handle, pull/push, then lock and regrip.
		bolt_lift = _envelope(visual_fire_age, 0.15, 0.235, 0.645, 0.755)
		bolt_pull = _envelope(visual_fire_age, 0.245, 0.36, 0.49, 0.64)
		handle = _envelope(visual_fire_age, 0.055, 0.145, 0.765, 0.84)
	else:
		bolt_pull = _envelope(visual_fire_age, 0.0, 0.018, 0.044, 0.09)
	bolt.position.z = bolt_pull * (0.085 if weapon_index == 0 else 0.027)
	bolt.rotation.z = bolt_lift * 0.90 if weapon_index == 0 else 0.0
	left.pose(left_action,reach if loading else 1.0,delta)
	right.pose("bolt" if handle > 0.01 else "grip",handle if handle > 0.01 else 1.0,delta,exp(-visual_fire_age*18.0))
	if handle > 0.0:
		var handle_basis := bolt.basis * Basis(Vector3.UP,Vector3.FORWARD,Vector3.LEFT)
		var knob: Vector3 = bolt.transform * rig.get("bolt_contact", Vector3(0.078,0.01,0.035))
		var wrist: Vector3 = knob - handle_basis * right.bolt_contact()
		right_at = right_at.lerp(wrist,handle)
		# Lift clear of the stock while changing grip, with zero offset while
		# operating the mechanism. The time envelopes already ease both ends.
		right_at += Vector3(0.018,0.012,0.009) * sin(handle * PI)
		right_basis = right_basis.slerp(handle_basis,handle)
	if loading:
		left_at += Vector3(-0.025,0.018,0.012) * sin(reach * PI)
	left.position = left_at
	right.position = right_at
	left.basis = left_basis
	right.basis = right_basis
	left.update_sleeve()
	right.update_sleeve()

func _envelope(value: float, start: float, rise: float, fall: float, end: float) -> float:
	return smoothstep(start, rise, value) * (1.0 - smoothstep(fall, end, value))

func _can_stand() -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.02, global_position + Vector3.UP * 1.8, 1)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func fire() -> void:
	if main.mode != "playing" or reload_timer > 0 or shot_timer > 0:
		return
	if magazines[weapon_index] <= 0:
		main.notify("没有子弹了。", 1.2)
		return
	magazines[weapon_index] -= 1
	shot_timer = WEAPONS[weapon_index]["interval"]
	recoil = 0.035 if weapon_index == 0 else 0.022
	view_kick = 0.065 if weapon_index == 0 else 0.043
	visual_fire_age = 0.0
	bolt_pending = weapon_index == 0
	flash_time = 0.045
	muzzle_flash.rotation.z = randf() * TAU
	muzzle_light.light_energy = 3.5
	muzzle_flash.position = weapon_rigs[weapon_index].muzzle
	muzzle_flash.visible = true
	muzzle_light.position = weapon_rigs[weapon_index].muzzle
	muzzle_smoke.position = weapon_rigs[weapon_index].muzzle
	muzzle_smoke.visible = true
	smoke_age = 0.0
	muzzle_smoke.restart()
	muzzle_smoke.emitting = true
	_play(WEAPONS[weapon_index]["sound"])
	main.hear_shot(global_position)
	var origin := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(origin, origin - camera.global_basis.z * 110.0, 1 | 4 | 8)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if hit.collider.collision_layer == 8:
			main.notify("注意枪口，前面是自己人。", 2.5)
			return
		main.impact(hit.position)
		if hit.collider.has_method("take_damage"):
			hit.collider.take_damage(WEAPONS[weapon_index]["damage"])
			main.hit_marker = 0.2

func start_reload() -> void:
	if main.mode != "playing" or reload_timer > 0 or magazines[weapon_index] >= WEAPONS[weapon_index]["capacity"] or reserves[weapon_index] <= 0:
		return
	reload_timer = WEAPONS[weapon_index]["reload"]
	bolt_pending = false
	bolt_sound.stop()
	_play("reload")

func switch_weapon(index: int) -> void:
	if index == weapon_index:
		return
	bolt_pending = false
	bolt_sound.stop()
	var previous_rig: Dictionary = weapon_rigs[weapon_index]
	var previous_rest: Dictionary = hand_rest[weapon_index]
	previous_rig.clip.visible = false
	previous_rig.bolt.position = Vector3.ZERO
	previous_rig.bolt.rotation = Vector3.ZERO
	previous_rig.left.position = previous_rest.left_position
	previous_rig.left.rotation = previous_rest.left_rotation
	previous_rig.right.position = previous_rest.right_position
	previous_rig.right.rotation = previous_rest.right_rotation
	weapon_index = index
	reload_timer = 0
	shot_timer = 0.25
	switch_age = 0.0
	visual_fire_age = 2.0
	flash_time = 0.0
	muzzle_smoke.emitting = false
	muzzle_smoke.visible = false
	muzzle_flash.visible = false
	muzzle_light.light_energy = 0.0
	for i in models.size():
		models[i].visible = i == index

func take_damage(amount: float) -> void:
	if main.mode != "playing" or amount <= 0:
		return
	health = maxf(0, health - amount)
	damage_flash = 0.45
	_play("hit")
	if health <= 0:
		main.lose()

func restore(snapshot: Dictionary) -> void:
	position = Vector3(snapshot.position[0], snapshot.position[1], snapshot.position[2])
	rotation.y = snapshot.get("yaw", 0.0)
	pitch = 0
	velocity = Vector3.ZERO
	horizontal_velocity = Vector2.ZERO
	step_clock = 0.0
	walk_clock = 0.0
	health = snapshot.health
	magazines.assign(snapshot.magazines)
	reserves.assign(snapshot.reserves)
	reload_timer = 0
	bolt_pending = false
	bolt_sound.stop()
	shot_timer = 0
	damage_flash = 0
	fire_requested = false
	aiming = false
	crouching = false
	recoil = 0
	view_kick = 0.0
	flash_time = 0.0
	mouse_impulse = Vector2.ZERO
	mouse_sway = Vector2.ZERO
	aim_blend = 0.0
	movement_blend = 0.0
	sprint_blend = 0.0
	camera.rotation = Vector3.ZERO
	camera.fov = 78.0
	camera.position.y = 1.57
	(collider.shape as CapsuleShape3D).height = 1.72
	collider.position.y = 0.86
	switch_weapon(int(snapshot.weapon))
	visual_fire_age = 2.0
	switch_age = 1.0
	model.position = WeaponVisuals.HIP_POSITIONS[weapon_index]
	model.rotation = WeaponVisuals.HIP_ROTATION
	for i in weapon_rigs.size():
		var rig: Dictionary = weapon_rigs[i]
		var rest: Dictionary = hand_rest[i]
		rig.left.position = rest.left_position
		rig.left.rotation = rest.left_rotation
		rig.right.position = rest.right_position
		rig.right.rotation = rest.right_rotation
		rig.bolt.position = Vector3.ZERO
		rig.bolt.rotation = Vector3.ZERO
		rig.clip.visible = false
		rig.left.pose("grip",1.0,1.0)
		rig.right.pose("grip",1.0,1.0)
		rig.left.update_sleeve()
		rig.right.update_sleeve()
	muzzle_flash.visible = false
	muzzle_light.light_energy = 0.0
	muzzle_smoke.emitting = false
	muzzle_smoke.visible = false
	reset_physics_interpolation()

func snapshot() -> Dictionary:
	return {"position": [position.x, position.y, position.z], "yaw": rotation.y, "health": health, "magazines": magazines.duplicate(), "reserves": reserves.duplicate(), "weapon": weapon_index}

func _play(kind: String) -> void:
	sound.bus = &"Foley" if kind in ["reload", "hit"] else &"Weapons"
	sound.stream = sounds[kind]
	sound.play()

func _build_weapons() -> void:
	for i in 2:
		var rig := WeaponVisuals.build(i)
		var weapon: Node3D = rig.root
		model.add_child(weapon)
		models.append(weapon)
		weapon.visible = i == 0
		weapon_rigs.append(rig)
		hand_rest.append({"left_position": rig.left.position, "left_rotation": rig.left.rotation, "right_position": rig.right.position, "right_rotation": rig.right.rotation})
	muzzle_light = OmniLight3D.new()
	muzzle_light.position = weapon_rigs[0].muzzle
	muzzle_light.light_color = Color("ffcd75")
	muzzle_light.omni_range = 3.5
	muzzle_light.shadow_enabled = false
	muzzle_light.light_energy = 0
	model.add_child(muzzle_light)
	muzzle_flash = MuzzleEffect.make_flash()
	model.add_child(muzzle_flash)
	muzzle_smoke = MuzzleEffect.make_smoke(6, 0.16)
	muzzle_smoke.position = weapon_rigs[0].muzzle
	model.add_child(muzzle_smoke)

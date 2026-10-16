extends CharacterBody3D

const Human = preload("res://scripts/human_model.gd")
const AudioFactory = preload("res://scripts/audio_factory.gd")

var main: Node3D
var guard_id := ""
var spawn_position := Vector3.ZERO
var patrol_target := Vector3.ZERO
var patrol_endpoint := Vector3.ZERO
var last_seen := Vector3.ZERO
var health := 75.0
var state := "patrol"
var sight_memory := 0.0
var fire_timer := 1.2
var path_timer := 0.0
var route := PackedVector3Array()
var route_index := 0
var stride := 0.0
var model: Node3D
var report_timer := 0.0
var shots_fired := 0
var horizontal_velocity := Vector2.ZERO
var corpse_remaining := 5.0
var alert_audio: AudioStreamPlayer3D
var alert_cooldown := 0.0

func initialize(owner_node: Node3D, identifier: String, spawn: Vector3, patrol: Vector3) -> void:
	main = owner_node
	guard_id = identifier
	spawn_position = spawn
	position = spawn
	patrol_target = patrol
	patrol_endpoint = patrol
	name = identifier
	collision_layer = 4
	collision_mask = 1 | 2
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.7
	collider.shape = shape
	collider.position.y = 0.85
	add_child(collider)
	_build_model()
	alert_audio = AudioStreamPlayer3D.new()
	alert_audio.name = "AlertVoice"
	alert_audio.bus = &"Voice"
	alert_audio.stream = AudioFactory.make_sound("alert%d" % (absi(identifier.hash()) % 3 + 1))
	alert_audio.volume_db = -9
	alert_audio.max_distance = 32
	add_child(alert_audio)
	if is_instance_valid(main.audio_mix): main.audio_mix.register_player(alert_audio, &"Voice")

func _physics_process(delta: float) -> void:
	if state == "dead":
		if main.mode == "playing":
			model.animate_death(delta)
			corpse_remaining -= delta
			if corpse_remaining <= 0: queue_free()
		return
	if main.mode != "playing":
		return
	if main.linear != null and not main.linear.can_guard_act(guard_id):
		return
	var previous_yaw := rotation.y
	alert_cooldown = maxf(0, alert_cooldown - delta)
	var player_position: Vector3 = main.player.global_position
	var distance := global_position.distance_to(player_position)
	var visible_player := can_see_player()
	if visible_player:
		if state != "combat" and alert_cooldown <= 0:
			alert_audio.play()
			alert_cooldown = 8.0
		if state == "patrol":
			main.notify("岗哨发现了你！", 2.0)
			fire_timer = 1.4 + float(absi(guard_id.hash()) % 4) * 0.12
		state = "combat"
		last_seen = player_position
		sight_memory = 6.0
	else:
		sight_memory = maxf(0, sight_memory - delta)
		if state == "combat" and sight_memory < 4:
			state = "search"
		if state == "search" and sight_memory <= 0:
			state = "patrol"
	var approach_bayonet: bool = main.melee.needs_office_approach(self)
	var target := player_position if approach_bayonet else (patrol_target if state == "patrol" else last_seen)
	if state == "patrol" and global_position.distance_to(target) < 1.2:
		patrol_target = spawn_position if patrol_target != spawn_position else patrol_endpoint
	path_timer -= delta
	if path_timer <= 0:
		route = main.world.path(global_position, target)
		route_index = 1 if route.size() > 1 else 0
		path_timer = 0.6
	var direction := Vector3.ZERO
	if approach_bayonet and main.world._path_segment_clear(global_position, player_position):
		direction = (player_position - global_position).normalized()
		direction.y = 0
	elif (approach_bayonet or not (visible_player and distance < 17)) and route_index < route.size():
		var to_point := route[route_index] - global_position
		to_point.y = 0
		if to_point.length() < 0.7:
			route_index += 1
		else:
			direction = to_point.normalized()
	var facing := (player_position - global_position) if visible_player else direction
	facing.y = 0
	if facing.length() > 0.05:
		rotation.y = lerp_angle(rotation.y, atan2(-facing.x, -facing.z), delta * 7)
	var target_speed := 2.2 if state != "patrol" else 1.3
	var target_horizontal := Vector2(direction.x, direction.z) * target_speed
	var acceleration := 14.0 if target_horizontal.length() > 0.1 else 20.0
	horizontal_velocity = horizontal_velocity.move_toward(target_horizontal, acceleration * delta)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.y
	velocity.y = -0.2 if is_on_floor() else velocity.y - delta * 20
	move_and_slide()
	stride += delta * direction.length() * 7
	model.set_motion_context(false, angle_difference(previous_yaw, rotation.y) / maxf(delta, 0.001), visible_player)
	model.animate(delta, horizontal_velocity.length())
	fire_timer -= delta
	if visible_player and distance < 26 and fire_timer <= 0:
		fire_timer = 2.0 + float(absi(guard_id.hash()) % 4) * 0.12
		shots_fired += 1
		model.fire()
		# The first shot warns; subsequent deliberate shots alternate with
		# suppression. Extra guards add pressure without six perfect hits at once.
		var aimed_hit := shots_fired % (3 if distance > 12.0 else 2) == 0
		var shot_target := player_position + Vector3.UP * 1.2
		if not aimed_hit:
			var side := (player_position - global_position).cross(Vector3.UP).normalized()
			shot_target += side * (0.8 if shots_fired % 2 == 0 else -0.8) + Vector3.UP * 0.25
		main.guard_shot(model.rifle.to_global(Vector3(0, 0.025, -0.59)), shot_target, model.rifle)
		if aimed_hit:
			main.player.take_damage(7.0 if distance > 12 else 9.0)

func can_see_player() -> bool:
	if main.linear != null and not main.linear.can_guard_act(guard_id):
		return false
	var origin := global_position + Vector3.UP * 1.45
	var target: Vector3 = main.player.global_position + Vector3.UP * 1.25
	var direction := target - origin
	if direction.length() > 28:
		return false
	if state == "patrol" and direction.length() > 4 and -global_basis.z.dot(direction.normalized()) < 0.25:
		return false
	var query := PhysicsRayQueryParameters3D.create(origin, target, 1 | 2 | 8)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == main.player

func hear_shot(location: Vector3) -> void:
	if main.linear != null and not main.linear.can_guard_act(guard_id):
		return
	if global_position.distance_to(location) < 35 and state != "dead":
		last_seen = location
		sight_memory = 6.0
		state = "search"
		path_timer = 0

func take_damage(amount: float) -> void:
	if state == "dead":
		return
	health -= amount
	model.flinch()
	hear_shot(main.player.global_position)
	if health <= 0:
		state = "dead"
		alert_audio.stream_paused = false
		alert_audio.stop()
		collision_layer = 0
		model.fall()
		main.register_guard_defeat(guard_id)
		corpse_remaining = 5.0

func encounter_snapshot() -> Dictionary:
	return {"position": [position.x, position.y, position.z], "health": health, "state": state,
		"patrol": [patrol_target.x, patrol_target.y, patrol_target.z],
		"last_seen": [last_seen.x, last_seen.y, last_seen.z], "memory": sight_memory,
		"fire_wait": clampf(fire_timer, 0.0, 3.0), "shots": shots_fired, "yaw": rotation.y}

func restore_encounter(data: Dictionary) -> void:
	position = Vector3(data.position[0], data.position[1], data.position[2])
	health = float(data.health)
	state = data.state
	patrol_target = Vector3(data.patrol[0], data.patrol[1], data.patrol[2])
	last_seen = Vector3(data.last_seen[0], data.last_seen[1], data.last_seen[2])
	sight_memory = float(data.memory)
	fire_timer = float(data.fire_wait)
	shots_fired = int(data.shots)
	rotation.y = float(data.yaw)
	path_timer = 0.0
	velocity = Vector3.ZERO
	horizontal_velocity = Vector2.ZERO
	reset_physics_interpolation()

static func valid_encounter(data: Variant) -> bool:
	if not data is Dictionary or data.get("state") not in ["patrol", "search", "combat"]:
		return false
	for key in ["position", "patrol", "last_seen"]:
		var point = data.get(key)
		if not point is Array or point.size() != 3:
			return false
		if key == "last_seen" and _valid_number(point[0], 0, 0) and _valid_number(point[1], 0, 0) and _valid_number(point[2], 0, 0):
			continue
		var camp_point: bool = preload("res://scripts/first_level_layout.gd").contains(Vector3(point[0],point[1],point[2])) if point.all(func(v): return v is int or v is float) else false
		var village_point: bool = preload("res://scripts/village_world.gd").contains(Vector3(point[0],point[1],point[2])) if point.all(func(v): return v is int or v is float) else false
		if not camp_point and not village_point:
			return false
	if not _valid_number(data.get("health"), 0.1, 75) or not _valid_number(data.get("memory"), 0, 6) or not _valid_number(data.get("fire_wait"), 0, 3):
		return false
	return _valid_number(data.get("yaw"), -100000, 100000) and _valid_number(data.get("shots"), 0, 1000000) and float(data.shots) == floorf(float(data.shots))

static func _valid_number(value: Variant, minimum: float, maximum: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= minimum and float(value) <= maximum

func _build_model() -> void:
	model = Human.new()
	model.build("guard")
	add_child(model)

func role_profile() -> Dictionary:
	return {"role": "guard", "patrol_speed": 1.3, "combat_speed": 2.2, "rifle": true, "cover_behavior": "patrol_to_last_seen"}

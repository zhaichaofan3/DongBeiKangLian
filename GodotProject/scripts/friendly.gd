extends CharacterBody3D

const Human = preload("res://scripts/human_model.gd")
var main: Node3D
var person_id := ""
var display_name := ""
var role := ""
var following := false
var treated := false
var model: Node3D
var route := PackedVector3Array()
var route_index := 0
var route_clock := 0.0
var horizontal_velocity := Vector2.ZERO
var nameplate: Label3D

func initialize(owner_node: Node3D, identifier: String, title: String, role: String, at: Vector3) -> void:
	main = owner_node
	person_id = identifier
	display_name = title
	self.role = role
	position = at
	collision_layer = 8
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.31
	capsule.height = 1.72
	shape.shape = capsule
	shape.position.y = 0.86
	add_child(shape)
	model = Human.new()
	model.build(role)
	add_child(model)
	nameplate = Label3D.new()
	nameplate.text = title
	nameplate.font_size = 36
	nameplate.pixel_size = 0.004
	nameplate.position.y = 2.04
	nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	nameplate.modulate = Color("d5dfb7")
	add_child(nameplate)

func _physics_process(delta: float) -> void:
	var previous_yaw := rotation.y
	var talking: bool = main.mode == "dialogue" and main.story.speaker_id == person_id
	nameplate.visible = main.player.position.distance_to(position) < 9 and main.mode == "playing"
	if main.mode != "playing":
		if talking:
			var facing: Vector3 = main.player.position - position
			rotation.y = lerp_angle(rotation.y, atan2(-facing.x, -facing.z), minf(1.0, delta * 9))
		model.set_motion_context(treated, angle_difference(previous_yaw, rotation.y) / maxf(delta, 0.001))
		model.animate(delta, 0, talking)
		return
	var direction := Vector3.ZERO
	var covering: bool = person_id == "scout" and is_instance_valid(main.village) and main.village.entered and main.village.ally_wait > 1.25
	var distance: float = position.distance_to(main.player.position)
	if following and distance > 2.2 and not covering:
		route_clock -= delta
		if route_clock <= 0:
			route = main.world.path(position, main.player.position)
			route_index = 1 if route.size() > 1 else 0
			route_clock = 0.5
		if route_index < route.size():
			var offset := route[route_index] - position
			offset.y = 0
			if offset.length() < 0.45:
				route_index += 1
			else:
				direction = offset.normalized()
	var speed := _movement_speed()
	var target_horizontal := Vector2(direction.x, direction.z) * speed
	var acceleration := 16.0 if target_horizontal.length() > 0.1 else 22.0
	horizontal_velocity = horizontal_velocity.move_toward(target_horizontal, acceleration * delta)
	velocity.x = horizontal_velocity.x
	velocity.z = horizontal_velocity.y
	velocity.y = -0.2 if is_on_floor() else velocity.y - 20 * delta
	move_and_slide()
	var facing := direction
	if covering: facing = main.village.ally_target - position
	if not covering and distance < 4 and direction.length() < 0.1:
		facing = main.player.position - position
	if facing.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-facing.x, -facing.z), delta * 4)
	model.set_motion_context(treated, angle_difference(previous_yaw, rotation.y) / maxf(delta, 0.001), covering)
	model.animate(delta, horizontal_velocity.length())

func _movement_speed() -> float:
	match role:
		"scout": return 2.8 if treated else 2.4
		"logger": return 2.3 if treated else 2.0
		"wounded": return 2.7 if treated else 1.8
	return 2.2

func role_profile() -> Dictionary:
	return {"role": role, "treated": treated, "speed": _movement_speed(), "injured": role == "wounded" and not treated}

func reset(at: Vector3) -> void:
	if person_id == "scout": model.set_armed(false)
	position = at
	velocity = Vector3.ZERO
	horizontal_velocity = Vector2.ZERO
	following = false
	treated = false
	route.clear()
	route_clock = 0
	reset_physics_interpolation()

extends SceneTree
## Exercises the real player's inputs, timers and model transforms in gameplay.
## Optional images: FENGHUO_MOTION_CAPTURE_DIR; extra bounded sequence: FENGHUO_MOTION_SEQUENCE=1.

var main: Node3D
var failures: Array[String] = []
var checks := 0
var capture_dir := ""
var sequence := false
var temporary_save := ""
var temporary_settings := ""
var sampling_bolt := false
var bolt_samples := [0, 0, 0, 0]
var bolt_contact_errors := [0.0, 0.0, 0.0, 0.0]
var previous_bolt_position := 0.0
var previous_bolt_rotation := 0.0
var highest_knob := 0.01
var lowest_knob := 0.01
var support_drift := 0.0
var support_twist := 0.0
var sightline_sleeve_vertices := 0

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		printerr("Refusing visual motion verification without --qa: player saves must stay untouched.")
		quit(2)
		return
	if "--capture" in OS.get_cmdline_user_args():
		printerr("Use FENGHUO_MOTION_CAPTURE_DIR instead of --capture for this isolated test.")
		quit(2)
		return
	temporary_save = "user://motion_qinglan_%d.json" % OS.get_process_id()
	temporary_settings = "user://motion_presentation_%d.cfg" % OS.get_process_id()
	capture_dir = OS.get_environment("FENGHUO_MOTION_CAPTURE_DIR")
	sequence = OS.get_environment("FENGHUO_MOTION_SEQUENCE") == "1"
	process_frame.connect(_sample_bolt_cycle)
	_run.call_deferred()

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", description)
	else:
		failures.append(description)
		push_error(description)

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	main.save_path = temporary_save
	root.add_child(main)
	await process_frame
	main.presentation.settings_path = temporary_settings
	main.start_new()
	# Only the encounter setup is controlled. Player physics, process animations,
	# ammunition and action timers continue to run normally throughout the test.
	for guard in main.guards:
		guard.set_physics_process(false)
	main.player.position = Vector3(16, 0.08, 278)
	main.player.rotation.y = -0.4
	main.player.pitch = -0.035
	main.player.reset_physics_interpolation()
	await _seconds(0.65)
	check(main.mode == "playing" and main.player.is_on_floor(), "Motion scene starts in normal playable grounded state")
	check(main.save_path == temporary_save and main.save_path != main.SAVE_PATH, "Motion verification writes only its own temporary checkpoint")
	check(main.player.weapon_index == 0 and main.player.models[0].visible, "Rifle begins as the visible active weapon")
	await _capture("rifle")

	# Hold the actual aim input, observe an intermediate value, then convergence.
	var hip_fov: float = main.player.camera.fov
	var hip_position: Vector3 = main.player.model.position
	Input.action_press("aim")
	await _seconds(0.10)
	check(main.player.aiming and main.player.aim_blend > 0.10 and main.player.aim_blend < 0.98, "Aim transitions through an intermediate blend")
	check(main.player.camera.fov < hip_fov and main.player.camera.fov > 54.0, "Aim changes FOV smoothly without an immediate jump")
	await _seconds(0.65)
	check(main.player.aim_blend > 0.995 and absf(main.player.camera.fov - 54.0) < 0.15, "Held aim converges to the intended FOV")
	check(absf(main.player.model.position.x) < 0.012 and main.player.model.position.distance_to(hip_position) > 0.15, "Aim brings the weapon sights onto the camera centerline")
	await _capture("aim")
	Input.action_release("aim")
	await _seconds(0.65)
	check(not main.player.aiming and main.player.aim_blend < 0.005 and absf(main.player.camera.fov - hip_fov) < 0.15, "Releasing aim restores the hip view")

	var rifle: Dictionary = main.player.weapon_rigs[0]
	var rifle_rest: Dictionary = main.player.hand_rest[0]
	var rifle_ammo: int = main.player.magazines[0]
	var rifle_reserve: int = main.player.reserves[0]
	Input.action_press("aim")
	await _seconds(0.65)
	var aimed_position: Vector3 = main.player.model.position
	sampling_bolt = true
	await _tap("fire")
	check(main.player.magazines[0] == rifle_ammo - 1, "Rifle input fires exactly one real round")
	check(main.player.flash_time > 0.0 and main.player.view_kick > 0.0, "Firing starts a brief muzzle flash and view-model recoil")
	await _seconds(0.20)
	await _sequence_capture("bolt_01_lift")
	await _seconds(0.18)
	check(rifle.bolt.position.z > 0.04 and absf(rifle.bolt.rotation.z) > 0.2, "Rifle shot physically lifts and retracts the bolt")
	check(rifle.right.position.distance_to(rifle_rest.right_position) > 0.055, "Firing hand leaves the grip to operate the bolt")
	var hand_skeleton: Skeleton3D = rifle.right.skeleton
	var middle_bone := hand_skeleton.find_bone("f_middle_03_R")
	var thumb_bone := hand_skeleton.find_bone("thumb_03_R")
	check(middle_bone >= 0 and thumb_bone >= 0, "The firing hand has bound middle and thumb joints")
	if middle_bone >= 0 and thumb_bone >= 0:
		var finger_center: Vector3 = hand_skeleton.to_global((hand_skeleton.get_bone_global_pose(middle_bone).origin + hand_skeleton.get_bone_global_pose(thumb_bone).origin) * 0.5)
		var knob_center: Vector3 = rifle.bolt.to_global(rifle.get("bolt_contact", Vector3(0.078, 0.01, 0.035)))
		check(finger_center.distance_to(knob_center) < 0.025, "Curled finger joints stay around the bolt knob while it is open")
	await _sequence_capture("bolt_02_open")
	await _seconds(0.25)
	await _sequence_capture("bolt_03_return")
	await _seconds(0.40)
	sampling_bolt = false
	check(sightline_sleeve_vertices == 0, "Cycling the supplied bolt keeps sleeves outside the central sight line")
	var contact_valid := true
	for phase in 4:
		contact_valid = contact_valid and bolt_samples[phase] >= 2 and bolt_contact_errors[phase] < 0.025
	check(contact_valid, "Fingers stay within 2.5 cm of the knob throughout lift, pull, push and lock")
	check(highest_knob > 0.05 and lowest_knob >= 0.008, "Bolt handle rises above its closed position instead of rotating underneath the rifle")
	check(support_drift < 0.006 and support_twist < 0.02, "Support hand stays planted on the fore-end throughout the bolt cycle")
	print("BOLT CONTACT: samples=", bolt_samples, ", max_error_m=", bolt_contact_errors, ", support_drift_m=", support_drift)
	check(rifle.bolt.position.length() < 0.001 and rifle.bolt.rotation.length() < 0.001, "Bolt returns fully to battery after the cycle")
	check(rifle.right.position.distance_to(rifle_rest.right_position) < 0.01, "Firing hand returns to its grip")
	check(not main.player.muzzle_flash.visible and main.player.muzzle_light.light_energy < 0.01 and main.player.view_kick < 0.001, "Flash and recoil decay after the shot")
	check(_aim_recovered(aimed_position), "Held aim recovers its sight alignment after firing and operating the bolt")

	await _tap("reload")
	check(main.player.reload_timer > 0.0 and main.player.magazines[0] == rifle_ammo - 1, "Rifle reload starts without granting ammunition early")
	await _seconds(0.30)
	await _sequence_capture("reload_01_open")
	await _seconds(0.32)
	await _sequence_capture("reload_02_present")
	await _seconds(0.32)
	check(rifle.clip.visible and rifle.bolt.position.z > 0.04, "Mid-reload clip is visible over the open receiver")
	check(rifle.left.position.distance_to(rifle_rest.left_position) > 0.12, "Support hand reaches the receiver during loading")
	check(rifle.clip.position.y > 0.04 and rifle.clip.position.y < 0.15, "Clip has moved down along its insertion path")
	await _capture("reload")
	await _seconds(1.40)
	check(main.player.reload_timer <= 0.0 and main.player.magazines[0] == rifle_ammo and main.player.reserves[0] == rifle_reserve - 1, "Rifle reload completes with the correct magazine and reserve transfer")
	check(not rifle.clip.visible and rifle.bolt.position.length() < 0.001 and rifle.left.position.distance_to(rifle_rest.left_position) < 0.012, "Completed reload hides the clip and restores the hand and bolt")
	check(_aim_recovered(aimed_position), "Held aim recovers its sight alignment after reloading")
	Input.action_release("aim")

	await _tap("weapon_2")
	check(main.player.weapon_index == 1 and main.player.models[1].visible and not main.player.models[0].visible, "Weapon key switches visibility to the pistol")
	check(main.player.switch_age < 0.20, "Weapon switch begins its timed visual transition")
	await _seconds(0.65)
	check(main.player.switch_age > 0.5 and main.player.model.position.y > -0.27, "Switched pistol rises into its held position")
	await _capture("pistol")
	var pistol: Dictionary = main.player.weapon_rigs[1]
	var pistol_rest: Dictionary = main.player.hand_rest[1]
	var pistol_ammo: int = main.player.magazines[1]
	var pistol_reserve: int = main.player.reserves[1]
	var trigger_rest := _finger_in_weapon(pistol.right, "f_index_03_R", pistol.root)
	var trigger_start := Vector3(0, -0.016, -0.010)
	var trigger_end := Vector3(0, -0.052, -0.024)
	var trigger_surface := _nearest_index_surface(pistol.right, pistol.root, trigger_start, trigger_end)
	var guard_offset := trigger_surface - Vector3(0, -0.043, -0.021)
	var guard_radius := Vector2(guard_offset.y / 0.030, guard_offset.z / 0.028).length()
	check(_segment_distance(trigger_surface, trigger_start, trigger_end) < 0.016 and guard_radius < 1.4, "Pistol index-finger skin reaches the trigger region inside the guard outline")
	print("PISTOL TRIGGER: resting_joint=", trigger_rest, ", closest_finger_surface=", trigger_surface, ", trigger_distance_m=", _segment_distance(trigger_surface, trigger_start, trigger_end))
	await _tap("fire")
	await _seconds(0.02)
	var trigger_pressed := _finger_in_weapon(pistol.right, "f_index_03_R", pistol.root)
	check(main.player.magazines[1] == pistol_ammo - 1 and pistol.bolt.position.z > 0.001, "Pistol shot consumes a round and cycles its bolt")
	await _seconds(0.30)
	check(pistol.bolt.position.length() < 0.001, "Pistol bolt returns after cycling")
	check(trigger_pressed.distance_to(trigger_rest) > 0.0005 and trigger_pressed.distance_to(trigger_rest) < 0.018 and _finger_in_weapon(pistol.right, "f_index_03_R", pistol.root).distance_to(trigger_rest) < 0.002, "Pistol trigger finger visibly pulls and returns to its held grip")
	await _tap("reload")
	await _seconds(0.65)
	check(pistol.clip.visible and pistol.left.position.distance_to(pistol_rest.left_position) > 0.10, "Pistol reload uses a visible clip and a separate loading hand")
	await _sequence_capture("pistol_reload")
	await _seconds(1.10)
	check(main.player.reload_timer <= 0.0 and main.player.magazines[1] == pistol_ammo and main.player.reserves[1] == pistol_reserve - 1, "Pistol reload completes with correct ammunition transfer")
	check(not pistol.clip.visible and pistol.left.position.distance_to(pistol_rest.left_position) < 0.012, "Pistol loading hand and clip return to normal")

	# Restore uses a genuine earlier snapshot, never fabricated animation values.
	var saved: Dictionary = main.player.snapshot()
	await _tap("fire")
	check(main.player.flash_time > 0.0 and main.player.view_kick > 0.0, "Restore test begins while shot effects are active")
	main.player.restore(saved)
	check(main.player.flash_time == 0.0 and main.player.view_kick == 0.0 and not main.player.muzzle_flash.visible and main.player.muzzle_light.light_energy == 0.0, "Restore immediately cancels an unfinished shot effect")
	await _tap("fire")
	await _seconds(0.30)
	await _tap("reload")
	await _seconds(0.60)
	check(main.player.reload_timer > 0.0 and pistol.clip.visible, "Restore test begins during a real unfinished reload")
	var cancelled_reload_remaining: float = main.player.reload_timer
	main.player.restore(saved)
	check(main.player.reload_timer == 0.0 and main.player.magazines[1] == saved.magazines[1] and main.player.reserves[1] == saved.reserves[1], "Restore cancels loading and restores snapshot ammunition")
	var reset_models := true
	for i in main.player.weapon_rigs.size():
		var rig: Dictionary = main.player.weapon_rigs[i]
		var rest: Dictionary = main.player.hand_rest[i]
		reset_models = reset_models and not rig.clip.visible and rig.bolt.position.length() < 0.001 and rig.bolt.rotation.length() < 0.001
		reset_models = reset_models and rig.left.position.distance_to(rest.left_position) < 0.001 and rig.right.position.distance_to(rest.right_position) < 0.001
	check(reset_models, "Restore resets all weapon mechanisms and hands")
	await _seconds(cancelled_reload_remaining + 0.15)
	check(main.mode == "playing" and main.player.magazines[1] == saved.magazines[1] and main.player.reserves[1] == saved.reserves[1], "Cancelled reload cannot grant ammunition later")

	# Leave a real rifle loading action unfinished, then restore while it is hidden.
	# The wait crosses its original completion time to detect delayed ammo grants.
	await _tap("weapon_1")
	await _seconds(0.35)
	await _tap("fire")
	await _seconds(0.30)
	await _tap("reload")
	await _seconds(0.65)
	check(main.player.reload_timer > 0.0 and rifle.clip.visible and rifle.bolt.position.z > 0.04, "Weapon-switch test begins during real rifle loading")
	cancelled_reload_remaining = main.player.reload_timer
	var interrupted_ammo: int = main.player.magazines[0]
	var interrupted_reserve: int = main.player.reserves[0]
	await _tap("weapon_2")
	check(main.player.weapon_index == 1 and not main.player.models[0].visible and main.player.reload_timer == 0.0, "Switching away cancels loading and hides the rifle")
	await _seconds(cancelled_reload_remaining + 0.15)
	check(main.player.magazines[0] == interrupted_ammo and main.player.reserves[0] == interrupted_reserve, "Switched-away reload cannot grant ammunition later")
	main.player.restore(saved)
	check(not rifle.clip.visible and rifle.bolt.position.length() < 0.001 and rifle.bolt.rotation.length() < 0.001 and rifle.left.position.distance_to(rifle_rest.left_position) < 0.001 and rifle.right.position.distance_to(rifle_rest.right_position) < 0.001, "Restore resets the hidden rifle after its interrupted loading action")
	check(main.player.weapon_index == saved.weapon and main.player.magazines == saved.magazines and main.player.reserves == saved.reserves, "Restore recovers both weapons' ammunition after a cancelled switch reload")
	await _finish()

func _sample_bolt_cycle() -> void:
	if not sampling_bolt or not is_instance_valid(main):
		return
	var rig: Dictionary = main.player.weapon_rigs[0]
	var rest: Dictionary = main.player.hand_rest[0]
	var age: float = main.player.visual_fire_age
	var pull_delta: float = rig.bolt.position.z - previous_bolt_position
	var lift_delta: float = rig.bolt.rotation.z - previous_bolt_rotation
	previous_bolt_position = rig.bolt.position.z
	previous_bolt_rotation = rig.bolt.rotation.z
	# Exclude only reaching/releasing the knob. Classify the four operating
	# phases from actual mechanical movement, not the animation's envelopes.
	if age < 0.15 or age > 0.75:
		return
	var camera: Camera3D = main.player.camera
	var viewport_size := Vector2(root.size)
	for point: Vector3 in rig.right.sleeve.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		var global_point: Vector3 = rig.right.sleeve.to_global(point)
		if camera.to_local(global_point).z > -camera.near: continue
		var screen_point := camera.unproject_position(global_point) / viewport_size
		if absf(screen_point.x - .5) < .06 and absf(screen_point.y - .5) < .09:
			sightline_sleeve_vertices += 1
	var phase := -1
	if pull_delta > 0.00001:
		phase = 1
	elif pull_delta < -0.00001:
		phase = 2
	elif lift_delta > 0.0001:
		phase = 0
	elif lift_delta < -0.0001:
		phase = 3
	var middle := _finger_in_weapon(rig.right, "f_middle_03_R", rig.root)
	var thumb := _finger_in_weapon(rig.right, "thumb_03_R", rig.root)
	var knob: Vector3 = rig.bolt.transform * rig.get("bolt_contact", Vector3(0.078, 0.01, 0.035))
	if phase >= 0:
		bolt_samples[phase] += 1
		bolt_contact_errors[phase] = maxf(bolt_contact_errors[phase], ((middle + thumb) * 0.5).distance_to(knob))
	highest_knob = maxf(highest_knob, knob.y)
	lowest_knob = minf(lowest_knob, knob.y)
	support_drift = maxf(support_drift, rig.left.position.distance_to(rest.left_position))
	support_twist = maxf(support_twist, rig.left.quaternion.angle_to(Quaternion.from_euler(rest.left_rotation)))

func _finger_in_weapon(hand: Node3D, bone_name: String, weapon: Node3D) -> Vector3:
	var skeleton: Skeleton3D = hand.skeleton
	skeleton.force_update_all_bone_transforms()
	var bone := skeleton.find_bone(bone_name)
	if bone < 0:
		return Vector3(INF, INF, INF)
	return weapon.to_local(skeleton.to_global(skeleton.get_bone_global_pose(bone).origin))

func _segment_distance(point: Vector3, start: Vector3, end: Vector3) -> float:
	var direction := end - start
	var along := clampf((point - start).dot(direction) / direction.length_squared(), 0.0, 1.0)
	return point.distance_to(start + direction * along)

func _nearest_index_surface(hand: Node3D, weapon: Node3D, start: Vector3, end: Vector3) -> Vector3:
	# A distal bone's origin is the knuckle, not the fingertip. Measure the
	# actual skinned final index-finger segment against the authored trigger.
	var closest := Vector3(INF, INF, INF)
	var closest_distance := INF
	for instance in hand.find_children("*", "MeshInstance3D", true, false):
		if instance.skin == null or instance.mesh == null:
			continue
		var skeleton := instance.get_node_or_null(instance.skeleton) as Skeleton3D
		if skeleton == null:
			continue
		skeleton.force_update_all_bone_transforms()
		var index_bone := skeleton.find_bone("f_index_03_R")
		var transforms: Array[Transform3D] = []
		var index_bindings: Array[int] = []
		for binding in instance.skin.get_bind_count():
			var bind_name: StringName = instance.skin.get_bind_name(binding)
			var bone: int = skeleton.find_bone(bind_name) if not bind_name.is_empty() else instance.skin.get_bind_bone(binding)
			transforms.append(weapon.global_transform.affine_inverse() * skeleton.global_transform * skeleton.get_bone_global_pose(bone) * instance.skin.get_bind_pose(binding))
			if bone == index_bone:
				index_bindings.append(binding)
		for surface in instance.mesh.get_surface_count():
			var arrays: Array = instance.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var influences: int = weights.size() / maxi(1, vertices.size())
			for vertex in vertices.size():
				var index_weight := 0.0
				for slot in influences:
					var offset := vertex * influences + slot
					if indices[offset] in index_bindings:
						index_weight += weights[offset]
				if index_weight < 0.5:
					continue
				var point := Vector3.ZERO
				for slot in influences:
					var offset := vertex * influences + slot
					point += (transforms[indices[offset]] * vertices[vertex]) * weights[offset]
				var distance := _segment_distance(point, start, end)
				if distance < closest_distance:
					closest = point
					closest_distance = distance
	return closest

func _aim_recovered(at: Vector3) -> bool:
	return main.player.aiming and main.player.aim_blend > 0.995 and absf(main.player.camera.fov - 54.0) < 0.15 and main.player.model.position.distance_to(at) < 0.01 and main.player.model.rotation.length() < 0.025

func _tap(action: String) -> void:
	var pressed := InputEventAction.new()
	pressed.action = action
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await physics_frame
	await process_frame
	var released := InputEventAction.new()
	released.action = action
	released.pressed = false
	Input.parse_input_event(released)

func _seconds(duration: float) -> void:
	await create_timer(duration).timeout
	await process_frame

func _sequence_capture(label: String) -> void:
	if sequence:
		await _capture(label)

func _capture(label: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name() == "headless":
		return
	var directory_error := DirAccess.make_dir_recursive_absolute(capture_dir)
	if directory_error != OK:
		check(false, "Capture directory can be created: " + capture_dir)
		return
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	var output := capture_dir.path_join(label + ".png")
	check(not screenshot.is_empty() and screenshot.save_png(output) == OK, "Motion image saved: " + label)

func _finish() -> void:
	for action in ["aim", "fire", "reload", "weapon_1", "weapon_2", "move_forward", "move_back", "move_left", "move_right", "sprint"]:
		Input.action_release(action)
	main.mode = "paused"
	main.player.sound.stop()
	main.player.footsteps.stop()
	main.enemy_audio.stop()
	main.ambience.stop()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_save))
	if FileAccess.file_exists(temporary_settings):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_settings))
	check(not FileAccess.file_exists(temporary_save), "Motion verification removes its temporary checkpoint")
	main.queue_free()
	await process_frame
	print("VISUAL MOTION RESULT: ", checks - failures.size(), "/", checks, " passed")
	quit(0 if failures.is_empty() else 1)

extends SceneTree

var main: Node3D
var checks: Array[Dictionary] = []
var metrics: Dictionary = {}
var output := OS.get_environment("FENGHUO_POLISH_EVIDENCE")
var rendered := DisplayServer.get_name() != "headless"

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args() or output.is_empty(): quit(2); return
	_run.call_deferred()

func check(ok: bool, label: String) -> void:
	checks.append({"passed":ok,"description":label})
	print("PASS: " if ok else "FAIL: ", label)

func frames(count: int = 4) -> void:
	for i in count: await process_frame

func freeze() -> void:
	main.set_process(false)
	main.player.set_physics_process(false)
	main.melee.set_process(false)
	main.hud.set_process(false)
	if is_instance_valid(main.opening): main.opening.set_process(false)
	for guard in main.guards: guard.set_physics_process(false)

func capture(label: String) -> void:
	if not rendered: return
	await frames()
	await RenderingServer.frame_post_draw
	var raster := root.get_texture().get_image()
	var colors: Dictionary = {}
	for y in range(30, raster.get_height() - 30, 13):
		for x in range(30, raster.get_width() - 30, 13):
			var c := raster.get_pixel(x,y)
			colors[Vector3i(int(c.r * 32), int(c.g * 32), int(c.b * 32))] = true
	check(colors.size() > 40 and raster.save_png(output.path_join(label + ".png")) == OK, label + " renders a nonblank frame")

func drag(slider: HSlider, fraction: float) -> void:
	var rect := slider.get_global_rect()
	var start := Vector2(rect.position.x + rect.size.x * 0.3, rect.get_center().y)
	var end := Vector2(rect.position.x + rect.size.x * fraction, start.y)
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = start
	root.push_input(down, true)
	for i in range(1, 9):
		var motion := InputEventMouseMotion.new()
		motion.position = start.lerp(end, i / 8.0)
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		root.push_input(motion, true)
		await frames(1)
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.position = end
	root.push_input(up, true)
	await frames()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await frames()
	main.save_path = "user://polish_%d.json" % OS.get_process_id()
	main.presentation.settings_path = "user://polish_%d.cfg" % OS.get_process_id()
	freeze()
	for id in ["scout", "lu", "logger"]:
		var person = main.story.people[id]
		var star: MeshInstance3D = person.model.find_child("FriendlyCapStar", true, false)
		check(star != null and star.visible == (id != "logger"), "Cap star has correct faction visibility: " + id)
		if star != null:
			check(star.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() == 30, "Cap insignia is a five-point star: " + id)
	var enemy_star: Node3D = main.guards[0].model.find_child("FriendlyCapStar",true,false)
	check(enemy_star == null or not enemy_star.visible, "Enemy headgear never displays the friendly star")
	main.start_with_opening()
	freeze()
	main.hud.visible = false
	var opening = main.opening
	for id in ["ally1", "ally2", "scout"]:
		check(opening.actors[id].find_child("FriendlyCapStar",true,false).visible, "Opening friendly wears the red star: " + id)
		check(opening.actors[id].detailed_rig.character.scene_file_path.ends_with("volunteer.glb"), "Opening friendly uses the supplied friendly model: " + id)
	for second in [3.1, 11.0, 18.5, 48.8, 76.0]:
		opening.preview_at("B", second)
		check((-opening.hands.basis.z).y < -0.6, "Conversation muzzle points down at %.1f seconds" % second)
	opening.preview_at("B", 11)
	await capture("conversation-low-ready")
	var scout = opening.actors.scout
	opening.hands.visible = false
	opening.camera.position = scout.to_global(Vector3(0.55,1.70,-1.15))
	opening.camera.look_at(scout.position + Vector3(0,1.65,0))
	opening.camera.fov = 35
	await capture("friendly-cap-star")
	var before: Dictionary = main._snapshot()
	var walk_ok := true
	var camera_start := Vector3.ZERO
	for i in 51:
		opening.preview_at("A", 27.74 + i * 0.099)
		if i == 0: camera_start = opening.camera.position
		for id in ["ally1", "ally2"]:
			var actor = opening.actors[id]
			walk_ok = walk_ok and actor.position.x > 47 and actor.position.x < 56 and actor.position.z >= 38 and is_equal_approx(actor.position.y, 0.08)
			walk_ok = walk_ok and absf(actor.chest.rotation.z) < 0.08
		if i in [0,25,50]: await capture("office-walk-%02d" % i)
	check(walk_ok and opening.camera.position.distance_to(camera_start) > 4, "Office replaces paired rescue with walking actors and a continuous camera move")
	var office_shot: Dictionary = opening.shot
	for actor in office_shot.actors:
		check(main.world._path_segment_clear(opening._v(actor.start), opening._v(actor.end)), "Office walk clears furniture: " + str(actor.id))
	check(main._snapshot().story == before.story and main.kills == before.kills and main.player.snapshot() == before.player, "Office showcase leaves mission state and player resources unchanged")
	opening.preview_at("A", 34)
	check(not opening.office_showcase_lights.visible, "Interior showcase lights deactivate after the shot")
	main.start_new()
	freeze()
	main.story.show_dialog("scout", "姜岚", "检查", [{"label":"继续","action":"close"}])
	check(main.player.model.visible and (-main.player.model.basis.z).y < -0.6, "Gameplay conversations display the same safe weapon posture")
	main.story.close_dialog()
	for i in 90: main.player._process(1.0 / 60.0)
	check(main.player.model.rotation.distance_to(main.player.WeaponVisuals.HIP_ROTATION) < 0.03, "Combat hold restores smoothly after a conversation")
	main.player.position = main.melee.PLAYER_MARK
	var ambusher: CharacterBody3D
	for guard in main.guards:
		if guard.guard_id == "door_ambusher": ambusher = guard
	var max_reach := 0.0
	var visible_samples := 0
	var early_hidden := true
	var grip_gap := 0.0
	for distance in [3.0, 7.0, 12.0]:
		ambusher.position = main.melee.PLAYER_MARK + Vector3(0,0,-distance)
		main.melee.begin("door")
		main.melee._process(main.melee.TURN_TIME)
		for i in range(1,101):
			main.melee.clock = main.melee.charge_seconds * i / 100.0
			main.melee._process(0)
			for hand in main.melee.hands:
				if ambusher.position.distance_to(main.melee.player_mark) > 1.75: early_hidden = early_hidden and not hand.visible
				if hand.visible:
					visible_samples += 1
					max_reach = maxf(max_reach, hand.position.distance_to(hand.sleeve_endpoint))
		main.melee._process(0.05)
		check(main.melee.hands.all(func(hand): return hand.visible), "Both hands reach the final grapple after %.0fm charge" % distance)
		if distance == 12: await capture("bayonet-grapple")
		for i in 2:
			var grip := Vector3(0, -0.075 if i == 0 else -0.035, 0.15 if i == 0 else -0.38)
			var hand = main.melee.hands[i]
			grip_gap = maxf(grip_gap, (hand.position + hand.basis.y * 0.065).distance_to(main.melee.camera.to_local(ambusher.model.rifle.to_global(grip))))
		main.melee._phase("counter")
		for i in 40:
			main.melee._process(0.02)
			for hand in main.melee.hands:
				if hand.visible: max_reach = maxf(max_reach, hand.position.distance_to(hand.sleeve_endpoint))
		if distance == 12: await capture("bayonet-counter")
		main.melee.abort()
	check(early_hidden and visible_samples > 0 and max_reach <= main.melee.MAX_ARM_REACH + 0.01, "Long and short charges never stretch visible sleeves beyond the arm budget")
	check(grip_gap < 0.10, "Both hands meet the rifle within ten centimetres in the grapple")
	metrics = {"max_visible_arm_m":max_reach,"grapple_grip_gap_m":grip_gap,"visible_arm_samples":visible_samples}
	main.return_to_menu()
	main.hud.visible = true
	main.hud.show_menu(main.mode)
	main.hud._show_settings()
	await frames()
	if rendered:
		var prefs = main.presentation
		var window_size := DisplayServer.window_get_size()
		var window_position := DisplayServer.window_get_position()
		# Reproduce an external/native fullscreen change while the cached value is false.
		prefs.fullscreen = false
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		await frames(12)
		var fullscreen_size := DisplayServer.window_get_size()
		for name in ["MasterVolume", "MusicVolume", "SfxVolume", "DialogueVolume", "CinematicVolume"]:
			var slider: HSlider = main.hud.settings_panel.find_child(name,true,false)
			var old_value := slider.value
			await drag(slider, 0.41 if old_value > 0.5 else 0.72)
			check(absf(slider.value-old_value) > 0.03 and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN and DisplayServer.window_get_size() == fullscreen_size, "Actual slider drag changes volume and preserves fullscreen: " + name)
		await capture("fullscreen-volume-drag")
		prefs.change("sensitivity", .0023)
		prefs.change("motion", .3)
		prefs.change("fps_limit", 120)
		prefs.change("show_stats", true)
		check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN and prefs.fullscreen, "Other settings retain native fullscreen and synchronize the saved preference")
		prefs.change("fullscreen", false)
		await frames(12)
		check(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED and DisplayServer.window_get_size() == window_size and DisplayServer.window_get_position().distance_to(window_position) < 5, "Explicitly leaving fullscreen restores the original window geometry")
		var saved = load("res://scripts/presentation.gd").new()
		saved.settings_path = prefs.settings_path
		saved.load_preferences()
		check(not saved.fullscreen and is_equal_approx(saved.music_volume,prefs.music_volume), "Window mode and dragged volumes reload correctly")
	var passed := checks.all(func(item): return item.passed)
	FileAccess.open(output.path_join("validation.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"count":checks.size(),"checks":checks,"metrics":metrics,"rendered":rendered,"resolution":str(root.size)},"  "))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.presentation.settings_path))
	main.audio_mix.reset_transients()
	main.queue_free()
	await frames()
	print("POLISH REVISION: ", "PASS" if passed else "FAIL", " | checks=",checks.size())
	quit(0 if passed else 1)

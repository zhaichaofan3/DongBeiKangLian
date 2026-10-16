extends SceneTree

const Weapons = preload("res://scripts/weapon_visuals.gd")

var main: Node3D
var checks := 0
var failures: Array[String] = []
var output := OS.get_environment("FENGHUO_REVISION_EVIDENCE")
var rendered := DisplayServer.get_name() != "headless"

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	if value: print("PASS: ", label)
	else: failures.append(label); printerr("FAIL: ", label)

func frames(count: int) -> void:
	for i in count:
		for guard in main.guards:
			if is_instance_valid(guard): guard.set_physics_process(false)
		await process_frame

func shot(label: String) -> void:
	if not rendered or output.is_empty(): return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))

func kill(id: String) -> void:
	for guard in main.guards:
		if is_instance_valid(guard) and guard.guard_id == id: guard.take_damage(1000); return

func _run() -> void:
	if output.is_empty(): output = ProjectSettings.globalize_path("res://revision-evidence")
	DirAccess.make_dir_recursive_absolute(output)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await frames(4)
	check(ProjectSettings.get_setting("application/config/name") == "东北抗联-烽火回声", "New game title in application and menu")
	check(main.hud.menu_title.text == "东北抗联-烽火回声" and main.menu_camera.current, "Title menu uses the scenic camera")
	await shot("01-title")
	main.hud._show_settings()
	await frames(2)
	await shot("02-settings")
	main.hud.show_menu("briefing")
	main.start_new()
	main.set_process(false)
	main.player.set_physics_process(false)
	check(main.alive_guard_count() == 13, "Thirteen guards: 3 checkpoint, 4 timber, 4 office, 1 door ambusher, 1 pier")
	for id in ["scout", "lu"]:
		var cloth := coat_materials(main.story.people[id].model)
		check(cloth.size() >= 3 and cloth.all(material_is_grey), "Friendly coat is grey: " + id)
	check(Weapons.materials.cloth.albedo_color == Color("7c8083") and Weapons.materials.cuff.albedo_color == Color("505559"), "First-person sleeves and cuffs share the grey uniform palette")
	var paths_ok := true
	main.linear.set_enabled(false)
	for guard in main.guards:
		if main.world.path(guard.position, guard.patrol_target).is_empty():
			print("BLOCKED PATROL: ", guard.guard_id)
			paths_ok = false
	check(paths_ok, "Every new patrol has a traversable path")
	main.linear.reset()
	main.story.met_scout = true
	kill("gate_guard")
	check(not main.linear.gate_ready("checkpoint"), "Added checkpoint guards must also be defeated")
	kill("gate_guard_2"); kill("gate_guard_3")
	check(main.linear.gate_ready("checkpoint"), "All three checkpoint guards unlock first gate")
	main.linear.opened.assign(["checkpoint"])
	kill("yard_guard"); kill("timber_guard")
	check(not main.linear.gate_ready("yard"), "Added timber guards must also be defeated")
	kill("yard_guard_2"); kill("yard_guard_3")
	check(main.linear.gate_ready("yard"), "All four timber guards unlock second gate")
	main.player.position = Vector3(34, 0.08, 124)
	main.linear._sync_gates()
	main.interact()
	check("yard" in main.linear.opened and main.melee.active and main.melee.enemy.guard_id == "door_ambusher", "Second gate retains its separate original ambush")
	for last_id in ["office_guard", "office_guard_2", "office_guard_3", "office_guard_4"]:
		main.start_new()
		main.set_process(false)
		main.player.set_physics_process(false)
		main.story.met_scout = true
		main.linear.opened.assign(["checkpoint", "yard"])
		main.linear._sync_gates()
		main.story._set_door(true)
		main.player.position = Vector3(50, 0.08, 36)
		for guard in main.guards:
			if guard.guard_id == last_id: main.player.position = guard.position + Vector3(0, 0, 3)
		for id in ["office_guard", "office_guard_2", "office_guard_3", "office_guard_4"]:
			if id == last_id: continue
			kill(id)
			if main.kills < 3: check(not main.melee.can_begin(), "No charge before three office kills")
		main._try_office_melee()
		check(main.melee.active and main.melee.enemy.guard_id == last_id, "Any last survivor charges: " + last_id)
		check(main.audio_mix.voice.stream == main.melee.SHOUT, "Reuses the supplied banzai shout")
		var saved: Dictionary = main._read_save()
		if saved.is_empty():
			var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(main.save_path))
			print("SAVE DIAGNOSTIC: ", main.story.valid(raw.story), "/", main.linear.valid_snapshot(raw.linear), "/", main._valid_encounter(raw), "/", main._valid_opening_snapshot(raw))
			for id in raw.encounter.active:
				if not main.Guard.valid_encounter(raw.encounter.active[id]): print("INVALID ACTOR: ", id, " ", raw.encounter.active[id])
		check(saved.get("kills", -1) == 3, "Pre-charge save preserves exactly three office defeats")
		if last_id == "office_guard":
			main.melee.clock = main.melee.TURN_TIME
			main.melee._process(0)
			main.melee.clock = main.melee.charge_seconds
			main.melee._process(0)
			await frames(2)
			print("GRAPPLE CAMERA: ", main.melee.camera.global_position, " ENEMY: ", main.melee.enemy.global_position, " PLAYER: ", main.player.position, " CURRENT: ", main.get_viewport().get_camera_3d().get_path())
			await shot("03-office-grapple")
			main.melee.set_paused(true)
			var clock: float = main.melee.clock
			await frames(5)
			check(main.melee.clock == clock, "Office grapple pauses without advancing")
			main.resume()
			main.melee.pressure = 1
			main.melee._phase("counter")
			main.melee._process(0.9)
			main.melee._process(1.1)
			check(main.kills == 4 and not main.melee.active, "Counterattack finishes and saves the fourth office defeat")
			main.continue_checkpoint()
			check(main.kills == 4 and not main.melee.can_begin(), "Completed office encounter does not replay after load")
		else:
			main.melee._phase("failure")
			main.melee._process(0.7)
			check(main.mode == "lost", "Failed office grapple exits cleanly")
			main.continue_checkpoint()
			check(main.kills == 3 and main.player.health > 0, "Retry restores three kills and the surviving defender")
			main._try_office_melee()
			check(main.melee.active, "Retry can replay the same office survivor")
			main.melee.abort()
	await _hold()
	_export_dialogue()
	main.player.position = Vector3(12, 0.08, 284.5)
	main.player.rotation.y = 0
	main.player.pitch = 0
	main.player.camera.rotation = Vector3.ZERO
	main.player.reset_physics_interpolation()
	main.hud.info_clock = 0
	await frames(8)
	await shot("06-grey-uniform")
	var file := FileAccess.open(output.path_join("validation.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "passed": failures.is_empty(), "rendered": rendered}, "\t"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.audio_mix.reset_transients()
	main.ambience.stop()
	main.enemy_audio.stop()
	main.player.footsteps.stop()
	main.queue_free()
	await process_frame
	await process_frame
	print("USER REVISION: ", "PASS" if failures.is_empty() else "FAIL", " ", checks - failures.size(), "/", checks)
	quit(0 if failures.is_empty() else 1)

func _hold() -> void:
	main.start_new()
	main.set_process(false)
	main.player.set_physics_process(false)
	for guard in main.guards: guard.take_damage(1000)
	main.stage = 2
	main.story.met_scout = true
	main.story.recruited = true
	main.story.people.lu.following = true
	main.story.people.lu.position = main.EVAC + Vector3(-3, 0, 0)
	main.story.people.lu.set_physics_process(false)
	main.linear.opened.assign(["checkpoint", "yard", "river"])
	main.linear._sync_gates()
	main.player.position = main.EVAC
	main.player.rotation.y = PI
	main.linear.update(0)
	check(main.linear.extraction_remaining == 30 and not main.linear.can_evacuate(), "Hold starts at thirty seconds and blocks early extraction")
	main._update_reinforcements(0)
	check(main.hold_next == 2 and main.alive_guard_count() == 2, "First pursuing pair arrives when untying starts")
	await frames(3)
	check(main.hud.hold_clock.visible and "00:30" in main.hud.hold_clock.text, "Top-left countdown displays 00:30")
	await shot("04-hold-30")
	main._update_reinforcements(10)
	check(main.hold_next == 2, "No new wave while a pursuing pair remains alive")
	kill("hold_0"); kill("hold_1")
	main._update_reinforcements(.9)
	check(main.hold_next == 2, "Next wave does not spawn before one second after clearing the pair")
	main.mode = "paused"
	main._update_reinforcements(10)
	main.linear.update(10)
	check(is_equal_approx(main.hold_wait, 0.1) and main.linear.extraction_remaining == 30, "Pause freezes both countdown and spawn delay")
	main.resume()
	main._update_reinforcements(0.11)
	check(main.hold_next == 4 and main.alive_guard_count() == 2, "Next group contains two soldiers")
	main._save_checkpoint()
	main.continue_checkpoint()
	check(main.hold_next == 4 and main.alive_guard_count() == 2, "Load restores exact pursuing soldiers without duplication")
	kill("hold_2"); kill("hold_3")
	main._update_reinforcements(1.01)
	check(main.hold_next == 6, "Pursuit continues beyond the first group")
	main.linear.update(20)
	main._save_checkpoint()
	main.continue_checkpoint()
	check(main.linear.extraction_remaining == 10, "Load preserves partially completed thirty-second hold")
	main.hud.info_clock = 0
	await frames(2)
	await shot("05-hold-10")
	main.linear.update(10)
	check(main.linear.can_evacuate(), "Thirty seconds permits joint evacuation")
	var issued: int = main.hold_next
	kill("hold_4"); kill("hold_5")
	main._update_reinforcements(20)
	check(main.hold_next == issued, "Spawning ends when the hold completes")
	main._save_checkpoint()
	main.continue_checkpoint()
	check(main.linear.can_evacuate(), "Completed hold survives reload")
	main.interact()
	main.story.choose(0)
	check(main.mode == "crossing" and main.village.crossing, "Completed ferry hold continues into the village crossing")
	var legacy: Dictionary = main.linear.snapshot()
	legacy.version = 1
	legacy.extraction_remaining = 6
	check(main.linear.valid_snapshot(legacy), "Original twelve-second extraction save remains valid")
	main.linear.restore(legacy)
	check(main.linear.extraction_remaining == 15, "Half-completed old hold migrates to half of thirty seconds")
	legacy.extraction_remaining = 0
	main.linear.restore(legacy)
	check(main.linear.can_evacuate(), "Completed original hold stays complete")

func coat_materials(node: Node) -> Array[StandardMaterial3D]:
	var result: Array[StandardMaterial3D] = []
	if node is MeshInstance3D:
		for index in node.mesh.get_surface_count():
			var material = node.get_active_material(index)
			if not material is StandardMaterial3D: continue
			var label: String = material.resource_name.to_lower()
			if label.contains("coat") or ["17309872-001", "17309872-002", "17309872-007"].any(func(part): return label.ends_with(part)):
				if material not in result: result.append(material)
	for child in node.get_children():
		for material in coat_materials(child):
			if material not in result: result.append(material)
	return result

func material_is_grey(material: StandardMaterial3D) -> bool:
	if material.albedo_texture == null: return material.albedo_color == Color("7c8083")
	var raster := material.albedo_texture.get_image()
	if raster == null or raster.is_empty(): return false
	if raster.is_compressed() and raster.decompress() != OK: return false
	var neutral := 0
	var count := 0
	var darkest := 1.0
	var lightest := 0.0
	# Inspect the shipped texture and tint, retaining woven shading and stains.
	for y in range(0, raster.get_height(), maxi(1, raster.get_height() / 32)):
		for x in range(0, raster.get_width(), maxi(1, raster.get_width() / 32)):
			var color := raster.get_pixel(x, y) * material.albedo_color
			if color.a < 0.5: continue
			count += 1
			if maxf(color.r, maxf(color.g, color.b)) - minf(color.r, minf(color.g, color.b)) < 0.08: neutral += 1
			var luminance := color.get_luminance()
			darkest = minf(darkest, luminance)
			lightest = maxf(lightest, luminance)
	return count > 100 and neutral >= count * 0.95 and lightest - darkest > 0.08

func _export_dialogue() -> void:
	main.start_new()
	var entries: Array = []
	for variant in ["scout_intro", "scout_route", "scout_repeat", "logger_intro", "logger_repeat", "lu_rescue", "lu_untreated", "lu_treated", "ending"]:
		match variant:
			"scout_intro": main.story.talk("scout")
			"scout_route": main.story.talk("scout"); main.story.choose(1)
			"scout_repeat": main.story.met_scout = true; main.story.talk("scout")
			"logger_intro": main.story.talk("logger")
			"logger_repeat": main.story.supply_choice = "medicine"; main.story.talk("logger")
			"lu_rescue": main.story.talk("lu")
			"lu_untreated": main.story.recruited = true; main.story.talk("lu")
			"lu_treated": main.story.people.lu.treated = true; main.story.talk("lu")
			"ending": main.stage = 2; main.story.people.lu.position = main.EVAC; main.linear.set_enabled(false); main.story.ending()
		entries.append({"id": variant, "speaker": main.story.speaker, "text": main.story.speech})
		main.story.close_dialog()
	var file := FileAccess.open(output.path_join("dialogue-runtime.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(entries, "\t"))

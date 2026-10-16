extends SceneTree

var main: Node3D
var checks := 0
var failures: Array[String] = []
var evidence: String
var captures: Array[String] = []

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		quit(2)
		return
	evidence = OS.get_environment("FENGHUO_EXPANSION_EVIDENCE")
	_run.call_deferred()

func check(condition: bool, description: String) -> void:
	checks += 1
	if condition: print("PASS: ", description)
	else:
		failures.append(description)
		push_error(description)

func _run() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await _frames(12)
	main.start_new()
	for guard in main.guards: guard.set_physics_process(false)
	await _frames(12)
	check(main.player.models[0].name == "Kar98k", "Supplied rifle is the active first-person weapon")
	check(main.player.weapon_rigs[0].bolt.get_child_count() > 0 and main.player.weapon_rigs[0].clip.get_child_count() > 0, "Supplied bolt and clip remain independently animated")
	var rifle: Dictionary = main.player.weapon_rigs[0]
	var contact_error := INF
	for part: MeshInstance3D in rifle.bolt.get_children():
		for surface in part.mesh.get_surface_count():
			for point: Vector3 in part.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
				contact_error = minf(contact_error, (part.transform * point).distance_to(rifle.bolt_contact))
	check(contact_error < .015, "Bolt hand socket lies on the supplied metal handle geometry")
	check(main.world.village_world.house_count == 22 and main.world.village_world.tree_count == 300, "Complete original settlement retains twenty-two courtyard groups and its surrounding forest")
	check(main.world.water != null and main.world.water.material_override is ShaderMaterial, "Supplied river channel uses animated game water")
	var waterfront := {"dock":0,"boat":0,"river":0}
	for child in main.get_children():
		if child.has_meta("user_waterfront"): waterfront[child.get_meta("user_waterfront")] += 1
	check(waterfront.dock == 2 and waterfront.boat == 2 and waterfront.river == 2, "Supplied pier and boat present at both banks")
	main.story._set_door(true)
	main.player.position = Vector3(53.5, .08, 42)
	await _frames(5)
	check(main.can_reach(main.BOOK, 3), "Codebook reachable on the south-hall office desk")
	main.story.met_scout = true
	main.interact()
	check(main.stage == 1, "Relocated codebook interaction advances mission")
	main.player.position = Vector3(62.2, .08, 32)
	await _frames(5)
	check(main.can_reach(main.POWER, 2.3), "Power switch reachable beside the northeast telephone cabinet")
	main.interact()
	check(main.stage == 2, "Relocated power switch advances mission")
	await _capture("office-exterior", Vector3(30, 7, 134), Vector3(54, 2.6, 36))
	await _capture("office-interior", Vector3(48, 2.1, 44), Vector3(60, 1.4, 30))
	await _capture("dock", Vector3(74, 5, 26), Vector3(88, -.1, 17))
	for guard in main.guards: guard.take_damage(1000)
	main.linear.set_enabled(false)
	main.linear.opened.assign(main.linear.GATES)
	main.story.recruited = true
	main.story.people.lu.following = true
	main.story.people.lu.position = main.EVAC + Vector3(-2, 0, 0)
	main.player.position = main.EVAC
	main.linear.extraction_started = true
	main.linear.extraction_remaining = 20
	main.hold_next = 0
	main.hold_wait = 0
	main._update_hold_reinforcements(0)
	check(main.hold_next == 2, "Ferry pursuit issues two soldiers per batch")
	for guard in main.guards:
		if guard.guard_id.begins_with("hold_"): guard.take_damage(1000)
	main._update_hold_reinforcements(.99)
	check(main.hold_next == 2, "Next pursuit batch waits for its one-second interval")
	main._update_hold_reinforcements(.02)
	check(main.hold_next == 4, "Second pair arrives after one second, twice the old batch cadence")
	main.linear.extraction_remaining = 0
	main._save_checkpoint()
	var legacy: Dictionary = main._snapshot().duplicate(true)
	legacy.erase("village")
	legacy.erase("map_revision")
	legacy.stage = 3
	_write_save(legacy)
	check(main._read_save().get("stage") == 2, "Legacy ferry victory saves migrate to a completed departure")
	main.village.depart()
	check(main.village.crossing and main.mode == "crossing", "Departure starts the ferry transition")
	main.village.crossing_clock = main.village.Journey.DURATION-.03
	await _frames(6)
	check(main.village.entered and main.stage == 3 and main.mode == "playing", "Ferry arrives in the playable village and restores control")
	check(main.player.camera.environment == main.world.village_world.environment, "Arrival applies the village atmosphere")
	check(main.guards.size() == 12 and main.village.remaining() == 12, "Village starts with twelve enemies")
	check(main.story.people.scout.following and not main.story.people.lu.following, "Jiang Lan joins combat while Lu Shan rests with the roster")
	check(main.story.people.scout.model.rifle != null and main.story.people.scout.model.rifle.visible, "Jiang Lan carries a rifle with friendly appearance")
	check(not main.world.village_world.path(main.VillageDirector.VillageWorld.START, Vector3(1140, .08, 167)).size(), "Closed first courtyard gate blocks route to the next encounter")
	var before: int = main.village.phase
	main.player.position = main.VillageDirector.VillageWorld.APPROACHES[0]
	main.village.interact()
	check(main.village.phase == before, "Uncleared encounter cannot open its gate")
	main.player.position = main.village.Forest.ENTRANCE
	main.village._update_approach()
	if main.mode=="dialogue": main.story.choose(0)
	main.player.position = Vector3(1153, .08, 272)
	main.story.people.scout.position = Vector3(1150, .08, 270)
	for guard in main.guards: guard.set_physics_process(false)
	await _frames(125)
	check(main.village.ally_shots > 0, "Companion fires at a visible village enemy")
	check(main._save_checkpoint() and not main._read_save().is_empty(), "Village checkpoint validates all actor and encounter states")
	if main._read_save().is_empty(): _save_diagnostics()
	var saved_shots: int = main.village.ally_shots
	main.continue_checkpoint()
	await _frames(5)
	check(main.village.entered and main.village.ally_shots >= saved_shots and main.stage == 3, "Village checkpoint restores chapter, ally and enemies")
	main.checkpoint.clear()
	main.continue_checkpoint()
	check(main.village.entered and main.stage == 3, "Village restore works from disk without the in-memory fallback")
	check(main.player.camera.environment == main.world.village_world.environment, "Disk restore retains the village atmosphere")
	await _capture("village-arrival", Vector3(1153, 2.1, 277), Vector3(1148, 1.7, 238))
	await _capture("village-wide", Vector3(1230, 60, 315), Vector3(1125, 3, 165))
	for phase in 3:
		for guard in main.guards:
			guard.set_physics_process(false)
			if int(guard.guard_id.trim_prefix("village_")) / 4 == phase: guard.take_damage(1000)
		check(main.village.section_cleared(), "Village encounter %d clears in order" % phase)
		if phase < 2:
			main.player.position = main.VillageDirector.VillageWorld.APPROACHES[phase]
			await _frames(3)
			main.village.interact()
			check(main.village.phase == phase+1, "Village gate %d opens after clearing its encounter" % phase)
			check(not main._read_save().is_empty(), "Gate checkpoint remains loadable")
	main.player.position = main.VillageDirector.VillageWorld.EXIT
	await _frames(3)
	main.village.interact()
	check(main.mode == "won" and main.stage == 4 and main.village.finished, "Final rendezvous wins only after all twelve village enemies are defeated")
	check(not main._read_save().is_empty(), "Final village victory is saved")
	main.continue_checkpoint()
	check(main.mode == "won" and main.village.finished, "Completed village restores its victory state")
	main.start_with_opening()
	check(main.player.camera.environment == null, "New game restores the forest atmosphere")
	check(not main.story.people.scout.model.rifle.visible, "Starting a new chapter resets Jiang Lan to the original scout pose")
	main.opening.set_process(false)
	for id in ["A-01", "A-04", "A-06"]:
		var shot: Dictionary = {}
		for candidate in main.opening.data.shots:
			if candidate.id == id: shot = candidate
		check(shot.get("environment") == ("qinglan_logging" if id=="A-04" else "songling_village"), "%s establishing sequence combines original village and logging camp" % id)
		if shot.is_empty(): continue
		main.opening.clock = (shot.start_ms + shot.end_ms) * .0005
		main.opening._update_view(.016)
		if DisplayServer.get_name() != "headless":
			await _capture_current("opening-" + id)
	main.opening.abort()
	var result := {"checks":checks,"failures":failures,"captures":captures,"passed":failures.is_empty(),"renderer":DisplayServer.get_name()}
	var file := FileAccess.open(evidence.path_join("validation.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	file.close()
	print("USER EXPANSION: ", "PASS" if failures.is_empty() else "FAIL", " | checks=", checks)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(main.save_path))
	main.queue_free()
	await _frames(3)
	quit(0 if failures.is_empty() else 1)

func _write_save(data: Dictionary) -> void:
	var file := FileAccess.open(main.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func _save_diagnostics() -> void:
	var data: Dictionary = main._snapshot()
	var guards := {}
	for id in data.encounter.active: guards[id] = main.Guard.valid_encounter(data.encounter.active[id])
	var file := FileAccess.open(evidence.path_join("save-diagnostics.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"snapshot":data,"story":main.story.valid(data.story),"linear":main.linear.valid_snapshot(data.linear),"village":main.village.valid_snapshot(data.village),"encounter":main._valid_encounter(data),"guards":guards},"\t"))
	file.close()

func _capture(label: String, at: Vector3, target: Vector3) -> void:
	if DisplayServer.get_name() == "headless": return
	main.player.model.visible = false
	main.menu_camera.position = at
	main.menu_camera.environment = main.world.village_world.environment if at.x > 900 else null
	main.menu_camera.look_at(target)
	main.menu_camera.current = true
	await _frames(4)
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	screenshot.save_png(evidence.path_join(label + ".png"))
	captures.append(label)
	main.player.camera.current = true
	main.player.model.visible = true

func _capture_current(label: String) -> void:
	await _frames(3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(evidence.path_join(label + ".png"))
	captures.append(label)

func _frames(count: int) -> void:
	for i in count: await physics_frame

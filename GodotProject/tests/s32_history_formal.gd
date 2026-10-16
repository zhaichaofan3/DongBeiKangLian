extends SceneTree

## S32 acceptance for the formal A1-A6 history segment.
## B1-B6 remains explicitly pending S33 and is not marked complete here.

var main: Node3D
var checks: Array[Dictionary] = []
var evidence := ""

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		quit(2)
		return
	evidence = OS.get_environment("FENGHUO_S32_EVIDENCE")
	if evidence.is_empty():
		quit(2)
		return
	_run.call_deferred()

func check(value: bool, description: String) -> void:
	checks.append({"passed": value, "description": description})
	print("PASS: " if value else "FAIL: ", description)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(evidence)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.save_path = "user://s32_history_formal_%d.json" % OS.get_process_id()
	main.start_with_opening()
	main.set_process(false)
	main.opening.set_process(false)
	var opening = main.opening
	var a_shots: Array = opening.data.shots.filter(func(item): return item.part == "A")
	var b_shots: Array = opening.data.shots.filter(func(item): return item.part == "B")
	# Check observable behavior instead of trusting completion labels in metadata.
	check(a_shots.size() == 11 and b_shots.size() == 16, "History uses 11 longer shots and B retains 16 shots")
	for history_shot in a_shots:
		opening.preview_at("A", (history_shot.start_ms + history_shot.end_ms) * 0.0005)
		var actors_present := true
		for block in history_shot.actors:
			actors_present = actors_present and opening.actors[block.id].is_visible_in_tree()
			var enemy := str(block.id).begins_with("enemy")
			for detail in ["GuardHelmetMark", "GuardMoustache"]:
				var accessory: Node3D = opening.actors[block.id].find_child(detail, true, false)
				actors_present = actors_present and (accessory != null and accessory.is_visible_in_tree() if enemy else accessory == null or not accessory.is_visible_in_tree())
			var expected_model := "japanese.glb" if enemy else "field_character.glb" if block.id == "worker" else "volunteer.glb"
			actors_present = actors_present and opening.actors[block.id].detailed_rig.character.scene_file_path.ends_with(expected_model)
		check(actors_present, "Authored actors and faction details remain correct in " + str(history_shot.id))
	check(ResourceLoader.exists("res://assets/opening/tianchi_artistic.glb") and opening.lake != null and opening.lake.name == "S21_Artistic_Tianchi", "A5-A6 load the artistic Tianchi scene including exported import remapping")
	check(opening.data.cues.A.size() == 17 and opening.HISTORY_AUDIO.get_length() > 68, "History has original 15 cues plus two additions over the complete supplied track")
	check(opening.blasts.size() == 4 and opening.distant_flashes.size() == 4, "A4 has the authored S27 barrage and distant fireline layers")
	var snow_top: float = opening.snow.position.y + (opening.snow.mesh as BoxMesh).size.y * 0.5
	check(opening.snow.material_override is ShaderMaterial and (opening.snow.material_override as ShaderMaterial).shader != null, "A07 snow surface uses a procedural material instead of the old flat color")
	opening.preview_at("A", 22.7)
	check(is_equal_approx(snow_top, 0.08) and is_equal_approx(opening.actors["ally1"].position.y, 0.08), "A07 snow top aligns with the actors' foot anchor")
	check(opening.shot_id == "A-07" and opening.snow.visible and opening.actors["ally1"].position.y >= snow_top - 0.001, "A07 preview shows the snow path and keeps the walking actor above its surface")
	if not OS.get_environment("FENGHUO_S32_SNOW_CAPTURE").is_empty() and DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		var capture_path := OS.get_environment("FENGHUO_S32_SNOW_CAPTURE")
		DirAccess.make_dir_recursive_absolute(capture_path.get_base_dir())
		check(root.get_texture().get_image().save_png(capture_path) == OK, "A07 snow render capture saved")
	opening.preview_at("A", 29.0)
	check(opening.shot_id == "A-09T" and opening.office_showcase_lights.visible and opening.camera.fov == 48,"Opening includes a lit close-up of the telegraph desk within the original narration timing")
	opening.preview_at("A", 31.4)
	var support = opening.actors["ally1"]
	var assisted = opening.actors["ally2"]
	check(opening.shot_id == "A-10" and support.position.x > 49 and assisted.position.x > 47.7 and support.position.z >= 38, "A10 soldiers walk through the office instead of helping each other")
	check(opening.office_showcase_lights.visible and opening.camera.position.x > 56 and support.position.distance_to(assisted.position) > 1, "A10 uses the interior travelling camera and dedicated lighting with separated actors")
	if not OS.get_environment("FENGHUO_S32_OFFICE_CAPTURE").is_empty() and DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		var office_path := OS.get_environment("FENGHUO_S32_OFFICE_CAPTURE")
		check(root.get_texture().get_image().save_png(office_path) == OK, "A10 office render capture saved")
	var before: Dictionary = main._snapshot()
	opening.preview_at("A", 33.5)
	check(opening.shot.segment == "A4" and opening.effects.visible and opening.blasts[0].visible, "A4 runtime combines formal label, muzzle layer and first barrage")
	opening.preview_at("A", 50.0)
	check(opening.shot.segment == "A5" and opening.current_cue == "N15" and opening.tianchi_environment_root.visible, "A5 carries N15 into the artistic Tianchi close")
	opening.preview_at("A", 62.0)
	check(opening.shot.segment == "A6" and opening.shot_id == "A-18" and not opening.lake.visible, "A6 carries the added narration over the continuous building panorama")
	check(main._snapshot().player == before.player and main._snapshot().story == before.story and main._snapshot().kills == before.kills, "History previews leave gameplay resources and mission state unchanged")
	# Continuous A playback proves the formal segment is traversable as one authored sequence.
	main.start_with_opening()
	main.set_process(false)
	opening.set_process(false)
	for i in 5100:
		if opening.part != "A" or not opening.active:
			break
		opening.advance(1.0 / 60.0)
	check(opening.part == "B" and opening.active and opening.handoff_count == 0, "A1-A6 complete into the separate B boundary without gameplay handoff")
	var history_seen_shots: Array = opening.seen_shots.filter(func(item): return str(item).begins_with("A-"))
	var history_seen_cues: Array = opening.seen_cues.filter(func(item): return str(item).begins_with("N"))
	check(history_seen_shots.size() == 11 and history_seen_cues.size() == 17, "Continuous history playback reaches all A shots and narration cues")
	check(not main.story.met_scout and main.mode == "cinematic", "History completion does not commit the task prologue")
	opening.abort()
	var passed := true
	for item in checks:
		passed = passed and item.passed
	var report := {
		"step": "S32",
		"status": "runtime_pass_visual_and_audio_acceptance_pending" if passed else "failed",
		"all_passed": passed,
		"checks": checks,
		"history_shots": a_shots.size(),
		"narration_cues": opening.data.cues.A.size(),
		"voice": "user_supplied_full_mix",
		"music": "embedded_in_history_global_suppressed",
		"sfx_listening": "pending_S28",
		"task_prologue": "pending_S33",
	}
	FileAccess.open(evidence.path_join("history-formal.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("S32 HISTORY FORMAL: ", "PASS" if passed else "FAIL", " | checks=", checks.size())
	opening.abort()
	for kind in ["AudioStreamPlayer", "AudioStreamPlayer3D"]:
		for sound in main.find_children("*", kind, true, false): sound.stop()
	await process_frame
	# The audio thread uses real time even when QA advances the game clock fast.
	OS.delay_msec(100)
	main.queue_free()
	await process_frame
	quit(0 if passed else 1)

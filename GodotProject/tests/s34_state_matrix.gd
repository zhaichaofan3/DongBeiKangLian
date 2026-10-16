extends SceneTree

## S34 state matrix for opening boundaries and gameplay checkpoint recovery.
## Every row records a user-visible transition and the state that must survive it.

var main: Node3D
var checks: Array[Dictionary] = []
var rows: Array[Dictionary] = []
var evidence := ""

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		quit(2)
		return
	evidence = OS.get_environment("FENGHUO_S34_EVIDENCE")
	if evidence.is_empty():
		quit(2)
		return
	_run.call_deferred()

func check(value: bool, description: String, row: String) -> void:
	checks.append({"passed": value, "description": description, "row": row})
	print("PASS: " if value else "FAIL: ", row, " | ", description)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(evidence)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.save_path = "user://s34_state_matrix_%d.json" % OS.get_process_id()

	# Row 1: start + pause + resume keeps the same cinematic clock and audio state.
	main.start_with_opening()
	main.set_process(false)
	main.opening.set_process(false)
	main.opening.preview_at("A", 4.0)
	var paused_clock: float = main.opening.clock
	main.opening.set_paused(true)
	main.opening.advance(2.0)
	check(main.opening.clock == paused_clock and main.mode == "cinematic_paused" and main.ambience.stream_paused, "Pause freezes clock, mode and environment audio", "pause_A")
	main.resume()
	check(main.opening.clock == paused_clock and main.mode == "cinematic" and not main.ambience.stream_paused, "Resume returns to the same cinematic point", "resume_A")
	rows.append({"id":"pause_A","action":"pause then resume","expected":"same A clock; no audio drift","passed":checks[-1].passed and checks[-2].passed})

	# Row 2: returning to menu mid-A restores the last saved A boundary.
	main.opening.preview_at("A", 40.0)
	main.return_to_menu()
	main.continue_checkpoint()
	main.set_process(false)
	main.opening.set_process(false)
	check(main.opening.active and main.opening.part == "A" and main.opening.clock == 0.0 and main.opening.shot_id == "A-01" and main.opening.current_cue.is_empty(), "Mid-history exit resumes at the saved A boundary", "exit_A_restore")
	rows.append({"id":"exit_A_restore","action":"return to menu during A then continue","expected":"history A1 boundary","passed":checks[-1].passed})

	# Row 3: skip A saves B, and an exit from B restores B1 without replaying A.
	main.opening.last_skip_ms = -1000
	main.opening.skip("A")
	main.return_to_menu()
	main.continue_checkpoint()
	main.set_process(false)
	main.opening.set_process(false)
	check(main.opening.active and main.opening.part == "B" and main.opening.clock == 0.0 and main.opening.current_cue.is_empty() and main.mode == "cinematic", "Skip-A then exit resumes at the B boundary", "skip_A_exit_B")
	rows.append({"id":"skip_A_exit_B","action":"skip A, exit during B, continue","expected":"task B1 boundary without replaying A","passed":checks[-1].passed})

	# Row 4: pausing B does not duplicate the active dialogue take.
	main.opening.preview_at("B", 2.6)
	var dialogue_stream: AudioStream = main.audio_mix.voice.stream
	main.opening.set_paused(true)
	main.opening.advance(1.0)
	check(main.opening.clock == 2.6 and main.audio_mix.voice.stream == dialogue_stream and main.audio_mix.voice.stream_paused, "Pause preserves the B1 dialogue stream", "pause_B_dialogue")
	main.resume()
	rows.append({"id":"pause_B_dialogue","action":"pause during B1 dialogue","expected":"same voice stream and clock","passed":checks[-1].passed})

	# Row 5: skipping B commits exactly once and leaves gameplay at the briefing boundary.
	main.opening.last_skip_ms = -1000
	main.opening.skip("B")
	check(main.mode == "playing" and main.opening.handoff_count == 1 and main.story.met_scout and main.stage == 0 and main.kills == 0, "Skip-B commits one gameplay handoff without advancing objectives", "skip_B_handoff")
	var handoff_count: int = main.opening.handoff_count
	main.opening.finish()
	check(main.opening.handoff_count == handoff_count and main.mode == "playing", "Repeated finish is idempotent", "skip_B_idempotent")
	rows.append({"id":"skip_B_handoff","action":"skip B","expected":"single gameplay handoff at stage 0","passed":checks[-2].passed and checks[-1].passed})

	# Row 6: an ordinary gameplay checkpoint never replays the opening.
	main.continue_checkpoint()
	check(not main.opening.active and main.mode == "playing" and main.story.met_scout, "Gameplay checkpoint restores play instead of replaying B", "gameplay_restore")
	rows.append({"id":"gameplay_restore","action":"continue after completed opening","expected":"playing state; no cinematic","passed":checks[-1].passed})

	var guard_ids := {}
	for guard in main.guards: guard_ids[guard.guard_id] = true
	check(guard_ids.size() == main.initial_roster().size() and main.guards.size() == main.initial_roster().size(), "Restore has exactly the revised roster with unique initial guards", "restore_unique_guards")
	# Row 7: malformed opening state is rejected visibly and does not silently complete.
	main.start_with_opening()
	main.set_process(false)
	main.opening.set_process(false)
	var invalid: Dictionary = main._snapshot()
	invalid.opening.phase = "unknown"
	_write_save(invalid)
	main.continue_checkpoint()
	check(main.mode == "opening_load_error" and not main.opening.active and FileAccess.get_file_as_string(main.save_path).contains("unknown"), "Malformed opening save enters a visible load error", "invalid_opening_save")
	rows.append({"id":"invalid_opening_save","action":"load unknown opening phase","expected":"opening_load_error with file preserved","passed":checks[-1].passed})

	# Row 8: legacy gameplay saves remain readable.
	main.start_new()
	var legacy: Dictionary = main._snapshot()
	legacy.erase("opening")
	_write_save(legacy)
	main.continue_checkpoint()
	check(not main.opening.active and main.mode == "playing" and not main.story.met_scout, "Legacy gameplay save retains the original briefing state", "legacy_restore")
	rows.append({"id":"legacy_restore","action":"load version-2 save without opening field","expected":"normal gameplay briefing","passed":checks[-1].passed})

	# Row 9: a failed final write leaves the old save and exposes retry.
	main.start_with_opening()
	main.set_process(false)
	main.opening.set_process(false)
	var good_path: String = main.save_path
	var good_file := FileAccess.get_file_as_string(good_path)
	main.save_path = "user://s34_missing_parent/checkpoint.json"
	main.opening.finish()
	check(main.mode == "opening_save_error" and not main.opening.active, "Failed handoff write exposes a retry state", "failed_write")
	check(FileAccess.get_file_as_string(good_path) == good_file, "Failed final write preserves the previous file byte for byte", "failed_write_preserves_file")
	main.save_path = good_path
	main.retry_opening_save()
	check(main.mode == "playing" and main.has_save() and FileAccess.get_file_as_string(good_path) != good_file, "Retry writes the prepared gameplay checkpoint", "retry_write")
	rows.append({"id":"failed_write","action":"force missing parent at handoff then retry","expected":"old save retained; retry commits prepared state","passed":checks[-3].passed and checks[-2].passed and checks[-1].passed})

	var passed := true
	for item in checks:
		passed = passed and item.passed
	var report := {
		"step": "S34",
		"status": "done" if passed else "failed",
		"all_passed": passed,
		"checks": checks,
		"rows": rows,
		"opening_audio": "temporary_voice_cleared_on_abort_and_boundary_transition",
		"music": "user_global_20261015",
		"sfx_listening": "pending_S28",
		"method": "Headless state matrix with isolated user save and explicit failure evidence.",
	}
	FileAccess.open(evidence.path_join("state-matrix.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("S34 STATE MATRIX: ", "PASS" if passed else "FAIL", " | checks=", checks.size(), " rows=", rows.size())
	main.opening.abort()
	await process_frame
	await create_timer(0.15).timeout
	main.queue_free()
	await process_frame
	quit(0 if passed else 1)

func _write_save(data: Dictionary) -> void:
	var file := FileAccess.open(main.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

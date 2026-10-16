extends SceneTree

## S33 acceptance for the formal B1-B6 task prologue.
## The cinematic must hand off once, without advancing gameplay objectives.

var main: Node3D
var checks: Array[Dictionary] = []
var evidence := ""

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args():
		quit(2)
		return
	evidence = OS.get_environment("FENGHUO_S33_EVIDENCE")
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
	main.save_path = "user://s33_task_formal_%d.json" % OS.get_process_id()
	main.start_with_opening()
	main.set_process(false)
	main.opening.set_process(false)
	var opening = main.opening
	var b_shots: Array = opening.data.shots.filter(func(item): return item.part == "B")
	check(b_shots.size() == 16, "All 16 authored task shots remain available")
	check(opening.data.cues.B.size() == 14 and opening.voice_streams.size() == 8, "B1-B6 keeps all 14 subtitle cues and the eight supplied recordings")
	var before: Dictionary = main._snapshot()
	opening.preview_at("B", 2.6)
	print("B1 SAMPLE: ", {"shot": opening.shot_id, "cue": opening.s24_active_cue, "peer": opening.s24_peer_visible, "badge": opening.badge.text})
	check(opening.shot_id == "B-01" and opening.s24_active_cue == "B1-L01" and opening.s24_peer_visible and opening.badge.text.begins_with("任务序幕") and not opening.badge.text.contains("临时合成对白"), "B1 starts the two-person Tianchi exchange with its task label")
	opening.preview_at("B", 20.0)
	check(opening.shot.segment == "B3" and opening.s24_active_cue == "B3-L01" and opening.arrival_route.size() > 0, "B3 states the original rendezvous and keeps the departure route available")
	opening.preview_at("B", 31.0)
	check(opening.shot.segment == "B4" and opening.s24_active_cue.is_empty() and not opening.hands.visible and not opening.s24_peer_visible and not opening.title.text.is_empty(), "B4 compresses the multi-day journey with separate time/place cards")
	opening.preview_at("B", 45.0)
	check(opening.shot.segment == "B5" and opening.s24_active_cue == "B5-L03" and opening.s24_peer_visible and not main.story.met_scout, "B5 reveals Lu Shan's injury and roster risk without starting gameplay combat")
	opening.preview_at("B", 77.0)
	check(opening.shot_id == "B-16" and opening.s24_active_cue == "B6-L02", "B6 final dialogue leaves the player-facing handoff cue visible")
	opening.preview_at("B", 79.5)
	print("B6 SAMPLE: ", {"shot": opening.shot_id, "cue": opening.s24_active_cue, "fov": opening.camera.fov, "clock": opening.clock})
	check(opening.shot_id == "B-16" and absf(opening.camera.fov - 78.0) < 0.1, "B6 ends on the authored player-facing handoff composition")
	check(main._snapshot().player == before.player and main._snapshot().story == before.story and main._snapshot().kills == before.kills, "B1-B6 previews leave gameplay resources and objectives unchanged")
	# Run B from start through its fade. Starting directly at B isolates S33 while
	# preserving the same mission state as the A->B boundary.
	opening.start("B")
	opening.set_process(false)
	for i in 5100:
		if not opening.active:
			break
		opening.advance(1.0 / 60.0)
	var b_seen_shots: Array = opening.seen_shots.filter(func(item): return str(item).begins_with("B-"))
	var b_seen_cues: Array = opening.seen_cues.filter(func(item): return str(item).begins_with("B"))
	check(b_seen_shots.size() == 16 and b_seen_cues.size() == 14, "Continuous task prologue playback reaches all B shots and dialogue cues")
	check(not opening.active and opening.handoff_count == 1 and main.mode == "playing", "B6 commits one and only one gameplay handoff")
	check(main.story.met_scout and main.stage == 0 and main.kills == 0 and main.player.magazines == [5, 10] and main.player.reserves == [35, 50], "Handoff marks briefing complete while leaving objectives and ammunition untouched")
	check(main.player.position.is_equal_approx(main.START) and is_equal_approx(main.player.rotation.y, -0.6) and main.player.camera.current, "Player camera and start anchor are restored at handoff")
	var count: int = opening.handoff_count
	opening.finish()
	check(opening.handoff_count == count, "Repeated finish cannot duplicate the task handoff")
	var passed := true
	for item in checks:
		passed = passed and item.passed
	var report := {
		"step": "S33",
		"status": "runtime_pass_audio_and_visual_review_pending" if passed else "failed",
		"all_passed": passed,
		"checks": checks,
		"task_shots": b_shots.size(),
		"dialogue_cues": opening.data.cues.B.size(),
		"voice": "eight_user_recordings_missing_lines_silent",
		"music": "user_global_20261015",
		"sfx_listening": "pending_S28",
		"handoff": "single_S25_contract",
	}
	FileAccess.open(evidence.path_join("task-formal.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("S33 TASK FORMAL: ", "PASS" if passed else "FAIL", " | checks=", checks.size())
	opening.abort()
	for kind in ["AudioStreamPlayer", "AudioStreamPlayer3D"]:
		for sound in main.find_children("*", kind, true, false):
			sound.stream_paused = false
			sound.stop()
	var cleanup_deadline := Time.get_ticks_msec() + 150
	while Time.get_ticks_msec() < cleanup_deadline: await process_frame
	main.queue_free()
	await process_frame
	quit(0 if passed else 1)

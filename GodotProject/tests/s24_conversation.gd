extends SceneTree
## S24 dialogue performance checks against the authored cue timing.

var checks: Array[Dictionary] = []
var evidence := ""

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	evidence = OS.get_environment("FENGHUO_S24_EVIDENCE")
	_run.call_deferred()

func check(passed: bool, description: String) -> void:
	checks.append({"passed": passed, "description": description})
	print("PASS: " if passed else "FAIL: ", description)

func _run() -> void:
	var main := (load("res://main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	main._ensure_opening()
	await process_frame
	var opening = main.opening
	opening.set_process(false)
	var before: Dictionary = main._snapshot()
	opening.start("B")
	opening.set_process(false)
	opening.preview_at("B", 3.1)
	await process_frame
	var scout: Node3D = opening.actors["scout"]
	var peer: Node3D = opening.actors["ally1"]
	check(opening.s24_active_cue == "B1-L01" and opening.s24_peer_visible and peer.visible, "B1 cue enables the second actor and the speaker action")
	check(peer.position.is_equal_approx(Vector3(497.2, 26.0, 146.3)) and absf(peer.position.y - 26.0) < 0.01, "Tianchi peer stands on the S22 platform without foot drift")
	opening.preview_at("B", 7.2)
	await process_frame
	check(opening.s24_active_cue == "B2-L01" and peer.visible, "B2 player line switches the speaking role")
	check(absf(scout.head.rotation.y - peer.head.rotation.y) > 0.01, "B2 listener waits for the line before turning")
	opening.preview_at("B", 11.0)
	await process_frame
	check(opening.s24_active_cue == "B2-L02" and absf(scout.chest.rotation.z) > 0.001, "B2 response adds a restrained hand and breath gesture")
	opening.preview_at("B", 18.5)
	await process_frame
	check(opening.s24_active_cue == "B3-L01" and absf(scout.arms[0].rotation.x) > 0.001, "B3 route briefing points toward the departure path")
	opening.preview_at("B", 39.0)
	await process_frame
	check(opening.s24_active_cue == "B5-L01" and peer.visible and peer.get_meta("opening_layer", 0) == 1, "B5 restores the two-person forest meeting on the gameplay layer")
	var forest_peer_y := peer.position.y
	opening.preview_at("B", 42.7)
	await process_frame
	check(opening.s24_active_cue == "B5-L02" and absf(peer.head.rotation.y) > 0.001, "B5 question uses a short forward response turn")
	opening.preview_at("B", 27.0)
	await process_frame
	check(opening.s24_active_cue.is_empty() and not peer.visible, "B4 travel montage hides the conversation peer")
	check(absf(forest_peer_y - 0.08) < 0.01 and main.mode == "cinematic", "Performance copy never changes player control mode or ground anchor")
	check(main.story.snapshot() == before.story and main.linear.snapshot() == before.linear, "Conversation acting leaves mission state untouched")
	var passed := true
	for item in checks: passed = passed and item.passed
	DirAccess.make_dir_recursive_absolute(evidence)
	var report := {"step":"S24","status":"done" if passed else "failed","all_passed":passed,"checks":checks,"cue_samples":["B1-L01","B2-L01","B2-L02","B3-L01","B5-L01","B5-L02"],"peer_anchor":{"tianchi":[497.2,26.0,146.3],"forest":[9.4,0.08,82.35]},"method":"Headless opening preview at authored dialogue cue windows; speaker/listener transform, layer, anchor and mission-state checks."}
	FileAccess.open(evidence.path_join("conversation.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("S24 CONVERSATION: ", "PASS" if passed else "FAIL", " | checks=", checks.size())
	main.queue_free()
	await process_frame
	quit(0 if passed else 1)

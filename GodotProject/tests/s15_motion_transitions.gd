extends SceneTree
## S15 isolated role motion probes. No mission or save files are used.
const Human = preload("res://scripts/human_model.gd")
const ROLES := ["scout", "logger", "wounded", "guard"]
var checks: Array[Dictionary] = []
var stage: Node3D
var models: Array[Node3D] = []
var evidence := ""

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	evidence = OS.get_environment("FENGHUO_S15_EVIDENCE")
	_run.call_deferred()

func check(passed: bool, description: String) -> void:
	checks.append({"passed": passed, "description": description})
	print("PASS: " if passed else "FAIL: ", description)

func _settle(model: Node3D, speed: float, yaw_rate: float, frames: int) -> Array[Dictionary]:
	var samples: Array[Dictionary] = []
	for i in frames:
		model.set_motion_context(model.role == "wounded", yaw_rate)
		model.animate(1.0 / 60.0, speed)
		if i % 5 == 0:
			samples.append({"frame": i, "motion": model._motion, "turn": model.turn_amount, "hip_y": model.hips.position.y, "chest_y": model.chest.position.y, "chest_z": model.chest.rotation.z})
	return samples

func _run() -> void:
	stage = Node3D.new()
	root.add_child(stage)
	for role in ROLES:
		var model := Human.new()
		model.build(role)
		stage.add_child(model)
		models.append(model)
	await process_frame
	for index in models.size():
		var model: Node3D = models[index]
		var idle := _settle(model, 0.0, 0.0, 120)
		var breath_values: Array[float] = []
		for sample in idle: breath_values.append(sample.chest_y)
		var breath_span := _span(breath_values)
		check(breath_span > 0.0005 and breath_span < 0.02, ROLES[index] + " has bounded idle breathing")
		var start := _settle(model, 2.2, 0.0, 30)
		check(start[-1].motion > start[0].motion + 0.25 and start[-1].motion <= 1.0, ROLES[index] + " blends from standing into movement")
		var stop := _settle(model, 0.0, 0.0, 45)
		check(stop[-1].motion < 0.08 and stop[0].motion > stop[-1].motion + 0.20, ROLES[index] + " eases to a stable stop")
		var turn := _settle(model, 0.0, 2.1, 30)
		check(absf(turn[0].turn) < 0.05 and absf(turn[-1].turn) > 0.08, ROLES[index] + " eases into a turn response")
		check(absf(turn[1].turn - turn[0].turn) < 0.06, ROLES[index] + " avoids an instantaneous turn snap")
		var reverse := _settle(model, 0.0, -2.1, 30)
		check(reverse[-1].turn < -0.08 and reverse[0].turn > -0.05, ROLES[index] + " reverses turn response smoothly")
	var passed := true
	for item in checks: passed = passed and item.passed
	FileAccess.open(evidence.path_join("motion_transitions.json"), FileAccess.WRITE).store_string(JSON.stringify({"step":"S15","all_passed":passed,"checks":checks,"roles":ROLES,"method":"Isolated imported character rigs; 120-frame idle breathing, 30-frame start, 45-frame stop and 30-frame eased turn probes."}, "  "))
	print("S15 MOTION TRANSITIONS: ", "PASS" if passed else "FAIL", " | checks=", checks.size())
	stage.queue_free()
	await process_frame
	quit(0 if passed else 1)

func _span(values: Array[float]) -> float:
	if values.is_empty(): return 0.0
	var low := values[0]
	var high := values[0]
	for value in values:
		low = minf(low, value)
		high = maxf(high, value)
	return high - low

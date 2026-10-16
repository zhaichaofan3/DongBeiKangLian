extends RefCounted
## Route progress stays separate from the roster/power mission state.

const GATES := ["checkpoint", "yard", "river"]
const POINTS := preload("res://scripts/first_level_layout.gd").GATES
const HOLD_DURATION := 30.0
var main: Node3D
var enabled := true
var opened: Array[String] = []
var contact_started := false
var extraction_started := false
var extraction_remaining := HOLD_DURATION

func initialize(owner_node: Node3D) -> void:
	main = owner_node
	reset()

func reset() -> void:
	enabled = true
	opened.clear()
	contact_started = false
	extraction_started = false
	extraction_remaining = HOLD_DURATION
	_sync_gates()

func set_enabled(value: bool) -> void:
	enabled = value
	_sync_gates()

func _sync_gates() -> void:
	for id in GATES:
		main.world.set_route_gate(id, not enabled or id in opened)

func gate_ready(id: String) -> bool:
	if not main.story.met_scout:
		return false
	match id:
		"checkpoint": return _section_cleared(["gate_guard", "gate_guard_2", "gate_guard_3"])
		"yard": return "checkpoint" in opened and _section_cleared(["yard_guard", "timber_guard", "yard_guard_2", "yard_guard_3"])
		"river": return "yard" in opened and main.stage == 2 and main.story.recruited
	return false

func _section_cleared(ids: Array) -> bool:
	var roster: Dictionary = main.initial_roster()
	for id in ids:
		if roster.has(id) and (main.expanded_encounter or id in main.LEGACY_INITIAL_IDS) and not main.defeated.has(id): return false
	return true

func _near_gate() -> String:
	if enabled:
		for index in GATES.size():
			if GATES[index] not in opened and main.can_reach(POINTS[index], 3.3):
				return GATES[index]
	return ""

func _needs_ammo(id: String) -> bool:
	return id in ["checkpoint", "yard"] and main.story.met_scout and not gate_ready(id) and main.player.magazines[0] + main.player.magazines[1] + main.player.reserves[0] + main.player.reserves[1] == 0

func interact() -> bool:
	var id := _near_gate()
	if id.is_empty():
		return false
	if _needs_ammo(id):
		main.player.reserves[0] += 5
		main.notify("从栅门旁的弹药箱取出 5 发步枪弹。按 1 切步枪、R 装填。", 5)
		main._save_checkpoint()
		return true
	if not gate_ready(id):
		main.notify(interaction_prompt(), 3)
		return true
	var ambush: bool = id == "yard" and main.melee.can_begin("door")
	if ambush and not main._save_checkpoint():
		main.notify("门前检查点保存失败，请重试开门。" + main.last_save_error, 6)
		return true
	opened.append(id)
	_sync_gates()
	main.play_world_sound("door_open", POINTS[GATES.find(id)])
	if ambush:
		main.melee.begin("door")
		return true
	main._save_checkpoint()
	match id:
		"checkpoint": main.notify("检查口已打开。木料巷有四名守卫，利用矮箱逐段推进。", 6)
		"yard": main.notify("木料巷已打通。沿装卸林道绕过山坡，再接近电报房。", 6)
		"river": main.notify("陆山：前面就是船！你看住后面的路，我来解缆。", 6)
	return true

func interaction_prompt() -> String:
	var id := _near_gate()
	if id.is_empty():
		return ""
	if _needs_ammo(id):
		return "E  从备用弹药箱取 5 发步枪弹"
	if gate_ready(id):
		return "E  打开%s栅门" % {"checkpoint": "检查口", "yard": "木料巷", "river": "渡口"}[id]
	if not main.story.met_scout:
		return "先与姜岚接头"
	if id == "river":
		return "取回名册、切断电源，再接上陆山"
	return "先清除这段路上的守卫"

func can_guard_act(id: String) -> bool:
	if is_instance_valid(main.village) and main.village.entered: return main.village.can_guard_act(id)
	if id.begins_with("village_"): return false
	if not enabled:
		return true
	match id:
		"gate_guard", "gate_guard_2", "gate_guard_3": return contact_started
		"yard_guard", "timber_guard", "yard_guard_2", "yard_guard_3": return "checkpoint" in opened
		"office_guard", "office_guard_2", "office_guard_3", "office_guard_4", "door_ambusher": return "yard" in opened
		"pier_guard": return "river" in opened
	return "river" in opened

func update(delta: float) -> void:
	if main.stage >= 3 or not enabled or main.mode != "playing":
		return
	if not contact_started and main.story.met_scout and main.player.position.x > 24 and main.player.position.z > 198:
		contact_started = true
		main.notify("前方检查口有岗哨。压低身子，借沙袋接近。", 4)
	if "river" not in opened or main.stage != 2 or not main.story.recruited:
		return
	if not main.story.people.lu.following or main.player.position.distance_to(main.EVAC) > 10 or main.story.people.lu.position.distance_to(main.EVAC) > 6:
		return
	if not extraction_started:
		extraction_started = true
		main.notify("陆山正在解缆！守住30秒，留意后方林道。", 5)
		main._save_checkpoint()
	if extraction_remaining > 0:
		extraction_remaining = maxf(0, extraction_remaining - delta)
		if extraction_remaining == 0:
			main.notify("陆山：缆绳解开了！快上船，一起走！", 6)
			main._save_checkpoint()

func can_evacuate() -> bool:
	return not enabled or ("river" in opened and extraction_started and extraction_remaining <= 0)

func status_text() -> String:
	if main.stage >= 3: return ""
	if not enabled:
		return ""
	if extraction_started and extraction_remaining > 0:
		if not main.story.people.lu.following:
			return "靠近陆山按 E，让他继续跟随并解缆。"
		if main.player.position.distance_to(main.EVAC) > 10 or main.story.people.lu.position.distance_to(main.EVAC) > 6:
			return "回到渡口照应陆山，才能继续解缆。"
		return "掩护陆山解缆  ·  还需 %d 秒\n利用渡口木箱，看住林道入口。" % ceili(extraction_remaining)
	if "river" in opened and not extraction_started:
		return "带陆山靠近船边，再掩护他解缆。"
	return ""

func objective_text() -> String:
	if not enabled or not main.story.met_scout:
		return ""
	if main.player.position.x < 24 and main.player.position.z > 248:
		return "木墙缺口"
	if "checkpoint" not in opened:
		return "01 / 04   突破检查口"
	if "yard" not in opened:
		return "02 / 04   清理木料巷"
	if main.stage < 2:
		return "03 / 04   " + ("夺取搜山名册" if main.stage == 0 else "切断电话中继电源")
	if not main.story.recruited:
		return "03 / 04   接应交通员陆山"
	if extraction_started:
		return "04 / 04   " + ("掩护解缆 · %d 秒" % ceili(extraction_remaining) if extraction_remaining > 0 else "与陆山登船撤离")
	return "04 / 04   护送陆山前往渡口"

func target_name() -> String:
	if not enabled or not main.story.met_scout:
		return ""
	if "checkpoint" not in opened:
		return "木墙缺口" if main.player.position.x < 24 else "检查口"
	if "yard" not in opened or main.player.position.z > 166:
		return "运输林道" if main.player.position.z > 166 else "木料巷出口"
	if main.player.position.z > 70:
		return "装卸林道"
	if main.stage == 2 and main.story.recruited and "river" not in opened:
		return "电报房北侧通道" if main.player.position.x < 40 and main.player.position.z > 25 else "渡口栅门"
	return ""

func target_position() -> Vector3:
	if main.player.position.x < 24 and main.player.position.z > 248:
		return Vector3(24,1.4,256)
	if "checkpoint" not in opened:
		return Vector3(24, 1.4, 256) if main.player.position.x < 24 else POINTS[0]
	if "yard" not in opened or main.player.position.z > 166:
		return _next_turn([Vector3(34,1.4,194),Vector3(34,1.4,182),Vector3(56,1.4,182),Vector3(56,1.4,166),Vector3(34,1.4,162),POINTS[1]])
	if main.player.position.z > 70:
		return _next_turn([Vector3(34,1.4,118),Vector3(34,1.4,106),Vector3(72,1.4,106),Vector3(72,1.4,76),Vector3(34,1.4,76),Vector3(34,1.4,64)])
	if main.player.position.x < 40 and main.player.position.z > 25:
		return Vector3(38, 1.4, 22)
	return POINTS[2]

func _next_turn(points: Array) -> Vector3:
	var at := Vector2(main.player.position.x,main.player.position.z)
	var best := INF
	var next := 1
	for i in range(1,points.size()):
		var a := Vector2(points[i-1].x,points[i-1].z)
		var b := Vector2(points[i].x,points[i].z)
		var projected := Geometry2D.get_closest_point_to_segment(at,a,b)
		var distance := at.distance_squared_to(projected)
		if distance < best:
			best=distance
			next=i
	if at.distance_to(Vector2(points[next].x,points[next].z)) < 3 and next < points.size()-1: next+=1
	return points[next]

func snapshot() -> Dictionary:
	return {"version": 2, "enabled": enabled, "opened": opened.duplicate(), "contact_started": contact_started,
		"extraction_started": extraction_started, "extraction_remaining": extraction_remaining}

func restore(data: Dictionary) -> void:
	reset()
	if data.is_empty():
		set_enabled(false)
		return
	enabled = data.enabled
	opened.assign(data.opened)
	contact_started = data.contact_started
	extraction_started = data.extraction_started
	extraction_remaining = float(data.extraction_remaining)
	if int(data.get("version", 1)) == 1:
		extraction_remaining = extraction_remaining / 12.0 * HOLD_DURATION
	_sync_gates()

func valid_snapshot(data: Variant) -> bool:
	if not data is Dictionary or not main._whole_number(data.get("version"), 1, 2):
		return false
	for key in ["enabled", "contact_started", "extraction_started"]:
		if not data.get(key) is bool:
			return false
	if not data.get("opened") is Array or data.opened.size() > GATES.size():
		return false
	for index in data.opened.size():
		if data.opened[index] != GATES[index]:
			return false
	var duration := 12.0 if int(data.version) == 1 else HOLD_DURATION
	if not main._number_between(data.get("extraction_remaining"), 0, duration):
		return false
	if data.extraction_started and "river" not in data.opened:
		return false
	return data.extraction_started or float(data.extraction_remaining) == duration

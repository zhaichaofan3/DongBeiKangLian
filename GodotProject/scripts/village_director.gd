extends Node
## Ferry departure opens a second playable chapter with three ordered encounters.

const VillageWorld = preload("res://scripts/village_world.gd")
const Journey = preload("res://scripts/river_journey.gd")
const Forest = preload("res://scripts/forest_approach.gd")
const ENEMIES := {
	"village_0": [Vector3(1147,.08,264),Vector3(1147,.08,258)],
	"village_1": [Vector3(1147,.08,237),Vector3(1147,.08,231)],
	"village_2": [Vector3(1143.5,.08,204),Vector3(1143.5,.08,202)],
	"village_3": [Vector3(1147,.08,199),Vector3(1147,.08,201)],
	"village_4": [Vector3(1147,.08,180),Vector3(1147,.08,174)],
	"village_5": [Vector3(1150.5,.08,149),Vector3(1150.5,.08,147)],
	"village_6": [Vector3(1147,.08,136),Vector3(1147,.08,130)],
	"village_7": [Vector3(1147,.08,116),Vector3(1147,.08,119)],
	"village_8": [Vector3(1147,.08,97),Vector3(1147,.08,91)],
	"village_9": [Vector3(1150.5,.08,65),Vector3(1150.5,.08,63)],
	"village_10": [Vector3(1147,.08,49),Vector3(1147,.08,44)],
	"village_11": [Vector3(1147,.08,29),Vector3(1147,.08,26)]}
var main: Node3D
var entered := false
var phase := 0
var finished := false
var crossing := false
var crossing_clock := 0.0
var ally_shots := 0
var ally_wait := 0.0
var ally_target := Vector3.ZERO
var overlay: CanvasLayer
var fade: ColorRect
var journey: Node3D
var approach_active := false
var intro_seen := false
var approach_marker := -1
var arrival_fade := 0.0

func initialize(owner_node: Node3D) -> void:
	main = owner_node
	overlay = CanvasLayer.new()
	overlay.layer = 40
	add_child(overlay)
	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(fade)
	fade.visible = false
	_prepare_navigation.call_deferred()

func _prepare_navigation() -> void:
	await get_tree().physics_frame
	main.world.village_world.initialize_navigation()

func reset() -> void:
	abort_crossing()
	entered = false
	phase = 0
	finished = false
	crossing = false
	ally_shots = 0
	ally_wait = 0
	approach_active = false
	intro_seen = false
	approach_marker = -1
	arrival_fade = 0
	if fade != null: fade.visible = false
	main.player.camera.environment = null
	main.world.village_world.set_phase(0)
	for npc in main.story.people.values(): npc.visible = true

func depart() -> void:
	if crossing or entered or not main.story.ready_to_leave(): return
	if not main._save_checkpoint():
		main.notify("登船前检查点保存失败，请重试。" + main.last_save_error, 6)
		return
	crossing = true
	crossing_clock = 0
	main.mode = "crossing"
	main.player.fire_requested = false
	main.player.model.visible = false
	fade.visible = true
	fade.color.a = 0
	journey = Journey.new()
	add_child(journey)
	journey.initialize(main,self)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	if crossing:
		if main.mode!="crossing": return
		crossing_clock += delta
		journey.sample(crossing_clock,delta)
		if crossing_clock>=Journey.DURATION: finish_crossing()
		return
	if arrival_fade>0 and main.mode=="playing":
		arrival_fade = maxf(0,arrival_fade-delta)
		fade.color.a = arrival_fade/.75
		fade.visible = arrival_fade>0
	if not entered or finished or main.mode != "playing": return
	if main.player.position.y < -2:
		main.player.position = Forest.LANDING
		main.player.velocity = Vector3.ZERO
		main.player.horizontal_velocity = Vector2.ZERO
		main.player.rotation.y = 0
		main.player.reset_physics_interpolation()
		arrival_fade = .75
		fade.visible = true
		main.notify("河水太急，回到岸边沿土路进村。",4)
	if approach_active:
		_update_approach()
		return
	_update_ally(delta)

func handle_input(event: InputEvent) -> bool:
	if not crossing: return false
	if event.is_action_pressed("pause"):
		set_crossing_paused(main.mode=="crossing")
		return true
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_ENTER:
		finish_crossing()
		return true
	return false

func set_crossing_paused(value: bool) -> void:
	if not crossing: return
	main.mode = "crossing_paused" if value else "crossing"
	journey.set_paused(value)
	fade.visible = not value
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func abort_crossing() -> void:
	crossing = false
	if is_instance_valid(journey):
		journey.release()
		journey.queue_free()
	journey = null
	if fade!=null: fade.visible = false

func finish_crossing() -> void:
	if not crossing: return
	abort_crossing()
	if not _arrive(true):
		main.mode = "crossing_save_error"
		main.player.camera.make_current()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	arrival_fade = .75
	fade.visible = true
	fade.color.a = 1
	main.resume()
	main.notify("姜岚：沿这条土路穿过林子，前面就是松岭屯。",7)

func retry_arrival_save() -> void:
	if main._save_checkpoint(): main.resume()

func _arrive(via_forest: bool = false) -> bool:
	entered = true
	approach_active = via_forest
	intro_seen = not via_forest
	approach_marker = -1
	main.player.camera.environment = main.world.village_world.environment
	phase = 0
	main.stage = 3
	main.player.position = Forest.LANDING if via_forest else VillageWorld.START
	main.player.rotation.y = 0
	main.player.pitch = 0
	main.player.camera.rotation = Vector3.ZERO
	main.player.velocity = Vector3.ZERO
	main.player.horizontal_velocity = Vector2.ZERO
	main.player.reset_physics_interpolation()
	main.player.health = maxf(80, main.player.health)
	main.player.reserves[0] += 35
	main.player.reserves[1] += 30
	main.story.bandages = mini(3, main.story.bandages + 1)
	var treated: bool = main.story.people.lu.treated
	main.story.people.lu.reset(Forest.REST if via_forest else Vector3(1152,.08,285))
	main.story.people.lu.treated = treated
	main.story.people.scout.reset(Forest.SCOUT if via_forest else VillageWorld.START+Vector3(.7,0,1.5))
	main.story.people.scout.model.set_armed(true)
	main.story.people.scout.following = true
	main.story.people.logger.visible = false
	main.world.village_world.set_phase(phase)
	main._reset_guards()
	return main._save_checkpoint()

func _update_approach() -> void:
	if main.player.position.distance_to(Forest.ENTRANCE)<13:
		approach_active = false
		intro_seen = true
		var ally: CharacterBody3D = main.story.people.scout
		ally.reset(main.player.position+Vector3(-1.3,0,-2.5))
		var facing: Vector3 = main.player.position-ally.position
		ally.rotation.y = atan2(-facing.x,-facing.z)
		ally.model.set_armed(true)
		ally.following = true
		if not main._save_checkpoint():
			approach_active = true
			intro_seen = false
			main.notify("入村检查点保存失败，请重试。"+main.last_save_error,4)
			return
		main.story.show_dialog("scout","姜岚","到了，前面就是松岭屯。\n陆山的名单上有几户乡亲还没撤走，日军正在挨院搜人。街上堆了木料，得从敞开的院门穿过去。你贴着院墙走，我在侧后掩护。",[{"label":"进村，先打通村口。","action":"close"}])
		return
	var marker: int = Forest.projection(main.player.position).index
	if marker>approach_marker and marker%2==0:
		approach_marker = marker
		main._save_checkpoint()

func can_guard_act(identifier: String) -> bool:
	return entered and not approach_active and identifier in ENEMIES and int(identifier.trim_prefix("village_")) / 4 <= phase

func remaining() -> int:
	var count := 0
	for id in ENEMIES:
		if not main.defeated.has(id): count += 1
	return count

func section_cleared() -> bool:
	for i in range(phase*4, phase*4+4):
		if not main.defeated.has("village_%d" % i): return false
	return true

func interact() -> void:
	if approach_active: return
	if phase < 2:
		if main.can_reach(VillageWorld.GATES[phase], 3.5):
			if not section_cleared():
				main.notify("先清除这段村道上的日军，再打开院门。", 4)
				return
			phase += 1
			main.world.village_world.set_phase(phase)
			main.play_world_sound("door_open", VillageWorld.GATES[phase-1])
			main._save_checkpoint()
			main.notify("姜岚：继续向北，我掩护你。", 5)
	elif remaining() == 0 and main.can_reach(VillageWorld.EXIT + Vector3.UP, 3.5):
		finished = true
		main.stage = 4
		main._save_checkpoint()
		main.mode = "won"
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func interaction_prompt() -> String:
	if approach_active: return ""
	if phase < 2 and main.can_reach(VillageWorld.GATES[phase], 3.5):
		return "F  打开村内院门" if section_cleared() else "清除本段日军后打开院门"
	if phase == 2 and remaining() == 0 and main.can_reach(VillageWorld.EXIT + Vector3.UP, 3.5): return "F  村庄安全，与战友完成会合"
	return ""

func objective_text() -> String:
	if approach_active: return "04 / 07   穿过密林，沿土路前往松岭屯"
	return "%02d / 07   %s · 剩余 %d 名日军" % [5 + phase, ["穿过村口西院", "转入东侧夹巷", "肃清北院"][phase], remaining()]

func target_name() -> String:
	if approach_active: return "松岭屯村口"
	return "北侧会合点" if phase == 2 and remaining() == 0 else "村内院门" if section_cleared() and phase < 2 else ["村口日军", "主街日军", "北院日军"][phase]

func target_position() -> Vector3:
	if approach_active:
		var index: int = mini(Forest.ROAD.size()-1,int(Forest.projection(main.player.position).index)+1)
		if main.player.position.distance_to(Forest.ROAD[index])<2: index = mini(index+1,Forest.ROAD.size()-1)
		return Forest.ROAD[index]+Vector3.UP
	if phase == 2 and remaining() == 0: return VillageWorld.EXIT
	if phase < 2 and section_cleared(): return VillageWorld.GATES[phase]
	for guard in main.guards:
		if is_instance_valid(guard) and guard.state != "dead" and can_guard_act(guard.guard_id): return guard.position + Vector3.UP
	return VillageWorld.EXIT

func _update_ally(delta: float) -> void:
	var ally: CharacterBody3D = main.story.people.scout
	ally_wait = maxf(0, ally_wait - delta)
	if ally_wait > 0: return
	for guard in main.guards:
		if not is_instance_valid(guard) or guard.state == "dead" or not can_guard_act(guard.guard_id): continue
		if ally.position.distance_to(guard.position) > 27: continue
		var target: Vector3 = guard.position + Vector3.UP * 1.25
		var query := PhysicsRayQueryParameters3D.create(ally.position + Vector3.UP * 1.4, target, 1 | 2 | 4 | 8)
		query.exclude = [ally.get_rid()]
		var hit := main.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or hit.collider != guard: continue
		var offset: Vector3 = guard.position - ally.position
		ally_target = guard.position
		ally.rotation.y = atan2(-offset.x, -offset.z)
		ally.model.set_motion_context(false, 0, true)
		ally.model.fire()
		main.guard_shot(ally.model.rifle.to_global(Vector3(0,.025,-.59)), target, ally.model.rifle)
		ally_shots += 1
		ally_wait = 1.8
		guard.take_damage(30)
		return

func snapshot() -> Dictionary:
	var at: Vector3 = main.story.people.scout.position if entered else VillageWorld.START+Vector3(.7,0,1.5)
	return {"version": 4, "entered": entered, "phase": phase, "finished": finished, "ally_position": [at.x,at.y,at.z], "ally_shots": ally_shots,"approach_active":approach_active,"intro_seen":intro_seen}

func restore(data: Dictionary) -> void:
	reset()
	if data.is_empty() or not data.entered: return
	entered = true
	approach_active = data.get("approach_active",false)
	intro_seen = data.get("intro_seen",true)
	approach_marker = int(Forest.projection(main.player.position).index)
	phase = int(data.phase)
	main.player.camera.environment = main.world.village_world.environment
	finished = data.finished
	ally_shots = int(data.ally_shots)
	var at: Array = data.ally_position
	main.story.people.scout.reset(Vector3(at[0],at[1],at[2]))
	main.story.people.scout.model.set_armed(true)
	main.story.people.scout.following = true
	main.story.people.logger.visible = false
	main.world.village_world.set_phase(phase)

func valid_snapshot(data: Variant) -> bool:
	if not data is Dictionary: return false
	if data.is_empty(): return true
	if not main._whole_number(data.get("version"),1,4) or not data.get("entered") is bool or not data.get("finished") is bool: return false
	if int(data.version)>=3:
		if not data.get("approach_active") is bool or not data.get("intro_seen") is bool: return false
		if data.approach_active and (not data.entered or data.finished or data.get("phase")!=0 or data.intro_seen): return false
		if not data.entered and (data.approach_active or data.intro_seen): return false
		if data.entered and not data.approach_active and not data.intro_seen: return false
	if not main._whole_number(data.get("phase"),0,2) or not main._whole_number(data.get("ally_shots"),0,100000): return false
	if not data.get("ally_position") is Array or data.ally_position.size() != 3: return false
	for number in data.ally_position:
		if not main._number_between(number,-.1,1290): return false
	if not VillageWorld.contains(Vector3(data.ally_position[0],data.ally_position[1],data.ally_position[2])): return false
	return data.entered or (int(data.phase) == 0 and not data.finished and int(data.ally_shots) == 0)

func migrate_layout(data: Dictionary) -> void:
	if not data.get("village",{}).get("entered",false) or int(data.village.get("version",0))>=4: return
	# Woodland saves retain their landing/path position. Village saves move only
	# to their matching cleared section; combat progress and supplies are retained.
	if not data.village.get("approach_active",false):
		var at: Vector3 = VillageWorld.EXIT if data.village.finished else VillageWorld.PHASE_STARTS[int(data.village.phase)]
		data.player.position = [at.x,at.y,at.z]
		data.village.ally_position = [at.x+.7,at.y,at.z+1.5]
	data.story.lu_position = [1152,.08,285]
	data.village.approach_active = data.village.get("approach_active",false)
	data.village.intro_seen = not data.village.approach_active
	for id in data.encounter.active:
		if not ENEMIES.has(id): continue
		var enemy: Dictionary = data.encounter.active[id]
		var spawn: Vector3 = ENEMIES[id][0]
		var patrol: Vector3 = ENEMIES[id][1]
		enemy.position = [spawn.x,spawn.y,spawn.z]
		enemy.patrol = [patrol.x,patrol.y,patrol.z]
		enemy.last_seen = [0,0,0]
		enemy.state = "patrol"
	data.map_revision = maxi(4,int(data.get("map_revision",0)))
	data.village.version = 4

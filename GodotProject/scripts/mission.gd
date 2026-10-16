extends Node3D

const World = preload("res://scripts/world.gd")
const Player = preload("res://scripts/fps_player.gd")
const Guard = preload("res://scripts/guard.gd")
const HUD = preload("res://scripts/hud.gd")
const AudioFactory = preload("res://scripts/audio_factory.gd")
const AudioMix = preload("res://scripts/audio_mix.gd")
const Story = preload("res://scripts/story.gd")
const Presentation = preload("res://scripts/presentation.gd")
const LinearDirector = preload("res://scripts/linear_director.gd")
const VillageDirector = preload("res://scripts/village_director.gd")
const OpeningDirector = preload("res://scripts/opening_director.gd")
const ArtilleryDirector = preload("res://scripts/artillery_director.gd")
const MuzzleEffect = preload("res://scripts/muzzle_effect.gd")
const BayonetEncounter = preload("res://scripts/bayonet_encounter.gd")
const Layout = preload("res://scripts/first_level_layout.gd")
const START := Layout.START
const BOOK := Vector3(53.5, 0.99, 40)
const POWER := Vector3(63.0, 1.55, 30.2)
const EVAC := Vector3(79, 0.16, 14)
const SAVE_PATH := "user://qinglan_checkpoint_v2.json"
const CAPTURE_SAVE_PATH := "user://capture_qinglan_checkpoint_v2.json"
const MAX_ALIVE_GUARDS := 14
const REINFORCEMENT_COUNT := 4
const REINFORCEMENT_FIRST_DELAY := 5.0
const REINFORCEMENT_INTERVAL := 3.0
const REINFORCEMENT_WAVE_DELAY := 10.0
const INITIAL_GUARDS := {
	"gate_guard": [Vector3(30, 0.08, 226), Vector3(30, 0.08, 234)],
	"yard_guard": [Vector3(38, 0.08, 134), Vector3(38, 0.08, 126)],
	"pier_guard": [Vector3(74, 0.08, 26), Vector3(74, 0.08, 18)],
	"timber_guard": [Vector3(30, 0.08, 130), Vector3(30, 0.08, 126)],
	"office_guard": [Vector3(34, 0.08, 118.5), Vector3(34, 0.08, 112)]}
const ADDED_GUARDS := {
	"door_ambusher": [Vector3(34, 0.08, 118.5), Vector3(34, 0.08, 112)],
	"gate_guard_2": [Vector3(38, 0.08, 210), Vector3(38, 0.08, 204)],
	"gate_guard_3": [Vector3(34, 0.08, 214), Vector3(34, 0.08, 206)],
	"yard_guard_2": [Vector3(34, 0.08, 134), Vector3(34, 0.08, 128)],
	"yard_guard_3": [Vector3(38, 0.08, 126), Vector3(34, 0.08, 126)],
	"office_guard_2": [Vector3(50, 0.08, 38), Vector3(46, 0.08, 38)],
	"office_guard_3": [Vector3(58, 0.08, 36), Vector3(54, 0.08, 36)],
	"office_guard_4": [Vector3(56, 0.08, 30), Vector3(54, 0.08, 30)]}
const HOLD_RESPAWN_DELAY := 1.0
const HOLD_MAX_ISSUED := 4096
const LEGACY_INITIAL_IDS := ["gate_guard", "yard_guard", "pier_guard"]
const REINFORCEMENT_ENTRIES := [Vector3(62, 0.08, 22), Vector3(58, 0.08, 22), Vector3(62, 0.08, 22), Vector3(58, 0.08, 22)]

var world: RefCounted
var player: CharacterBody3D
var hud: CanvasLayer
var story: RefCounted
var presentation: RefCounted
var linear: RefCounted
var village: Node
var opening: Node3D
var melee: Node3D
var opening_phase := "gameplay"
var invalid_opening_save := false
var last_save_error := ""
var mode := "briefing"
var stage := 0
var message := ""
var message_timer := 0.0
var hit_marker := 0.0
var elapsed := 0.0
var kills := 0
var defeated: Dictionary = {}
var checkpoint: Dictionary = {}
var reached_yard := false
var reinforcement_pending := 0
var reinforcement_next := 0
var reinforcement_wait := 0.0
var expanded_encounter := true
var encounter_revision := 2
var hold_next := 0
var hold_wait := 0.0
var menu_camera: Camera3D
var guards: Array[CharacterBody3D] = []
var codebook: Node3D
var power_marker: Label3D
var enemy_audio: AudioStreamPlayer3D
var ambience: AudioStreamPlayer
var audio_mix: Node
var artillery: Node3D
var active_fire_effects: Array[Node3D] = []
var save_path := "user://qa_qinglan_checkpoint_v2.json" if "--qa" in OS.get_cmdline_user_args() else SAVE_PATH

func _ready() -> void:
	if "--capture" in OS.get_cmdline_user_args():
		save_path = CAPTURE_SAVE_PATH
	_configure_input()
	audio_mix = AudioMix.new()
	add_child(audio_mix)
	audio_mix.initialize(self)
	world = World.new()
	world.build(self)
	player = Player.new()
	player.initialize(self, START)
	add_child(player)
	_spawn_initial_guards()
	codebook = world.box("搜山名册", BOOK, Vector3(0.45, 0.11, 0.6), "paper")
	var text := Label3D.new()
	text.text = "名簿"
	text.font_size = 48
	text.pixel_size = 0.005
	text.position = Vector3(0, 0.06, 0)
	text.rotation.x = -PI * 0.5
	codebook.add_child(text)
	power_marker = Label3D.new()
	power_marker.text = "總閘"
	power_marker.position = POWER + Vector3(0, 0.65, 0)
	power_marker.font_size = 48
	power_marker.pixel_size = 0.004
	add_child(power_marker)
	enemy_audio = AudioStreamPlayer3D.new()
	enemy_audio.stream = AudioFactory.make_sound("rifle")
	enemy_audio.volume_db = -16
	enemy_audio.max_distance = 70
	add_child(enemy_audio)
	artillery = ArtilleryDirector.new()
	artillery.main = self
	add_child(artillery)
	ambience = AudioStreamPlayer.new()
	ambience.stream = AudioFactory.make_wind()
	ambience.volume_db = -14
	add_child(ambience)
	ambience.play()
	audio_mix.register_player(player.sound, &"Weapons")
	audio_mix.register_player(player.bolt_sound, &"Foley")
	audio_mix.register_player(player.footsteps, &"Foley")
	audio_mix.register_player(enemy_audio, &"Weapons")
	audio_mix.register_player(ambience, &"Ambience", "ambience")
	story = Story.new()
	story.initialize(self)
	linear = LinearDirector.new()
	linear.initialize(self)
	village = VillageDirector.new()
	add_child(village)
	village.initialize(self)
	hud = HUD.new()
	hud.initialize(self)
	add_child(hud)
	presentation = Presentation.new()
	presentation.initialize(self)
	menu_camera = Camera3D.new()
	add_child(menu_camera)
	menu_camera.position = Vector3(26, 3.2, 255)
	menu_camera.look_at(Vector3(37, 1.9, 230))
	menu_camera.fov = 62
	menu_camera.current = true
	melee = BayonetEncounter.new()
	add_child(melee)
	melee.initialize(self)
	audio_mix.start_global_music()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	checkpoint = _snapshot()
	if "--capture" in OS.get_cmdline_user_args():
		_capture_views.call_deferred()

func _process(delta: float) -> void:
	audio_mix.update_mix(delta)
	if world.has_method("update") and mode in ["playing", "dialogue", "briefing"]:
		world.update(delta)
	if mode != "playing":
		_clear_fire_effects()
		return
	elapsed += delta
	message_timer = maxf(0, message_timer - delta)
	hit_marker = maxf(0, hit_marker - delta)
	linear.update(delta)
	_try_office_melee()
	if stage < 3 and not reached_yard and player.position.z < 170 and player.position.z > 122 and "checkpoint" in linear.opened:
		reached_yard = true
		_save_checkpoint()
		notify("进入木料巷。利用两侧木箱推进，清除守卫后打开北侧栅门。", 4)
	_update_reinforcements(delta)

func _unhandled_input(event: InputEvent) -> void:
	if is_instance_valid(village) and village.handle_input(event):
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(melee) and melee.handle_input(event):
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(opening) and opening.handle_input(event):
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("performance_overlay"):
		presentation.change("show_stats", not presentation.show_stats)
		get_viewport().set_input_as_handled()
		return
	if mode == "dialogue" and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_3:
			story.choose(event.physical_keycode - KEY_1)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("journal") and mode in ["playing", "journal"]:
		if mode == "journal":
			resume()
		else:
			mode = "journal"
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("heal"):
		story.heal_player()
	if event.is_action_pressed("pause"):
		if mode == "playing":
			mode = "paused"
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif mode == "paused":
			resume()
		elif mode == "dialogue":
			story.close_dialog()
		elif mode == "journal":
			resume()

func start_new() -> void:
	if is_instance_valid(melee): melee.abort()
	audio_mix.reset_transients()
	if is_instance_valid(opening): opening.abort()
	_clear_fire_effects()
	artillery.clear()
	opening_phase = "gameplay"
	stage = 0
	elapsed = 0
	kills = 0
	defeated.clear()
	reached_yard = false
	reinforcement_pending = 0
	reinforcement_next = 0
	reinforcement_wait = 0.0
	expanded_encounter = true
	encounter_revision = 2
	hold_next = 0
	hold_wait = 0.0
	story.reset()
	linear.reset()
	village.reset()
	player.restore({"position": [START.x, START.y, START.z], "yaw": -0.6, "health": 100.0, "magazines": [5, 10], "reserves": [35, 50], "weapon": 0})
	_reset_guards()
	codebook.visible = true
	codebook.collision_layer = 1
	world.set_power(true)
	_save_checkpoint()
	resume()
	notify("林道前方是侦察员姜岚。靠近后按 F 交谈。J 查看行动记录。", 7)

func start_with_opening() -> void:
	start_new()
	_ensure_opening()
	opening.start("A")
	if not _save_checkpoint():
		opening.set_paused(true)
		notify("开场检查点暂未保存。可继续排演，退出后仍使用上次成功保存。",8)

func _ensure_opening() -> void:
	if is_instance_valid(opening): return
	opening = OpeningDirector.new()
	add_child(opening)
	opening.initialize(self)

func retry_opening_save() -> void:
	if _save_checkpoint():
		resume()
		notify("任务检查点已保存。J查看行动记录。",5)
	else:
		hud.show_menu("opening_save_error")

func return_to_menu() -> void:
	if is_instance_valid(village): village.abort_crossing()
	if is_instance_valid(melee): melee.abort()
	audio_mix.reset_transients()
	if is_instance_valid(opening): opening.abort()
	mode = "briefing"
	menu_camera.current = true
	audio_mix.start_global_music()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func resume() -> void:
	if is_instance_valid(village) and village.crossing:
		village.set_crossing_paused(false)
		return
	if is_instance_valid(melee) and melee.active:
		melee.set_paused(false)
		return
	if is_instance_valid(opening) and opening.active:
		opening.set_paused(false)
		return
	mode = "playing"
	player.camera.current = true
	audio_mix.start_global_music()
	player.model.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func lose() -> void:
	mode = "lost"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func interact() -> void:
	if mode != "playing":
		return
	if village.entered:
		village.interact()
		return
	if linear.interact():
		return
	var at_evac := stage == 2 and can_reach(EVAC, 3.0)
	if at_evac and story.ready_to_leave():
		story.ending()
		return
	var objective_ready: bool = story.met_scout and stage < 2 and can_reach([BOOK, POWER][mini(stage, 1)], 2.3)
	if not objective_ready and story.interact():
		return
	if at_evac:
		story.ending()
		return
	if not story.met_scout or not can_reach([BOOK, POWER, EVAC, EVAC][stage], 2.3):
		return
	match stage:
		0:
			stage = 1
			codebook.visible = false
			codebook.collision_layer = 0
			notify("名册上记着密营联络点。切断总闸，阻止电话中继继续传讯。", 6)
			_save_checkpoint()
		1:
			stage = 2
			world.set_power(false)
			reinforcement_pending = REINFORCEMENT_COUNT if encounter_revision < 2 else 0
			reinforcement_next = 0
			reinforcement_wait = REINFORCEMENT_FIRST_DELAY if encounter_revision < 2 else 0.0
			_save_checkpoint()
			notify("中继电源已切断。接上陆山，绕电报房北侧去渡口！", 6)

func interaction_prompt() -> String:
	if village.entered: return village.interaction_prompt()
	var route_prompt: String = linear.interaction_prompt()
	if not route_prompt.is_empty():
		return route_prompt
	var at_evac := stage == 2 and can_reach(EVAC, 3.0)
	if at_evac and story.ready_to_leave():
		return "F  与陆山一起撤离"
	if story.met_scout and stage < 2 and can_reach([BOOK, POWER][stage], 2.3):
		return ["F  取回搜山名册", "F  拉下总闸"][stage]
	var item: Dictionary = story.candidate()
	if not item.is_empty():
		return item.text
	if at_evac:
		return "掩护陆山解缆" if linear.enabled and linear.extraction_started and not linear.can_evacuate() else "等待陆山到达渡口"
	if not story.met_scout or stage >= 3:
		return ""
	if not can_reach([BOOK, POWER, EVAC, EVAC][stage], 2.3):
		return ""
	return ["F  取回搜山名册", "F  拉下总闸", "F  一起撤离"][stage]

func can_reach(target: Vector3, distance: float) -> bool:
	var origin := player.position + Vector3.UP * 1.2
	if origin.distance_to(target) > distance:
		return false
	# Proximity alone must not let an interaction pass through a brick wall.
	var query := PhysicsRayQueryParameters3D.create(origin, target, 1)
	query.exclude = [player.get_rid()]
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if not result.is_empty() and result.position.distance_to(target) > 0.9:
		return false
	return true

func objective_text() -> String:
	if village.entered: return village.objective_text() if not village.finished else "任务完成 · 松岭屯已肃清"
	var route_objective: String = linear.objective_text()
	if not route_objective.is_empty() and stage < 3:
		return route_objective
	if not story.met_scout:
		return "接头  /  与侦察员姜岚交谈"
	if stage == 2 and not story.recruited:
		return "03 / 03   接应受伤的交通员陆山"
	return ["01 / 03   取回电报房搜山名册", "02 / 03   切断电话中继电源", "03 / 03   带陆山前往林溪渡口", "任务完成"][stage]

func target_name() -> String:
	if village.entered: return village.target_name()
	var route_name: String = linear.target_name()
	if not route_name.is_empty():
		return route_name
	if not story.met_scout:
		return "姜岚"
	if stage == 2 and not story.recruited:
		return "陆山"
	return ["电报房", "总闸", "林溪渡口", "林溪渡口"][stage]

func target_position() -> Vector3:
	if village.entered: return village.target_position()
	if not linear.target_name().is_empty():
		return linear.target_position()
	if not story.met_scout:
		return story.SCOUT
	if stage == 2 and not story.recruited:
		return story.people.lu.position
	return [BOOK, POWER, EVAC, EVAC][stage]

func notify(text: String, duration: float) -> void:
	message = text
	message_timer = duration

func play_world_sound(kind: String, at: Vector3, volume_db: float = -7.0) -> void:
	var player := AudioStreamPlayer3D.new()
	player.name = "WorldSound_%s" % kind
	player.bus = &"Foley"
	player.stream = AudioFactory.make_sound(kind)
	player.volume_db = volume_db
	player.max_distance = 24
	player.unit_size = 4.0
	add_child(player)
	player.global_position = at
	player.add_to_group("world_sounds")
	audio_mix.register_player(player, &"Foley", "world")
	player.finished.connect(player.queue_free)
	player.play()

func hear_shot(position: Vector3) -> void:
	for guard in guards:
		if is_instance_valid(guard):
			guard.hear_shot(position)

func guard_shot(origin: Vector3, target: Vector3, gun: Node3D = null) -> void:
	_prune_fire_effects()
	if active_fire_effects.size() >= 8:
		var oldest: Node3D = active_fire_effects.pop_front()
		if is_instance_valid(oldest): oldest.free()
	var muzzle := MuzzleEffect.new()
	muzzle.name = "GuardMuzzleEffect"
	add_child(muzzle)
	muzzle.trigger(origin, target, gun)
	active_fire_effects.append(muzzle)
	enemy_audio.position = origin
	enemy_audio.play()
	var tracer := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.014, 0.014, origin.distance_to(target))
	tracer.mesh = mesh
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("f5d685")
	tracer.material_override = material
	add_child(tracer)
	tracer.position = (origin + target) * 0.5
	tracer.look_at(target)
	get_tree().create_timer(0.06).timeout.connect(tracer.queue_free)

func impact(position: Vector3) -> void:
	var marker := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.045
	mesh.height = 0.09
	marker.mesh = mesh
	marker.material_override = world.materials["paper"]
	marker.position = position
	add_child(marker)
	get_tree().create_timer(0.15).timeout.connect(marker.queue_free)

func active_fire_effect_count() -> int:
	_prune_fire_effects()
	return active_fire_effects.size()

func _prune_fire_effects() -> void:
	for index in range(active_fire_effects.size() - 1, -1, -1):
		if not is_instance_valid(active_fire_effects[index]):
			active_fire_effects.remove_at(index)

func _clear_fire_effects() -> void:
	for effect in active_fire_effects:
		if is_instance_valid(effect): effect.free()
	active_fire_effects.clear()

func alive_guard_count() -> int:
	var count := 0
	for guard in guards:
		if is_instance_valid(guard) and guard.state != "dead":
			count += 1
	return count

func _spawn_guard(identifier: String, position: Vector3, patrol: Vector3) -> CharacterBody3D:
	if defeated.has(identifier) or alive_guard_count() >= (MAX_ALIVE_GUARDS if encounter_revision >= 2 else 6):
		return null
	for existing in guards:
		if is_instance_valid(existing) and existing.guard_id == identifier:
			return null
	var guard = Guard.new()
	guard.initialize(self, identifier, position, patrol)
	add_child(guard)
	guards.append(guard)
	return guard

func _spawn_initial_guards() -> void:
	var roster := initial_roster()
	for identifier in roster:
		if expanded_encounter or identifier in LEGACY_INITIAL_IDS:
			_spawn_guard(identifier, roster[identifier][0], roster[identifier][1])

func initial_roster() -> Dictionary:
	if is_instance_valid(village) and village.entered: return VillageDirector.ENEMIES.duplicate(true)
	var roster := INITIAL_GUARDS.duplicate(true)
	if encounter_revision >= 2:
		roster.merge(ADDED_GUARDS)
		roster.office_guard = [Vector3(46, 0.08, 34), Vector3(46, 0.08, 38)]
	return roster

func _try_office_melee() -> void:
	if stage >= 3 or encounter_revision < 2 or mode != "playing" or not story.door_open or "yard" not in linear.opened:
		return
	if melee.can_begin():
		if _save_checkpoint(): melee.begin()
		else: notify("突袭前检查点保存失败。" + last_save_error, 4)

func _reset_guards(saved_guards: Dictionary = {}) -> void:
	for guard in guards:
		if is_instance_valid(guard):
			guard.free()
	guards.clear()
	_spawn_initial_guards()
	if stage == 2:
		for index in reinforcement_next:
			_spawn_guard("wave_%d" % index, REINFORCEMENT_ENTRIES[index], EVAC)
	for identifier in saved_guards:
		if stage < 3 and identifier.begins_with("hold_"):
			var at: Array = saved_guards[identifier].position
			_spawn_guard(identifier, Vector3(at[0], at[1], at[2]), EVAC)
	for guard in guards:
		if saved_guards.has(guard.guard_id):
			guard.restore_encounter(saved_guards[guard.guard_id])
	reinforcement_pending = REINFORCEMENT_COUNT - reinforcement_next if stage == 2 and encounter_revision < 2 else 0

func _update_reinforcements(delta: float) -> void:
	if encounter_revision >= 2:
		_update_hold_reinforcements(delta)
		return
	if mode != "playing" or stage != 2 or reinforcement_next >= REINFORCEMENT_COUNT:
		return
	if linear.enabled and "river" not in linear.opened:
		return
	reinforcement_wait = maxf(0.0, reinforcement_wait - delta)
	if reinforcement_wait > 0.0 or alive_guard_count() >= 6:
		return
	var entry: Vector3 = REINFORCEMENT_ENTRIES[reinforcement_next]
	if not _reinforcement_entry_safe(entry):
		reinforcement_wait = 0.5
		return
	var guard := _spawn_guard("wave_%d" % reinforcement_next, entry, EVAC)
	if guard == null:
		return
	guard.hear_shot(EVAC)
	reinforcement_next += 1
	reinforcement_pending = REINFORCEMENT_COUNT - reinforcement_next
	reinforcement_wait = REINFORCEMENT_WAVE_DELAY if reinforcement_next % 2 == 0 else REINFORCEMENT_INTERVAL
	if reinforcement_pending == 0:
		reinforcement_wait = 0.0
	_save_checkpoint()

func _update_hold_reinforcements(delta: float) -> void:
	if mode != "playing" or stage != 2 or not linear.extraction_started or linear.extraction_remaining <= 0:
		return
	for guard in guards:
		if is_instance_valid(guard) and guard.state != "dead" and guard.guard_id.begins_with("hold_"):
			return
	hold_wait = maxf(0, hold_wait - delta)
	if hold_wait > 0 or hold_next >= HOLD_MAX_ISSUED: return
	# The fixed road entrance sits behind the timber stack, away from the boat.
	# Two soldiers every one-second gap doubles the previous single/pair cadence.
	var amount := 2
	for index in amount:
		var entry: Vector3 = REINFORCEMENT_ENTRIES[index]
		if player.position.distance_to(entry) < 12 or world.path(entry, EVAC).is_empty(): continue
		var guard := _spawn_guard("hold_%d" % hold_next, entry, EVAC)
		if guard != null:
			guard.hear_shot(EVAC)
			guard.sight_memory = 6
			hold_next += 1
	hold_wait = HOLD_RESPAWN_DELAY
	_save_checkpoint()

func _reinforcement_entry_safe(entry: Vector3) -> bool:
	if player.position.distance_to(entry) < 18.0:
		return false
	for guard in guards:
		if is_instance_valid(guard) and guard.state != "dead" and guard.position.distance_to(entry) < 2.0:
			return false
	var origin: Vector3 = player.camera.global_position
	var target := entry + Vector3.UP * 1.2
	var offset := target - origin
	# Delay a visible arrival; never pick a new spawn point around the player.
	if -player.camera.global_basis.z.dot(offset.normalized()) > 0.5:
		var ray := PhysicsRayQueryParameters3D.create(origin, target, 1)
		ray.exclude = [player.get_rid()]
		if get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			return false
	return not world.path(entry, EVAC).is_empty()

func register_guard_defeat(identifier: String) -> void:
	if defeated.has(identifier):
		return
	defeated[identifier] = true
	kills += 1
	if identifier.begins_with("hold_"): hold_wait = HOLD_RESPAWN_DELAY
	# Persist the encounter at the same time as ammunition/player/story state.
	if mode == "playing" and player.health > 0:
		_save_checkpoint()

func _snapshot() -> Dictionary:
	var active: Dictionary = {}
	for guard in guards:
		if is_instance_valid(guard) and guard.state != "dead":
			active[guard.guard_id] = guard.encounter_snapshot()
	return {"version": 2, "map_revision": Layout.REVISION, "village": village.snapshot(), "player": player.snapshot(), "story": story.snapshot(), "stage": stage, "defeated": defeated.duplicate(), "kills": kills, "elapsed": elapsed, "yard": reached_yard,
		"opening": {"version": 1, "phase": opening_phase},
		"linear": linear.snapshot(), "encounter": {"revision": encounter_revision, "expanded": expanded_encounter, "next": reinforcement_next, "wait": reinforcement_wait, "hold_next": hold_next, "hold_wait": hold_wait, "active": active}}

func _save_checkpoint() -> bool:
	# Keep the complete departure checkpoint until both passengers reach land.
	if is_instance_valid(village) and village.crossing: return false
	# An unfinished grapple always restores the complete pre-door checkpoint.
	if is_instance_valid(melee) and melee.active: return false
	checkpoint = _snapshot()
	# Replace only after a complete write; failed writes preserve the last good file.
	var pending := save_path + ".pending"
	var file := FileAccess.open(pending, FileAccess.WRITE)
	last_save_error = ""
	if file == null:
		last_save_error = "无法创建存档临时文件。"
		return false
	file.store_string(JSON.stringify(checkpoint))
	file.flush()
	var error := file.get_error()
	file.close()
	if error == OK:
		error = DirAccess.rename_absolute(ProjectSettings.globalize_path(pending),ProjectSettings.globalize_path(save_path))
	if error != OK:
		last_save_error = "写入检查点失败（%s），此前存档保留。" % error_string(error)
		return false
	return true

func has_save() -> bool:
	return not _read_save().is_empty()

func _read_save() -> Dictionary:
	invalid_opening_save = false
	if not FileAccess.file_exists(save_path):
		return {}
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return {}
	var result = parser.data
	if not result is Dictionary or result.get("version") != 2 or not result.get("player") is Dictionary:
		return {}
	# Old finished saves stopped at the ferry. Reopen that departure so the
	# player can continue into the added chapter without losing the rescue.
	if not result.has("village") and result.get("stage") == 3:
		result.stage = 2
		if result.get("linear") is Dictionary:
			result.linear.extraction_started = true
			result.linear.extraction_remaining = 0.0
	if not result.get("story") is Dictionary: return {}
	# Validate old coordinates before migration, then validate the new chapter bounds.
	if not _valid_layout_migration(result): return {}
	Layout.migrate(result)
	if not story.valid(result.get("story")):
		return {}
	if result.has("linear") and not linear.valid_snapshot(result.linear):
		return {}
	if not village.valid_snapshot(result.get("village", {})): return {}
	var in_village: bool = result.get("village", {}).get("entered", false)
	if not _whole_number(result.get("stage"), 0, 4) or in_village != (int(result.stage) >= 3):
		return {}
	if in_village and (result.village.finished != (int(result.stage) == 4) or not result.story.recruited): return {}
	var lu_at: Array = result.story.lu_position
	if VillageDirector.VillageWorld.contains(Vector3(lu_at[0], lu_at[1], lu_at[2])) != in_village: return {}
	if not result.get("defeated") is Dictionary or not result.get("yard") is bool:
		return {}
	if not _valid_encounter(result):
		return {}
	for identifier in result.defeated:
		if not identifier is String: return {}
		if (identifier not in INITIAL_GUARDS and identifier not in ADDED_GUARDS and identifier not in VillageDirector.ENEMIES and identifier not in ["wave_0", "wave_1", "wave_2", "wave_3"] and not _valid_hold_id(identifier, result.get("encounter", {}).get("hold_next", 0))) or result.defeated[identifier] != true:
			return {}
	if not _whole_number(result.get("kills"), 0, HOLD_MAX_ISSUED + 28) or int(result.kills) != result.defeated.size():
		return {}
	if not _valid_encounter(result):
		return {}
	if not _number_between(result.get("elapsed"), 0, 10000000):
		return {}
	var saved_player: Dictionary = result.player
	for key in ["position", "magazines", "reserves"]:
		if not saved_player.get(key) is Array or saved_player[key].size() != (3 if key == "position" else 2):
			return {}
	for coordinate in saved_player.position:
		if not _number_between(coordinate,-.1,1290): return {}
	var at := Vector3(saved_player.position[0],saved_player.position[1],saved_player.position[2])
	var valid_position: bool = VillageDirector.VillageWorld.contains(at) if in_village else Layout.contains(at)
	if not valid_position:
		return {}
	if not _number_between(saved_player.get("health"), 0.1, 100) or not _number_between(saved_player.get("yaw"), -100000, 100000) or not _whole_number(saved_player.get("weapon"), 0, 1):
		return {}
	for index in 2:
		if not _whole_number(saved_player.magazines[index], 0, Player.WEAPONS[index].capacity) or not _whole_number(saved_player.reserves[index], 0, 1000):
			return {}
	if not _valid_opening_snapshot(result):
		invalid_opening_save = true
		return {}
	village.migrate_layout(result)
	return result

func _valid_layout_migration(data: Dictionary) -> bool:
	if not _whole_number(data.get("map_revision",0),0,Layout.REVISION): return false
	if data.has("village") and not data.village is Dictionary: return false
	if data.has("encounter") and not data.encounter is Dictionary: return false
	if data.get("encounter",{}).has("active") and not data.encounter.active is Dictionary: return false
	if int(data.get("map_revision",0))>=Layout.REVISION or data.get("village",{}).get("entered",false): return true
	for pair in [[data.player,"position"],[data.story,"lu_position"]]:
		var point = pair[0].get(pair[1])
		if not point is Array or point.size()!=3: return false
		if not _number_between(point[0],4.4,83.6) or not _number_between(point[1],-.1,6) or not _number_between(point[2],4.4,91.6): return false
	for record in data.get("encounter",{}).get("active",{}).values():
		if not record is Dictionary: return false
		for key in ["position","patrol","last_seen"]:
			var point = record.get(key)
			if not point is Array or point.size()!=3: return false
			for value in point:
				if not _number_between(value,0,100): return false
	return true

func _valid_opening_snapshot(data: Dictionary) -> bool:
	if not data.has("opening"): return true # Legacy gameplay remains unchanged.
	var state = data.opening
	if not state is Dictionary or state.get("version") != 1 or state.get("phase") not in ["history","task","gameplay"]: return false
	if state.phase == "gameplay": return true
	var saved_story: Dictionary = data.story
	var route: Dictionary = data.get("linear",{})
	var encounter: Dictionary = data.get("encounter",{})
	var hold_duration := 12.0 if int(route.get("version", 1)) == 1 else LinearDirector.HOLD_DURATION
	return int(data.stage)==0 and int(data.kills)==0 and float(data.elapsed)==0 and not data.yard and data.defeated.is_empty() and not saved_story.briefed and not saved_story.recruited and not saved_story.following and not saved_story.treated and not saved_story.supply and not saved_story.letter and not saved_story.door and saved_story.choice=="none" and int(saved_story.bandages)==1 and saved_story.get("moments_seen",[]).is_empty() and Vector3(saved_story.lu_position[0],saved_story.lu_position[1],saved_story.lu_position[2]).is_equal_approx(Story.WOUNDED) and Vector3(data.player.position[0],data.player.position[1],data.player.position[2]).is_equal_approx(START) and int(data.player.health)==100 and int(data.player.magazines[0])==5 and int(data.player.magazines[1])==10 and int(data.player.reserves[0])==35 and int(data.player.reserves[1])==50 and int(data.player.weapon)==0 and route.get("enabled",false) and route.get("opened",[]).is_empty() and not route.get("contact_started",true) and not route.get("extraction_started",true) and float(route.get("extraction_remaining",0))==hold_duration and encounter.get("expanded",false) and int(encounter.get("next",-1))==0

func _valid_hold_id(identifier: String, issued: int) -> bool:
	if not identifier.begins_with("hold_"): return false
	var suffix := identifier.trim_prefix("hold_")
	return suffix.is_valid_int() and str(int(suffix)) == suffix and int(suffix) >= 0 and int(suffix) < issued

func _valid_encounter(data: Dictionary) -> bool:
	if not data.has("encounter"):
		for identifier in data.defeated:
			if identifier not in LEGACY_INITIAL_IDS and identifier not in ["wave_0", "wave_1"]:
				return false
			if int(data.stage) < 2 and identifier in ["wave_0", "wave_1"]:
				return false
		return true
	var saved = data.encounter
	if not saved is Dictionary or not saved.get("expanded") is bool or not saved.get("active") is Dictionary:
		return false
	if not _whole_number(saved.get("next"), 0, REINFORCEMENT_COUNT) or not _number_between(saved.get("wait"), 0, REINFORCEMENT_WAVE_DELAY):
		return false
	if int(data.stage) < 2 and (int(saved.next) != 0 or float(saved.wait) != 0.0):
		return false
	if not _whole_number(saved.get("revision", 1), 1, 2): return false
	var revision: int = saved.get("revision", 1)
	var roster := INITIAL_GUARDS.duplicate()
	if revision == 2:
		roster.merge(ADDED_GUARDS)
		if not saved.expanded or int(saved.next) != 0 or float(saved.wait) != 0: return false
		if not _whole_number(saved.get("hold_next"), 0, HOLD_MAX_ISSUED) or not _number_between(saved.get("hold_wait"), 0, 2.0): return false
		if int(data.stage) < 2 and (int(saved.hold_next) != 0 or float(saved.hold_wait) != 0): return false
	var expected: Array = roster.keys() if saved.expanded else LEGACY_INITIAL_IDS.duplicate()
	for index in int(saved.next):
		expected.append("wave_%d" % index)
	if revision == 2:
		for index in int(saved.hold_next): expected.append("hold_%d" % index)
	var in_village: bool = data.get("village", {}).get("entered", false)
	if in_village: expected = VillageDirector.ENEMIES.keys()
	for identifier in data.defeated:
		if in_village and identifier not in VillageDirector.ENEMIES: continue
		if identifier not in expected:
			return false
		expected.erase(identifier)
	if expected.size() > (MAX_ALIVE_GUARDS if revision == 2 else 6) or saved.active.size() != expected.size():
		return false
	for identifier in expected:
		if not saved.active.has(identifier) or not Guard.valid_encounter(saved.active[identifier]):
			return false
		var at: Array = saved.active[identifier].position
		if (float(at[0]) > 900) != in_village: return false
	if in_village:
		for index in 12:
			if index / 4 < int(data.village.phase) and not data.defeated.has("village_%d" % index): return false
		if data.village.finished:
			for id in VillageDirector.ENEMIES:
				if not data.defeated.has(id): return false
	return true

func _number_between(value: Variant, minimum: float, maximum: float) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and float(value) >= minimum and float(value) <= maximum

func _whole_number(value: Variant, minimum: int, maximum: int) -> bool:
	return _number_between(value, minimum, maximum) and float(value) == floorf(float(value))

func continue_checkpoint() -> void:
	if is_instance_valid(melee): melee.abort()
	audio_mix.reset_transients()
	var data := _read_save()
	if invalid_opening_save:
		if is_instance_valid(opening): opening.abort()
		mode = "opening_load_error"
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if data.is_empty():
		data = checkpoint
	if data.is_empty():
		start_new()
		return
	if is_instance_valid(opening): opening.abort()
	_clear_fire_effects()
	artillery.clear()
	opening_phase = data.get("opening",{}).get("phase","gameplay")
	stage = int(data.stage)
	defeated = data.defeated.duplicate()
	kills = int(data.kills)
	elapsed = float(data.elapsed)
	reached_yard = data.yard
	var encounter: Dictionary = data.get("encounter", {})
	expanded_encounter = encounter.get("expanded", false)
	encounter_revision = int(encounter.get("revision", 1))
	hold_next = int(encounter.get("hold_next", 0))
	hold_wait = minf(HOLD_RESPAWN_DELAY, float(encounter.get("hold_wait", 0.0)))
	reinforcement_next = int(encounter.get("next", 2 if stage >= 2 else 0))
	reinforcement_wait = float(encounter.get("wait", REINFORCEMENT_WAVE_DELAY if stage >= 2 else 0.0))
	player.restore(data.player)
	story.restore(data.story)
	linear.restore(data.get("linear", {}))
	village.restore(data.get("village", {}))
	_reset_guards(encounter.get("active", {}))
	# Earlier saves may be inside newly added S09 structures. Move only actors
	# actually intersecting those footprints; gate, inventory and mission state stay intact.
	if not village.entered:
		player.position = world.route_blockout.restore_position(player.position)
		story.people.lu.position = world.route_blockout.restore_position(story.people.lu.position)
		player.position = world.relocate_to_walkable(player.position)
		story.people.lu.position = world.relocate_to_walkable(story.people.lu.position)
	player.reset_physics_interpolation()
	story.people.lu.reset_physics_interpolation()
	for guard in guards:
		if not village.entered:
			guard.position = world.route_blockout.restore_position(guard.position)
			guard.patrol_target = world.route_blockout.restore_position(guard.patrol_target)
		guard.reset_physics_interpolation()
	if not village.entered and (not data.has("linear") or int(data.get("map_revision", 0)) < 3):
		# Old positions may overlap the new partitions. Only displaced actors move.
		player.position = world.relocate_to_walkable(player.position)
		story.people.lu.position = world.relocate_to_walkable(story.people.lu.position)
		player.reset_physics_interpolation()
		story.people.lu.reset_physics_interpolation()
		for guard in guards:
			guard.position = world.relocate_to_walkable(guard.position)
			guard.patrol_target = world.relocate_to_walkable(guard.patrol_target)
			guard.reset_physics_interpolation()
	codebook.visible = stage == 0
	codebook.collision_layer = 1 if stage == 0 else 0
	world.set_power(stage < 2)
	if opening_phase in ["history","task"]:
		_ensure_opening()
		opening.start("A" if opening_phase=="history" else "B")
		return
	resume()
	if village.finished:
		mode = "won"
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	notify("检查点已恢复。", 2)

func elapsed_text() -> String:
	return "%02d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]

func _configure_input() -> void:
	var keys := {"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A, "move_right": KEY_D, "sprint": KEY_SHIFT, "crouch": KEY_C, "crouch_hold": KEY_CTRL, "lean_left": KEY_Q, "lean_right": KEY_E, "jump": KEY_SPACE, "reload": KEY_R, "interact": KEY_F, "weapon_1": KEY_1, "weapon_2": KEY_2, "pause": KEY_ESCAPE, "journal": KEY_J, "heal": KEY_H, "performance_overlay": KEY_F3}
	for action in keys:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		InputMap.add_action(action)
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)
	for action in ["fire", "aim"]:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		InputMap.add_action(action)
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT if action == "fire" else MOUSE_BUTTON_RIGHT
		InputMap.action_add_event(action, event)

func _capture_views() -> void:
	var directory := OS.get_environment("FENGHUO_CAPTURE_DIR")
	if directory.is_empty():
		directory = ProjectSettings.globalize_path("res://captures")
	DirAccess.make_dir_recursive_absolute(directory)
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join("title.png"))
	hud._show_settings()
	await get_tree().create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join("settings.png"))
	start_new()
	for guard in guards:
		guard.set_physics_process(false)
	player.position = Vector3(12, 0.08, 284.4)
	player.rotation.y = 0
	await get_tree().create_timer(0.2).timeout
	story.talk("scout")
	await get_tree().create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join("conversation.png"))
	story.choose(0)
	linear.opened.assign(["checkpoint"])
	linear.contact_started = true
	linear._sync_gates()
	player.position = Vector3(30, 0.08, 132)
	player.rotation.y = -0.45
	await get_tree().create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join("yard.png"))
	linear.opened.assign(["checkpoint", "yard"])
	linear._sync_gates()
	player.position = Vector3(49, 0.08, 37)
	player.rotation.y = -1.1
	await get_tree().create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join("office.png"))
	player.position = Vector3(48.8, 0.08, 30)
	story.talk("lu")
	await get_tree().create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join("rescue.png"))
	story.choose(0)
	mode = "journal"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join("journal.png"))
	resume()
	stage = 2
	world.set_power(false)
	linear.opened.assign(["checkpoint", "yard", "river"])
	linear._sync_gates()
	story.people.lu.position = EVAC + Vector3(-3, 0, 0)
	player.position = Vector3(80, 0.08, 14)
	player.rotation.y = -PI * 0.5
	player.pitch = -0.08
	player.reset_physics_interpolation()
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join("river.png"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CAPTURE_SAVE_PATH))
	get_tree().quit()

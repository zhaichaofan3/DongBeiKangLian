extends Node
## Playback and bus ownership. User-supplied global score is separate from the mixed history track.

const GLOBAL_MUSIC = preload("res://assets/audio/global_war_music.ogg")
var global_music: AudioStreamOggVorbis = GLOBAL_MUSIC

const BUS_NAMES := [&"Cinematic", &"Weapons", &"Foley", &"Ambience", &"Music", &"Voice"]
const FROZEN_MODES := ["paused", "journal", "cinematic_paused", "crossing_paused"]
var main: Node3D
var entries: Array[Dictionary] = []
var music: Array[AudioStreamPlayer] = []
var voice: AudioStreamPlayer
var current_slot := -1
var music_key := ""
var music_gain := [0.0, 0.0]
var fade_from := [0.0, 0.0]
var fade_target := [0.0, 0.0]
var fade_elapsed := 0.0
var fade_seconds := 0.75
var music_base_db := [-12.0, -12.0]
var duck_db := 0.0
var last_mode := ""

func initialize(owner_node: Node3D) -> void:
	main = owner_node
	global_music.loop = true
	name = "AudioMix"
	# Sends must point left. Keep the opening master before all category buses,
	# including when reusing buses after a scene reload.
	if AudioServer.get_bus_index(&"Cinematic") < 0:
		AudioServer.add_bus(1)
		AudioServer.set_bus_name(1, &"Cinematic")
	elif AudioServer.get_bus_index(&"Cinematic") != 1:
		AudioServer.move_bus(AudioServer.get_bus_index(&"Cinematic"), 1)
	for bus in BUS_NAMES:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus)
			_set_send(index, &"Master")
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), 0)
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = &"Music"
		player.volume_db = -80
		add_child(player)
		music.append(player)
	voice = AudioStreamPlayer.new()
	voice.bus = &"Voice"
	add_child(voice)

func register_player(player: Node, bus: StringName, scope: String = "gameplay") -> void:
	player.bus = bus
	for entry in entries:
		if entry.node.get_ref() == player: return
	entries.append({"node":weakref(player), "scope":scope})

func _stop(player: Node) -> void:
	# Godot needs pause released before stop to retire a paused playback voice.
	player.stream_paused = false
	player.stop()

func update_mix(delta: float) -> void:
	var mode: String = main.mode
	var frozen: bool = mode in FROZEN_MODES
	if mode != last_mode and mode in ["briefing", "lost", "opening_load_error", "opening_save_error"]:
		reset_transients()
		start_global_music()
	last_mode = mode
	for index in range(entries.size()-1, -1, -1):
		var entry := entries[index]
		var player: Node = entry.node.get_ref()
		if not is_instance_valid(player):
			entries.remove_at(index)
			continue
		if entry.scope == "ambience":
			player.stream_paused = frozen or mode not in ["playing", "dialogue", "cinematic", "melee", "won", "crossing"]
		elif entry.scope == "transition":
			player.stream_paused = mode!="crossing"
		elif entry.scope == "world":
			player.stream_paused = mode not in ["playing", "melee"]
		else:
			player.stream_paused = mode != "playing"
	voice.stream_paused = frozen
	for player in music: player.stream_paused = frozen
	if frozen: return
	var speech_active: bool = voice.playing or mode == "dialogue"
	if is_instance_valid(main.opening) and main.opening.active:
		speech_active = speech_active or not main.opening.current_cue.is_empty()
	if main.story != null and is_instance_valid(main.story.moments):
		speech_active = speech_active or not main.story.moments.caption.is_empty()
	var target_db := -10.0 if speech_active else 0.0
	duck_db = move_toward(duck_db, target_db, delta * (45.0 if speech_active else 12.0))
	apply_category_volumes()
	fade_elapsed = minf(fade_seconds, fade_elapsed + delta)
	var t := smoothstep(0.0, fade_seconds, fade_elapsed)
	for i in 2:
		music_gain[i] = lerpf(fade_from[i], fade_target[i], t)
		music[i].volume_db = music_base_db[i] + linear_to_db(maxf(music_gain[i], 0.0001))
		if fade_elapsed >= fade_seconds and fade_target[i] == 0.0 and music[i].playing:
			_stop(music[i])

func apply_music_volume() -> void:
	apply_category_volumes()

func apply_category_volumes() -> void:
	var settings = main.presentation
	var in_opening: bool = (is_instance_valid(main.opening) and main.opening.active) or (is_instance_valid(main.village) and main.village.crossing)
	for bus in BUS_NAMES:
		var index := AudioServer.get_bus_index(bus)
		_set_send(index, &"Cinematic" if in_opening and bus != &"Cinematic" else &"Master")
	_set_level(&"Music", settings.music_volume if settings != null else 0.22, duck_db)
	var sfx: float = settings.sfx_volume if settings != null else 1.0
	_set_level(&"Weapons", sfx)
	_set_level(&"Foley", sfx)
	_set_level(&"Ambience", sfx, duck_db * 0.3)
	_set_level(&"Voice", settings.dialogue_volume if settings != null else 1.0)
	_set_level(&"Cinematic", settings.cinematic_volume if settings != null else 1.0)

func _set_send(index: int, target: StringName) -> void:
	if AudioServer.get_bus_send(index) == target: return
	# The mixer reads send names between two map lookups; synchronize changes.
	AudioServer.lock()
	AudioServer.set_bus_send(index, target)
	AudioServer.unlock()

func _set_level(bus: StringName, level: float, offset_db: float = 0.0) -> void:
	var index := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(level, 0.0001)) + offset_db)
	AudioServer.set_bus_mute(index, level <= 0.0)

func start_global_music() -> void:
	if is_instance_valid(main.opening) and main.opening.active and main.opening.part == "A":
		return
	set_music("user_global_20261015", global_music, 1.5, 0.0)
	apply_music_volume()

func stop_music_immediate() -> void:
	for player in music: _stop(player)
	music_gain = [0.0, 0.0]
	fade_from = [0.0, 0.0]
	fade_target = [0.0, 0.0]
	current_slot = -1
	music_key = ""

func set_music(key: String, stream: AudioStream, seconds: float = 0.75, gain_db: float = -12.0) -> void:
	if stream == null:
		stop_music(seconds)
		return
	if current_slot >= 0 and music_key == key and music[current_slot].stream == stream and music[current_slot].playing:
		return
	# Rapid transitions recycle the quieter slot. The pool never grows beyond two.
	var slot := 0 if music_gain[0] < music_gain[1] else 1
	if is_equal_approx(music_gain[0], music_gain[1]):
		slot = 0 if current_slot < 0 else 1-current_slot
	_stop(music[slot])
	music[slot].stream = stream
	music[slot].volume_db = -80
	music_gain[slot] = 0.0
	music[slot].play()
	music[slot].stream_paused = main.mode in FROZEN_MODES
	current_slot = slot
	music_key = key
	music_base_db[slot] = clampf(gain_db, -60, 0)
	_begin_fade(slot, seconds)

func _begin_fade(slot: int, seconds: float) -> void:
	fade_from = music_gain.duplicate()
	fade_target = [1.0 if slot == 0 else 0.0, 1.0 if slot == 1 else 0.0]
	fade_elapsed = 0.0
	fade_seconds = maxf(seconds, 0.05)

func stop_music(seconds: float = 0.75) -> void:
	music_key = ""
	current_slot = -1
	_begin_fade(-1, seconds)

func play_voice(stream: AudioStream, at_seconds: float = 0.0, mixed_history: bool = false) -> void:
	_stop(voice)
	# The supplied history file contains both speech and music; adjust the
	# complete recording with the opening master, without two category gains.
	voice.bus = &"Cinematic" if mixed_history else &"Voice"
	apply_category_volumes()
	voice.stream = stream
	if stream != null:
		voice.play(maxf(at_seconds, 0))
		voice.stream_paused = main.mode in FROZEN_MODES

func reset_transients() -> void:
	for entry in entries:
		var player: Node = entry.node.get_ref()
		if is_instance_valid(player) and entry.scope != "ambience":
			_stop(player)
			if player.is_in_group("world_sounds"): player.queue_free()
	stop_music_immediate()
	_stop(voice)
	music_gain = [0.0,0.0]
	fade_from = [0.0,0.0]
	fade_target = [0.0,0.0]
	current_slot = -1
	music_key = ""
	duck_db = 0.0
	voice.bus = &"Voice"
	apply_category_volumes()

func _exit_tree() -> void:
	for bus in BUS_NAMES:
		var index := AudioServer.get_bus_index(bus)
		if index >= 0:
			_set_send(index, &"Master")
			AudioServer.set_bus_volume_db(index, 0)
			AudioServer.set_bus_mute(index, false)

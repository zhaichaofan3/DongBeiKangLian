extends Node3D
## Short, optional lines spoken during play. Progression never waits on them.

const IDS := ["departure", "cloth", "contact", "power", "falling_behind", "crossing", "river"]
const RIVER := preload("res://assets/audio/user_sfx_20261015/river.mp3")
const RADIO := preload("res://assets/audio/radio_room_loop.wav")
const SWITCH := preload("res://assets/audio/power_switch_off.wav")
var main: Node3D
var seen: Array[String] = []
var caption := ""
var remaining := 0.0
var silence := 0.0
var last_stage := 0
var river_audio: AudioStreamPlayer3D
var radio_audio: AudioStreamPlayer3D
var switch_audio: AudioStreamPlayer3D

func initialize(owner_node: Node3D) -> void:
	main = owner_node
	name = "StoryMoments"
	river_audio = _spatial_loop(RIVER, Vector3(85, 0.6, 14), -18.0, 29.0)
	radio_audio = _spatial_loop(RADIO, Vector3(56, 1.4, 33), -22.0, 15.0)
	switch_audio = AudioStreamPlayer3D.new()
	switch_audio.bus = &"Foley"
	switch_audio.stream = SWITCH
	switch_audio.position = main.POWER
	switch_audio.volume_db = -13
	switch_audio.max_distance = 18
	add_child(switch_audio)
	reset()

func _spatial_loop(source: AudioStream, at: Vector3, gain: float, distance: float) -> AudioStreamPlayer3D:
	# Loop metadata belongs to this player; preserve the shared source asset.
	var stream := source.duplicate() as AudioStream
	if stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = roundi(wav.get_length() * wav.mix_rate)
	var audio := AudioStreamPlayer3D.new()
	audio.bus = &"Ambience"
	audio.stream = stream
	audio.position = at
	audio.volume_db = gain
	audio.unit_size = 3.0
	audio.max_distance = distance
	add_child(audio)
	return audio

func reset() -> void:
	seen.clear()
	caption = ""
	remaining = 0
	silence = 1.5
	sync_stage()

func sync_stage() -> void:
	last_stage = main.stage
	switch_audio.stream_paused = false
	switch_audio.stop()
	if not river_audio.playing:
		river_audio.play()
	if main.stage < 2:
		if not radio_audio.playing:
			radio_audio.play()
	else:
		radio_audio.stream_paused = false
		radio_audio.stop()

func restore(flags: Array) -> void:
	reset()
	for id in flags:
		if id is String and id in IDS and id not in seen:
			seen.append(id)

static func valid_flags(value: Variant) -> bool:
	if not value is Array or value.size() > IDS.size():
		return false
	for id in value:
		if not id is String or id not in IDS:
			return false
	return true

func _process(delta: float) -> void:
	if not is_instance_valid(main):
		return
	var active: bool = main.mode == "playing"
	river_audio.stream_paused = not active
	radio_audio.stream_paused = not active
	switch_audio.stream_paused = not active
	if not active:
		return
	if last_stage != main.stage:
		if last_stage < 2 and main.stage == 2:
			radio_audio.stop()
			switch_audio.play()
			_say("power", "陆山：灯灭了……他们会回来，别在门口停。")
		last_stage = main.stage
	remaining = maxf(0, remaining - delta)
	if remaining > 0:
		return
	caption = ""
	silence = maxf(0, silence - delta)
	if silence > 0:
		return
	var story: RefCounted = main.story
	var player_at: Vector3 = main.player.position
	var lu: CharacterBody3D = story.people.lu
	if story.recruited and main.stage == 2:
		if player_at.distance_to(main.EVAC) < 12 and lu.position.distance_to(main.EVAC) < 14:
			if _say("river", "陆山：听见水了。把名单揣进衣服里，别让它湿了。"):
				return
		if lu.following and lu.position.distance_to(player_at) > 16:
			if _say("falling_behind", "陆山：等一下……这条腿跟不上了。"):
				return
		if player_at.x > 66 and player_at.z < 31 and lu.position.distance_to(player_at) < 7:
			if _say("crossing", "陆山：从前这条路，我闭着眼也走得过。"):
				return
	if not story.met_scout:
		return
	if "contact" not in seen:
		for guard in main.guards:
			if is_instance_valid(guard) and guard.state == "combat" and player_at.distance_to(guard.position) < 28:
				_say("contact", "沈砚：有人！先找掩护。")
				return
	if story.supply_choice == "medicine" and player_at.distance_to(story.LOGGER) < 7:
		if _say("cloth", "林守义：这是家里剩下的干布……给他扎紧些。"):
			return
	if main.stage == 0 and player_at.x < 22 and player_at.z < story.LOGGER.z + 13 and player_at.z > story.LOGGER.z - 4:
		_say("departure", "沈砚：先把人带出去。名单上的名字，一个也不能丢。")

func _say(id: String, text: String) -> bool:
	if id in seen:
		return false
	seen.append(id)
	caption = text
	remaining = 5.2
	silence = 4.0
	return true

extends RefCounted

static var explosion_preview: AudioStream

const RIFLE_RECORDING: AudioStreamWAV = preload("res://assets/audio/rifle_arisaka_01.wav")
const GRASS_FOOTSTEP: AudioStreamWAV = preload("res://assets/audio/step_grass_01.wav")
const FOREST_WIND: AudioStreamWAV = preload("res://assets/audio/forest_wind_loop.wav")
const USER_RELOAD = preload("res://assets/audio/user_sfx_20261015/reload.mp3")
const USER_RIVER = preload("res://assets/audio/user_sfx_20261015/river.mp3")
const USER_STEP_RUN = preload("res://assets/audio/user_sfx_20261015/step_run.mp3")
const USER_GUNSHOT = preload("res://assets/audio/user_sfx_20261015/gunshot.mp3")
const USER_ALERTS = [
	preload("res://assets/audio/user_sfx_20261015/alert_1.mp3"),
	preload("res://assets/audio/user_sfx_20261015/alert_2.mp3"),
	preload("res://assets/audio/user_sfx_20261015/alert_3.mp3")]
const USER_EXPLOSION = preload("res://assets/audio/user_sfx_20261015/explosion.mp3")
const USER_STEP_WALK = preload("res://assets/audio/user_sfx_20261015/step_walk.mp3")
const USER_DOOR_CLOSE = preload("res://assets/audio/user_sfx_20261015/door_close.mp3")
const USER_DOOR_OPEN = preload("res://assets/audio/user_sfx_20261015/door_open.mp3")

static func make_sound(kind: String) -> AudioStream:
	if kind == "explosion_preview" and explosion_preview != null: return explosion_preview
	if kind in ["rifle", "pistol"]:
		return USER_GUNSHOT
	if kind == "reload":
		return USER_RELOAD
	if kind == "step":
		return USER_STEP_WALK
	if kind == "step_run":
		return USER_STEP_RUN
	if kind == "explosion":
		return USER_EXPLOSION
	if kind == "door_open":
		return USER_DOOR_OPEN
	if kind == "door_close":
		return USER_DOOR_CLOSE
	if kind.begins_with("alert"):
		var alert_index := clampi(int(kind.trim_prefix("alert")) - 1, 0, USER_ALERTS.size() - 1)
		return USER_ALERTS[alert_index]
	var rng := RandomNumberGenerator.new()
	rng.seed = kind.hash()
	var duration := 0.24 if kind == "rifle" else 0.16
	if kind == "reload":
		duration = 0.65
	elif kind == "explosion_preview":
		duration = 1.2
	var rate := 22050
	var samples := PackedByteArray()
	samples.resize(int(duration * rate) * 2)
	var previous := 0.0
	for i in int(duration * rate):
		var t := float(i) / rate
		var noise := rng.randf_range(-1.0, 1.0)
		previous = lerpf(previous, noise, 0.6)
		var amplitude := exp(-t * 26.0)
		var wave := previous * amplitude
		if kind == "rifle" or kind == "pistol":
			wave = (previous * 0.75 + sin(t * 460.0) * 0.25) * amplitude
		elif kind == "explosion_preview":
			wave = (previous * 0.55 + sin(t * 220.0 * exp(-t*0.8)) * 0.45) * exp(-t*5.5) * minf(1.0,t*900.0)
		elif kind == "step":
			wave = previous * exp(-t * 45.0) * 0.25
		elif kind == "reload":
			wave = previous * (exp(-abs(t - 0.06) * 90.0) + exp(-abs(t - 0.42) * 130.0)) * 0.55
		elif kind == "hit":
			wave = sin(t * 1600.0) * amplitude * 0.25
		samples.encode_s16(i * 2, int(clampf(wave, -1.0, 1.0) * 28000.0))
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = rate
	sound.data = samples
	if kind == "explosion_preview": explosion_preview = sound
	return sound

static func make_wind() -> AudioStreamWAV:
	# Keep the WAV return type used by the existing players; the source is a
	# crossfaded mono PCM16 loop. Duplicating avoids changing the shared import.
	var sound := FOREST_WIND.duplicate() as AudioStreamWAV
	sound.loop_mode = AudioStreamWAV.LOOP_FORWARD
	sound.loop_begin = 0
	sound.loop_end = roundi(sound.get_length() * sound.mix_rate)
	return sound

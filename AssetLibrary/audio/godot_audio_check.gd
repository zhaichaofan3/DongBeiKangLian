extends SceneTree

func _initialize() -> void:
	var factory = load("res://scripts/audio_factory.gd")
	var rifle: AudioStreamWAV = factory.make_sound("rifle")
	var step: AudioStreamWAV = factory.make_sound("step")
	var wind: AudioStreamWAV = factory.make_wind()
	assert(rifle is AudioStreamWAV and absf(rifle.get_length() - 2.55) < 0.001)
	assert(step is AudioStreamWAV and absf(step.get_length() - 0.243375) < 0.001)
	assert(rifle.mix_rate == 48000 and step.mix_rate == 48000 and wind.mix_rate == 48000)
	assert(rifle.loop_mode == AudioStreamWAV.LOOP_DISABLED)
	assert(step.loop_mode == AudioStreamWAV.LOOP_DISABLED)
	assert(wind.loop_mode == AudioStreamWAV.LOOP_FORWARD)
	assert(wind.format == AudioStreamWAV.FORMAT_16_BITS and not wind.stereo)
	assert(wind.loop_begin == 0 and wind.loop_end == 412078)
	assert(wind.data.decode_s16(0) == 0 and wind.data.decode_s16(wind.data.size() - 2) == 0)
	for kind in ["pistol", "reload", "hit"]:
		assert(factory.make_sound(kind).get_length() > 0.0)
	print("AUDIO INTEGRATION PASS: imported WAV types, lengths, rates, one-shots, loop bounds, seam and fallback streams")
	quit()

extends RefCounted

const SETTINGS_PATH := "user://presentation_v1.cfg"
const QA_SETTINGS_PATH := "user://qa_presentation_v1.cfg"
var main: Node3D
var quality := 1
var fps_limit := 120
var vsync := true
var fullscreen := false
var show_stats := false
var sensitivity := 0.002
var volume := 0.65
var music_volume := 0.22
var sfx_volume := 1.0
var dialogue_volume := 1.0
var cinematic_volume := 1.0
var motion_strength := 0.65
var settings_path := SETTINGS_PATH

func initialize(owner_node: Node3D) -> void:
	main = owner_node
	var testing := "--qa" in OS.get_cmdline_user_args() or "--capture" in OS.get_cmdline_user_args()
	if testing:
		settings_path = QA_SETTINGS_PATH
	else:
		load_preferences()
	apply_all()

func load_preferences() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	quality = int(_number(config, "quality", quality, 0, 2))
	var cap := int(_number(config, "fps_limit", fps_limit, 0, 240))
	fps_limit = cap if cap in [0, 60, 120, 144] else 120
	sensitivity = _number(config, "sensitivity", sensitivity, 0.0008, 0.004)
	volume = _number(config, "volume", volume, 0, 1)
	music_volume = _number(config, "music_volume", music_volume, 0, 1)
	sfx_volume = _number(config, "sfx_volume", sfx_volume, 0, 1)
	dialogue_volume = _number(config, "dialogue_volume", dialogue_volume, 0, 1)
	cinematic_volume = _number(config, "cinematic_volume", cinematic_volume, 0, 1)
	motion_strength = _number(config, "motion", motion_strength, 0, 1)
	vsync = _boolean(config, "vsync", vsync)
	fullscreen = _boolean(config, "fullscreen", fullscreen)
	show_stats = _boolean(config, "show_stats", show_stats)

func _number(config: ConfigFile, key: String, fallback: float, low: float, high: float) -> float:
	var value = config.get_value("presentation", key, fallback)
	if (value is int or value is float) and is_finite(float(value)):
		return clampf(float(value), low, high)
	return fallback

func _boolean(config: ConfigFile, key: String, fallback: bool) -> bool:
	var value = config.get_value("presentation", key, fallback)
	return value if value is bool else fallback

func save_preferences() -> void:
	if DisplayServer.get_name() != "headless":
		fullscreen = DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	var config := ConfigFile.new()
	for key in ["quality", "fps_limit", "vsync", "fullscreen", "show_stats", "sensitivity", "volume", "music_volume", "sfx_volume", "dialogue_volume", "cinematic_volume"]:
		config.set_value("presentation", key, get(key))
	config.set_value("presentation", "motion", motion_strength)
	if config.save(settings_path) != OK:
		main.notify("设置暂时无法保存，本次运行仍然生效。", 3)

func apply_all() -> void:
	set_quality(quality, false)
	Engine.max_fps = 0 if DisplayServer.get_name() == "headless" else fps_limit
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	main.player.sensitivity = sensitivity
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(0, volume == 0)
	main.audio_mix.apply_category_volumes()

func set_quality(level: int, persist: bool = true) -> void:
	quality = clampi(level, 0, 2)
	main.get_viewport().msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][quality]
	main.get_viewport().mesh_lod_threshold = [3.0, 2.0, 1.0][quality]
	RenderingServer.directional_shadow_atlas_set_size([1024,2048,4096][quality],true)
	if main.world.has_method("apply_quality"):
		main.world.apply_quality(quality)
	if persist:
		save_preferences()

func change(key: String, value: Variant) -> void:
	match key:
		"fps_limit": fps_limit = int(value) if int(value) in [0, 60, 120, 144] else 120
		"vsync": vsync = bool(value)
		"fullscreen": fullscreen = bool(value)
		"show_stats": show_stats = bool(value)
		"sensitivity": sensitivity = clampf(float(value), 0.0008, 0.004)
		"volume": volume = clampf(float(value), 0, 1)
		"music_volume": music_volume = clampf(float(value), 0, 1)
		"sfx_volume": sfx_volume = clampf(float(value), 0, 1)
		"dialogue_volume": dialogue_volume = clampf(float(value), 0, 1)
		"cinematic_volume": cinematic_volume = clampf(float(value), 0, 1)
		"motion": motion_strength = clampf(float(value), 0, 1)
		_: return
	# A slider must never reapply a cached window mode or rebuild world quality.
	match key:
		"fullscreen":
			if DisplayServer.get_name() != "headless":
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
		"vsync":
			if DisplayServer.get_name() != "headless":
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
		"fps_limit": Engine.max_fps = 0 if DisplayServer.get_name() == "headless" else fps_limit
		"sensitivity": main.player.sensitivity = sensitivity
		"volume":
			AudioServer.set_bus_volume_db(0, linear_to_db(maxf(volume, 0.0001)))
			AudioServer.set_bus_mute(0, volume == 0)
		"music_volume", "sfx_volume", "dialogue_volume", "cinematic_volume": main.audio_mix.apply_category_volumes()
	save_preferences()

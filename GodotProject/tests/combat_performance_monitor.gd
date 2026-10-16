extends Node
## Optional observer of the real route test; never changes actors or difficulty.
const EXPECTED_SIZE := Vector2i(1920, 1080)
const RECENT_SHOT_USEC := 1000000
var main: Node3D
var output := ""
var began := 0
var previous := 0
var was_playing := false
var finished := false
var frames: Array[float] = []
var active_frames: Array[float] = []
var stationary_frames: Array[float] = []
var fighting_frames: Array[float] = []
var firing_frames: Array[float] = []
var enemy_firing_frames: Array[float] = []
var exchange_frames: Array[float] = []
var player_shots := 0
var enemy_shots := 0
var previous_ammo := 0
var guard_shots: Dictionary = {}
var last_player_shot := -RECENT_SHOT_USEC * 2
var last_enemy_shot := -RECENT_SHOT_USEC * 2
var validation_errors: Array[String] = []
var calls := 0.0
var peak_enemies := 0
var peak_texture_bytes := 0.0
var render_size_checked := false
var measured_render_size := Vector2i.ZERO
var reported_texture_size := Vector2i.ZERO
var measured_content_size := Vector2i.ZERO
var measured_content_factor := 1.0
var measured_content_mode := 0

func initialize(game: Node3D, destination: String) -> void:
	main = game
	output = destination
	process_mode = Node.PROCESS_MODE_ALWAYS
	began = Time.get_ticks_usec()
	previous = began
	previous_ammo = _player_ammo()
	main.presentation.quality = 1
	main.presentation.fps_limit = 0
	main.presentation.vsync = false
	main.presentation.fullscreen = false
	main.presentation.show_stats = false
	main.presentation.apply_all()
	main.get_tree().root.size = EXPECTED_SIZE
	main.get_viewport().scaling_3d_scale = 1.0
	for argument in OS.get_cmdline_args():
		if argument == "--fixed-fps" or argument.begins_with("--fixed-fps="):
			_flag("A --fixed-fps simulation override was supplied.")

func _player_ammo() -> int:
	var total := 0
	for count in main.player.magazines: total += count
	for count in main.player.reserves: total += count
	return total

func _track_shots(now: int) -> void:
	var ammo := _player_ammo()
	var fired := maxi(0, previous_ammo - ammo)
	previous_ammo = ammo
	if fired > 0:
		player_shots += fired
		last_player_shot = now
	for guard in main.guards:
		if not is_instance_valid(guard): continue
		var count: int = guard.shots_fired
		var added := maxi(0, count - int(guard_shots.get(guard.guard_id, 0)))
		guard_shots[guard.guard_id] = count
		if added > 0:
			enemy_shots += added
			last_enemy_shot = now

func _flag(message: String) -> void:
	if message not in validation_errors: validation_errors.append(message)

func _check_render_target() -> void:
	# In Godot 4.7.2 canvas_items mode, ViewportTexture.get_size() can
	# include the canvas stretch factor a second time. Read the actual image
	# only outside measured intervals; GPU readback must not inflate samples.
	var texture := main.get_viewport().get_texture()
	var picture := texture.get_image() if texture != null else null
	measured_render_size = Vector2i.ZERO if picture == null else picture.get_size()
	if measured_render_size != EXPECTED_SIZE:
		_flag("The observed native render target was not 1920x1080 at 100% 3D scale.")
	if not render_size_checked:
		reported_texture_size = Vector2i.ZERO if texture == null else Vector2i(texture.get_size())
		measured_content_size = get_tree().root.content_scale_size
		measured_content_factor = get_tree().root.content_scale_factor
		measured_content_mode = get_tree().root.content_scale_mode
		render_size_checked = true

func _check_configuration() -> void:
	if main.get_tree().root.size != EXPECTED_SIZE or DisplayServer.window_get_size() != EXPECTED_SIZE:
		_flag("The observed window was not 1920x1080 throughout sampling.")
	if not is_equal_approx(main.get_viewport().scaling_3d_scale, 1.0):
		_flag("The 3D render scale changed from 100% during sampling.")
	if render_size_checked and (Vector2i(main.get_viewport().get_texture().get_size()) != reported_texture_size or get_tree().root.content_scale_size != measured_content_size or not is_equal_approx(get_tree().root.content_scale_factor, measured_content_factor) or get_tree().root.content_scale_mode != measured_content_mode):
		_flag("The viewport stretch configuration changed during sampling.")
	if Engine.max_fps != 0 or DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED:
		_flag("An FPS cap or VSync was enabled during sampling.")
	if not is_equal_approx(Engine.time_scale, 1.0):
		_flag("Engine.time_scale changed simulation speed.")
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MINIMIZED:
		_flag("The benchmark window was minimized during sampling.")
	if main.presentation.quality != 1:
		_flag("The benchmark quality changed from balanced during sampling.")

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var ms := float(now - previous) / 1000.0
	previous = now
	if not is_instance_valid(main):
		was_playing = false
		return
	_track_shots(now)
	var playing: bool = main.mode == "playing" and not get_tree().paused and now - began >= 1500000
	var whole_playing_interval := playing and was_playing
	was_playing = playing
	# Require both interval boundaries to be in active play. Never attribute a
	# pause, menu, or initial warm-up interval to the first resumed frame.
	if not whole_playing_interval or ms <= 0.0:
		return
	if not render_size_checked:
		_check_render_target()
		previous = Time.get_ticks_usec()
		was_playing = false
		return
	_check_configuration()
	frames.append(ms)
	calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	peak_texture_bytes = maxf(peak_texture_bytes, Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
	peak_enemies = maxi(peak_enemies, main.alive_guard_count())
	var player_firing := now - last_player_shot <= RECENT_SHOT_USEC
	var enemy_firing := now - last_enemy_shot <= RECENT_SHOT_USEC
	var moving: bool = Vector2(main.player.velocity.x, main.player.velocity.z).length_squared() > 0.01
	if moving or player_firing or enemy_firing:
		active_frames.append(ms)
	else:
		stationary_frames.append(ms)
	if player_firing or enemy_firing: firing_frames.append(ms)
	if enemy_firing: enemy_firing_frames.append(ms)
	if player_firing and enemy_firing: exchange_frames.append(ms)
	for guard in main.guards:
		if is_instance_valid(guard) and guard.state == "combat":
			fighting_frames.append(ms)
			break

func _summary(values: Array[float]) -> Dictionary:
	if values.is_empty():
		return {"frames": 0}
	var ordered := values.duplicate()
	ordered.sort()
	var total := 0.0
	for value in ordered:
		total += value
	var count := ordered.size()
	return {"frames": count, "mean_frame_ms": total / count, "mean_fps": count * 1000.0 / total,
		"p95_frame_ms": ordered[int((count - 1) * 0.95)], "p99_frame_ms": ordered[int((count - 1) * 0.99)],
		"max_frame_ms": ordered[-1], "seconds_sampled": total / 1000.0}

func finish(route_passed: bool) -> void:
	if finished: return
	finished = true
	set_process(false)
	_track_shots(Time.get_ticks_usec())
	_check_configuration()
	_check_render_target()
	if not route_passed: _flag("The route did not pass.")
	var active_summary := _summary(active_frames)
	var firing_summary := _summary(firing_frames)
	if active_frames.size() < 30 or float(active_summary.get("seconds_sampled", 0)) < 5.0:
		_flag("Fewer than 30 active frames or 5 seconds of active movement/firing were sampled.")
	if player_shots == 0 or firing_frames.size() < 10 or float(firing_summary.get("seconds_sampled", 0)) < 0.5:
		_flag("Insufficient observed real firing to report a combat route benchmark.")
	var render_size := measured_render_size
	var window_size := DisplayServer.window_get_size()
	var report := {"scope": "Real AI and automated player route; automatic aiming is not human difficulty. Primary active_route_frames include movement or a shot within 1s. Stationary no-shot intervals are separate. AI combat state alone is not evidence of firing. Excludes first 1.5s, menus, pauses and their boundary intervals. No fixed-fps simulation override.",
		"version": ProjectSettings.get_setting("application/config/version"),
		"gpu": RenderingServer.get_video_adapter_name(), "renderer": RenderingServer.get_current_rendering_method(),
		"resolution": [render_size.x, render_size.y], "window_resolution": [window_size.x, window_size.y],
		"resolution_method": "Viewport image readback before and after sampling; window and stretch configuration checked each sample; readback intervals excluded.",
		"reported_viewport_texture_size": [reported_texture_size.x, reported_texture_size.y],
		"render_scale_3d": main.get_viewport().scaling_3d_scale, "quality": "balanced",
		"vsync": DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED, "fps_limit": Engine.max_fps,
		"time_scale": Engine.time_scale, "measurement_valid": validation_errors.is_empty(), "validation_errors": validation_errors,
		"route_passed": route_passed, "all_playing_frames": _summary(frames), "enemy_in_combat_frames": _summary(fighting_frames),
		"active_route_frames": active_summary, "stationary_without_recent_fire_frames": _summary(stationary_frames),
		"recent_firing_frames": firing_summary, "recent_enemy_firing_frames": _summary(enemy_firing_frames),
		"two_sided_recent_firing_frames": _summary(exchange_frames), "player_shots_observed": player_shots, "enemy_shots_observed": enemy_shots,
		"peak_alive_enemies_observed": peak_enemies, "reported_peak_texture_bytes": peak_texture_bytes,
		"mean_draw_calls": calls / maxf(frames.size(), 1), "health_at_finish": main.player.health}
	if DirAccess.make_dir_recursive_absolute(output.get_base_dir()) != OK:
		push_error("Cannot create active-combat performance report directory: " + output.get_base_dir())
		return
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write active-combat performance report: " + output)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		push_error("Cannot finish active-combat performance report: " + error_string(write_error))
		return
	print("COMBAT PERFORMANCE RESULT: ", JSON.stringify(report))

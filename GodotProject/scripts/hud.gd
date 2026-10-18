extends CanvasLayer

var main: Node3D
var root: Control
var objective: Label
var subtitle: Label
var health: Label
var ammo: Label
var prompt: Label
var compass: Label
var marker: Label
var menu: Control
var menu_title: Label
var menu_caption: Label
var actions: VBoxContainer
var damage: ColorRect
var damage_edges: Array[ColorRect] = []
var crosshair: Label
var settings_panel: VBoxContainer
var settings_scroll: ScrollContainer
var hud_controls: Array[Control] = []
var menu_kind := ""
var conversation: PanelContainer
var dialog_name: Label
var dialog_text: Label
var dialog_actions: VBoxContainer
var dialog_revision := -1
var companion: Label
var performance_label: Label
var info_clock := 0.0
var stats_clock := 0.0
var field_dialogue: Label
var hold_clock: Label
var hold_bar: ColorRect
var hold_fill: ColorRect
var menu_center: CenterContainer
var menu_column: VBoxContainer
var menu_eyebrow: Label
var menu_footer: Label
var menu_rule: ColorRect
var menu_dim: ColorRect

func initialize(owner_node: Node3D) -> void:
	main = owner_node
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC"])
	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 18
	root.theme = theme
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("17221feb")
	panel_style.border_color = Color("8e8964")
	panel_style.set_border_width_all(1)
	panel_style.set_content_margin_all(14)
	theme.set_stylebox("panel", "PanelContainer", panel_style)
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = Color("27322eea")
	button_style.border_color = Color("606956")
	button_style.set_border_width_all(1)
	button_style.set_content_margin_all(9)
	theme.set_stylebox("normal", "Button", button_style)
	var hover := button_style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("4a5140")
	hover.border_color = Color("d4c598")
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("focus", "Button", hover)
	objective = _label(root, 20, Color("f3f7f0"))
	objective.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	objective.position = Vector2(30, 28)
	objective.size = Vector2(410, 32)
	subtitle = _label(root, 16, Color("d0e2dc"))
	subtitle.position = Vector2(30, 66)
	subtitle.size = Vector2(410, 80)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hold_clock = _label(root, 30, Color("fff1dc"))
	hold_clock.position = Vector2(30, 64)
	hold_clock.size = Vector2(410, 48)
	hold_clock.visible = false
	hold_bar = ColorRect.new()
	hold_bar.position = Vector2(32, 119)
	hold_bar.size = Vector2(290, 4)
	hold_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hold_bar.color = Color("ffffff24")
	hold_fill = ColorRect.new()
	hold_fill.size = Vector2(290, 4)
	hold_fill.color = Color("c95445")
	hold_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hold_bar.add_child(hold_fill)
	root.add_child(hold_bar)
	hold_bar.visible = false
	health = _label(root, 19)
	health.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	health.position = Vector2(30, -62)
	companion = _label(root, 16, Color("e6d4a5"))
	companion.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	companion.position = Vector2(30, -125)
	companion.size = Vector2(420, 56)
	ammo = _label(root, 22)
	ammo.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	ammo.position = Vector2(-300, -74)
	ammo.size = Vector2(270, 64)
	ammo.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	compass = _label(root, 16, Color("c4d9d8"))
	compass.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	compass.position = Vector2(-170, 24)
	compass.size = Vector2(340, 30)
	compass.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	marker = _label(root, 15, Color("c5e5cd"))
	marker.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	marker.position = Vector2(-170, 57)
	marker.size = Vector2(340, 26)
	marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt = _label(root, 19, Color("f9e5af"))
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.position = Vector2(-200, -128)
	prompt.size = Vector2(400, 36)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair = _label(root, 21, Color("e4eae7"))
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-14, -17)
	crosshair.size = Vector2(28, 34)
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.text = "+"
	hud_controls = [objective, subtitle, health, ammo, compass, marker, prompt, crosshair, companion]
	damage = ColorRect.new()
	damage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	damage.color = Color(0.6, 0.1, 0.05, 0)
	damage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(damage)
	_build_damage_edges()
	_build_menu()
	_build_conversation()
	performance_label = _label(root, 14, Color("bed2bf"))
	performance_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	performance_label.position = Vector2(-275, 20)
	performance_label.size = Vector2(245, 60)
	performance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	performance_label.visible = false
	field_dialogue = _label(root, 20, Color("f1e7cf"))
	field_dialogue.anchor_left = 0.16
	field_dialogue.anchor_right = 0.84
	field_dialogue.anchor_top = 0.65
	field_dialogue.anchor_bottom = 0.74
	field_dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	field_dialogue.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	field_dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	field_dialogue.visible = false

func _process(delta: float) -> void:
	if main == null or main.player == null:
		return
	if main.mode=="briefing":
		var ready: bool = main.world.is_world_ready()
		for button in actions.get_children():
			if button.has_meta("requires_world_ready"): button.disabled = not ready
	var changed: bool = menu_kind != main.mode
	var holding: bool = main.mode == "playing" and main.linear.extraction_started and main.linear.extraction_remaining > 0
	hold_clock.visible = holding
	hold_bar.visible = holding
	if holding:
		hold_clock.text = "守住30秒  /  00:%02d" % ceili(main.linear.extraction_remaining)
		hold_clock.add_theme_color_override("font_color", Color("ff8f7e") if main.linear.extraction_remaining <= 5 else Color("fff1dc"))
		hold_fill.size.x = 290 * main.linear.extraction_remaining / main.linear.HOLD_DURATION
	subtitle.position.y = 153 if holding else 66
	field_dialogue.visible = main.mode == "playing" and is_instance_valid(main.story.moments) and main.story.moments.remaining > 0
	if field_dialogue.visible:
		field_dialogue.text = main.story.moments.caption
	crosshair.text = "×" if main.hit_marker > 0 else "+"
	crosshair.visible = main.mode == "playing" and not main.player.aiming
	damage.color.a = main.player.damage_flash * 0.08 if main.mode == "playing" else 0
	var edge_alpha: float = main.player.damage_flash * 0.90 if main.mode == "playing" else 0.0
	for edge in damage_edges:
		edge.color.a = edge_alpha
	if changed:
		for control in hud_controls:
			if control != crosshair:
				control.visible = main.mode == "playing"
		show_menu(main.mode)
	conversation.visible = main.mode == "dialogue"
	if conversation.visible and dialog_revision != main.story.revision:
		_refresh_dialogue()
	stats_clock -= delta
	performance_label.visible = main.presentation != null and main.presentation.show_stats
	if performance_label.visible and stats_clock <= 0:
		stats_clock = 0.4
		var fps := Engine.get_frames_per_second()
		performance_label.text = "%d FPS  ·  %.1f ms\n%s  ·  F3 隐藏" % [fps, 1000.0 / maxf(fps, 1), ["性能", "均衡", "画质"][main.presentation.quality]]
	# Proximity queries and text formatting need not run at GPU frame frequency.
	info_clock -= delta
	if info_clock > 0 and not changed:
		return
	info_clock = 0.1
	objective.text = main.objective_text()
	subtitle.text = main.linear.status_text()
	if subtitle.text.is_empty() and main.message_timer > 0:
		subtitle.text = main.message
	var player = main.player
	health.text = "生命 %03d  ·  绷带 %d [H]  ·  记录 [J]" % [int(player.health), main.story.bandages]
	ammo.text = "%s\n%02d / %02d" % [player.WEAPONS[player.weapon_index].name, player.magazines[player.weapon_index], player.reserves[player.weapon_index]]
	if player.reload_timer > 0:
		ammo.text += "  装填中"
	compass.text = "1938  /  东北林区  /  " + ("松岭屯" if main.village.entered else "青岚林场")
	var local_target: Vector3 = player.global_basis.inverse() * (main.target_position() - player.position)
	var bearing := atan2(local_target.x, -local_target.z)
	var arrow: String = ["↑", "↗", "→", "↘", "↓", "↙", "←", "↖"][posmod(roundi(bearing / (PI / 4)), 8)]
	marker.text = "%s  %s  %dm" % [arrow, main.target_name(), int(player.position.distance_to(main.target_position()))]
	prompt.text = main.interaction_prompt()
	companion.text = ""
	if main.village.entered:
		companion.text = "姜岚  ·  同行掩护  ·  %d 米\n陆山在船边休整" % int(player.position.distance_to(main.story.people.scout.position))
	elif main.story.recruited:
		var lu = main.story.people.lu
		companion.text = "陆山  ·  %s  ·  %d 米\n%s" % ["跟随" if lu.following else "等候", int(player.position.distance_to(lu.position)), "已包扎" if lu.treated else "腿伤未处理，移动较慢"]

func _build_damage_edges() -> void:
	var red := Color(0.78, 0.025, 0.015, 0.0)
	var top := ColorRect.new()
	top.color = red
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.anchor_right = 1.0
	top.offset_bottom = 96
	root.add_child(top)
	damage_edges.append(top)
	var bottom := ColorRect.new()
	bottom.color = red
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.anchor_top = 1.0
	bottom.anchor_right = 1.0
	bottom.anchor_bottom = 1.0
	bottom.offset_top = -96
	root.add_child(bottom)
	damage_edges.append(bottom)
	var left := ColorRect.new()
	left.color = red
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.anchor_right = 0.0
	left.anchor_bottom = 1.0
	left.offset_right = 92
	root.add_child(left)
	damage_edges.append(left)
	var right := ColorRect.new()
	right.color = red
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.anchor_left = 1.0
	right.anchor_right = 1.0
	right.anchor_bottom = 1.0
	right.offset_left = -92
	root.add_child(right)
	damage_edges.append(right)
	var directions := [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT]
	for i in damage_edges.size():
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/damage_edge.gdshader")
		material.set_shader_parameter("inward", directions[i])
		damage_edges[i].material = material

func _build_menu() -> void:
	menu = Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(menu)
	var dim := ColorRect.new()
	menu_dim = dim
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.015, 0.02, 0.02, 0.72)
	menu.add_child(dim)
	var center := CenterContainer.new()
	menu_center = center
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(center)
	var column := VBoxContainer.new()
	menu_column = column
	column.custom_minimum_size = Vector2(620, 0)
	column.add_theme_constant_override("separation", 12)
	center.add_child(column)
	menu_eyebrow = _label(column, 15, Color("d6d8d4"))
	menu_eyebrow.text = "1938  /  白山黑水"
	menu_title = _label(column, 42, Color("f4f4ef"))
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title.add_theme_constant_override("outline_size", 0)
	menu_title.add_theme_color_override("font_shadow_color", Color("00000090"))
	menu_title.add_theme_constant_override("shadow_offset_y", 2)
	menu_caption = _label(column, 17, Color("c7dcda"))
	menu_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_rule = ColorRect.new()
	menu_rule.color = Color("b54a40")
	menu_rule.custom_minimum_size = Vector2(64, 3)
	menu_rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(menu_rule)
	actions = VBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	settings_scroll = ScrollContainer.new()
	settings_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	settings_scroll.follow_focus = true
	settings_scroll.visible = false
	column.add_child(settings_scroll)
	settings_panel = VBoxContainer.new()
	settings_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_panel.add_theme_constant_override("separation", 8)
	settings_scroll.add_child(settings_panel)
	column.add_child(actions)
	menu_footer = _label(menu, 13, Color("b6bbb7"))
	menu_footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	menu_footer.position = Vector2(76, -43)
	menu_footer.text = "青岚林场  /  东北抗联的一次敌后行动"
	root.resized.connect(_resize_settings)

func _resize_settings() -> void:
	settings_scroll.custom_minimum_size.y = clampf(root.size.y - 220, 240, 500)

func show_menu(kind: String) -> void:
	menu_kind = kind
	settings_scroll.visible = false
	menu.visible = kind not in ["playing", "dialogue", "cinematic", "melee", "crossing"]
	_layout_menu(kind == "briefing")
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
	for child in settings_panel.get_children():
		settings_panel.remove_child(child)
		child.queue_free()
	if kind in ["playing", "dialogue", "cinematic", "melee", "crossing"]:
		return
	match kind:
		"briefing":
			menu_title.text = "东北抗联 烽火回声"
			menu_caption.text = "一份名册，一位战友。\n穿过林场，把他们一起带回山。"
			_button("开始游戏", main.start_with_opening,true)
			_button("直接进入林场", main.start_new,true)
			if main.has_save():
				_button("继续检查点", main.continue_checkpoint,true)
			_button("设置", _show_settings)
			_button("退出", func(): main.get_tree().quit())
		"paused":
			menu_title.text = "任务暂停"
			menu_caption.text = "东北抗联 烽火回声"
			_button("继续", main.resume)
			_button("返回检查点", main.continue_checkpoint)
			_button("重新开始", main.start_with_opening)
			_button("设置", _show_settings)
			_button("退出", func(): main.get_tree().quit())
		"cinematic_paused":
			menu_title.text = "开场已暂停"
			menu_caption.text = "临时场景与动作排演 · 正式配音、音乐和特效将在后续制作"
			if not main.last_save_error.is_empty(): menu_caption.text += "\n" + main.last_save_error
			_button("继续观看", main.resume)
			_button("设置", _show_settings)
			_button("返回开始界面", main.return_to_menu)
		"crossing_paused":
			menu_title.text = "渡河途中"
			menu_caption.text = "林溪 · 松岭屯南岸"
			_button("继续观看", main.resume)
			_button("略过渡河", main.village.finish_crossing)
			_button("设置", _show_settings)
			_button("返回开始界面", main.return_to_menu)
		"crossing_save_error":
			menu_title.text = "上岸检查点未能保存"
			menu_caption.text = main.last_save_error
			_button("重试保存", main.village.retry_arrival_save)
			_button("返回检查点", main.continue_checkpoint)
			_button("返回开始界面", main.return_to_menu)
		"opening_save_error":
			menu_title.text = "检查点未能保存"
			menu_caption.text = main.last_save_error
			_button("重试保存并开始任务", main.retry_opening_save)
			_button("返回开始界面", main.return_to_menu)
		"opening_load_error":
			menu_title.text = "开场记录不一致"
			menu_caption.text = "已保留原存档，未重置任务。可返回开始界面选择重新开始。"
			_button("返回开始界面", main.return_to_menu)
		"lost":
			menu_title.text = "任务失败"
			menu_caption.text = "交通线还在等待。"
			_button("返回检查点", main.continue_checkpoint)
			_button("重新开始", main.start_with_opening)
			_button("退出", func(): main.get_tree().quit())
		"won":
			menu_title.text = "松岭屯的路，打通了"
			menu_caption.text = "村内12名日军已全部肃清。\n你和姜岚打通了乡亲的撤离路线，陆山带着名册等在船边。\n用时 %s" % main.elapsed_text()
			_button("再试一次", main.start_with_opening)
			_button("退出", func(): main.get_tree().quit())
		"journal":
			menu_title.text = "行动记录"
			menu_caption.text = main.story.journal_text()
			_button("返回行动  [J / Esc]", main.resume)
	if actions.get_child_count() > 0:
		(actions.get_child(0) as Button).grab_focus()

func _layout_menu(title_screen: bool) -> void:
	menu_dim.color.a = 0.48 if title_screen else 0.72
	menu_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if title_screen:
		menu_center.anchor_left = 0.06
		menu_center.anchor_right = 0.56
		menu_center.anchor_top = 0.12
		menu_center.anchor_bottom = 0.88
	menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if title_screen else HORIZONTAL_ALIGNMENT_CENTER
	menu_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if title_screen else HORIZONTAL_ALIGNMENT_CENTER
	menu_eyebrow.visible = title_screen
	menu_rule.visible = title_screen
	menu_footer.visible = title_screen
	actions.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if title_screen else Control.SIZE_FILL
	actions.custom_minimum_size.x = 312 if title_screen else 0

func _show_settings() -> void:
	_layout_menu(false)
	for child in actions.get_children():
		actions.remove_child(child)
		child.queue_free()
	for child in settings_panel.get_children():
		settings_panel.remove_child(child)
		child.queue_free()
	menu_title.text = "设置"
	menu_caption.text = "画面、声音与操控 · 修改立即生效并自动保存"
	settings_scroll.visible = true
	settings_scroll.scroll_vertical = 0
	_resize_settings()
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 12)
	settings_panel.add_child(grid)
	_volume_setting(grid, "总音量", "volume", "MasterVolume", "调整所有声音。")
	_volume_setting(grid, "背景音量", "music_volume", "MusicVolume", "调整全局配乐；历史录音自带配乐随剧情动画音量调整。")
	_volume_setting(grid, "音效音量", "sfx_volume", "SfxVolume", "调整枪声、脚步、流水、爆炸和开关门等声音。")
	_volume_setting(grid, "对话音量", "dialogue_volume", "DialogueVolume", "调整人物对白、发现敌人的语音和冲锋叫喊。")
	_volume_setting(grid, "剧情动画音量", "cinematic_volume", "CinematicVolume", "调整两段开场的整体音量，包括历史录音自带的配乐。")
	var audio_help := _label(settings_panel, 15, Color("c7dcda"))
	audio_help.text = "剧情动画音量控制两段开场整体；历史录音的旁白与配乐一起调整。\n任务序幕的对白、配乐和音效还受各自音量控制。拖到 0% 即可静音。"
	audio_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 12)
	settings_panel.add_child(grid)
	_label(grid, 17).text = "画质预设"
	var quality := OptionButton.new()
	for title in ["性能 · 较少植被与阴影", "均衡 · 推荐", "画质 · 更远阴影与精细抗锯齿"]:
		quality.add_item(title)
	quality.select(main.presentation.quality)
	quality.item_selected.connect(func(index: int): main.presentation.set_quality(index))
	quality.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(quality)
	_label(grid, 17).text = "帧率上限"
	var cap := OptionButton.new()
	for title in ["60 FPS", "120 FPS", "144 FPS", "不限制"]:
		cap.add_item(title)
	var caps: Array = [60, 120, 144, 0]
	cap.select(caps.find(main.presentation.fps_limit))
	cap.item_selected.connect(func(index: int): main.presentation.change("fps_limit", caps[index]))
	grid.add_child(cap)
	_label(grid, 17).text = "鼠标灵敏度"
	var slider := HSlider.new()
	slider.min_value = 0.0008
	slider.max_value = 0.004
	slider.step = 0.0001
	slider.value = main.player.sensitivity
	slider.value_changed.connect(func(value: float): main.presentation.change("sensitivity", value))
	grid.add_child(slider)
	_label(grid, 17).text = "镜头与武器晃动"
	var motion := HSlider.new()
	motion.min_value = 0
	motion.max_value = 1
	motion.step = 0.05
	motion.value = main.presentation.motion_strength
	motion.value_changed.connect(func(value: float): main.presentation.change("motion", value))
	grid.add_child(motion)
	var toggles := HBoxContainer.new()
	toggles.add_theme_constant_override("separation", 18)
	settings_panel.add_child(toggles)
	var fullscreen := CheckButton.new()
	fullscreen.text = "全屏"
	fullscreen.button_pressed = DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]
	fullscreen.toggled.connect(func(value: bool): main.presentation.change("fullscreen", value))
	toggles.add_child(fullscreen)
	var vsync := CheckButton.new()
	vsync.text = "垂直同步"
	vsync.button_pressed = main.presentation.vsync
	vsync.toggled.connect(func(value: bool): main.presentation.change("vsync", value))
	toggles.add_child(vsync)
	var stats := CheckButton.new()
	stats.text = "显示帧率 [F3]"
	stats.button_pressed = main.presentation.show_stats
	stats.toggled.connect(func(value: bool): main.presentation.change("show_stats", value))
	toggles.add_child(stats)
	var bindings := _label(settings_panel, 15, Color("c7dcda"))
	bindings.text = "移动 WASD · 冲刺 Shift · 跳跃 Space\n蹲伏 C / Ctrl · 左右探头 Q / E\n射击 左键 · 瞄准 右键 · 换弹 R · 切枪 1 / 2\n互动 F · 包扎 H · 记录 J · 暂停 Esc\n对话：点击选项或按 1 / 2 / 3，Esc 暂时离开"
	_button("返回", func(): show_menu(main.mode))
	(settings_panel.find_child("MasterVolume", true, false) as HSlider).grab_focus()

func _volume_setting(grid: GridContainer, title: String, key: String, node_name: String, hint: String) -> void:
	_label(grid, 17).text = title
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	grid.add_child(row)
	var slider := HSlider.new()
	slider.name = node_name
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.01
	slider.value = main.presentation.get(key)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.x = 280
	slider.tooltip_text = hint
	row.add_child(slider)
	var percent := _label(row, 17)
	percent.name = "Percent"
	percent.custom_minimum_size.x = 52
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	percent.text = "%d%%" % roundi(slider.value * 100)
	slider.value_changed.connect(func(value: float):
		percent.text = "%d%%" % roundi(value * 100)
		main.presentation.change(key, value))

func _build_conversation() -> void:
	conversation = PanelContainer.new()
	conversation.anchor_left = 0.14
	conversation.anchor_right = 0.86
	conversation.anchor_top = 0.52
	conversation.anchor_bottom = 0.97
	root.add_child(conversation)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	conversation.add_child(column)
	dialog_name = _label(column, 24, Color("e5cf92"))
	dialog_text = _label(column, 18, Color("e2e6dc"))
	dialog_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_text.custom_minimum_size.y = 86
	dialog_actions = VBoxContainer.new()
	dialog_actions.add_theme_constant_override("separation", 5)
	column.add_child(dialog_actions)
	conversation.visible = false

func _refresh_dialogue() -> void:
	dialog_revision = main.story.revision
	dialog_name.text = main.story.speaker
	dialog_text.text = main.story.speech
	for child in dialog_actions.get_children():
		child.free()
	for i in main.story.choices.size():
		var button := Button.new()
		button.text = "%d  %s" % [i + 1, main.story.choices[i].label]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 40
		button.add_theme_font_size_override("font_size", 17)
		button.pressed.connect(main.story.choose.bind(i))
		dialog_actions.add_child(button)
	if dialog_actions.get_child_count() > 0:
		(dialog_actions.get_child(0) as Button).grab_focus()

func _button(text: String, action: Callable, requires_world_ready: bool = false) -> void:
	var button := Button.new()
	if requires_world_ready:
		button.set_meta("requires_world_ready",true)
		button.disabled = not main.world.is_world_ready()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	if menu_kind == "briefing":
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(312, 48)
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color("121817c0")
		normal.border_color = Color("ffffff25")
		normal.border_width_bottom = 1
		normal.content_margin_left = 18
		normal.content_margin_right = 18
		normal.content_margin_top = 10
		normal.content_margin_bottom = 10
		var highlight := normal.duplicate() as StyleBoxFlat
		highlight.bg_color = Color("983f36ef")
		highlight.border_color = Color("e6b5a8")
		highlight.border_width_left = 3
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", highlight)
		button.add_theme_stylebox_override("focus", highlight)
		button.add_theme_stylebox_override("pressed", highlight)
	button.pressed.connect(action)
	actions.add_child(button)

func _label(parent: Node, size: int, color: Color = Color("ecf0e8")) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.025, 0.035, 0.035, 0.9))
	label.add_theme_constant_override("outline_size", 4)
	parent.add_child(label)
	return label

extends RefCounted

const Friendly = preload("res://scripts/friendly.gd")
const StoryMoments = preload("res://scripts/story_moments.gd")
const SCOUT := preload("res://scripts/first_level_layout.gd").SCOUT
const LOGGER := preload("res://scripts/first_level_layout.gd").LOGGER
const WOUNDED := Vector3(47, 0.08, 30)
const LETTER := Vector3(48, 1.14, 41.8)
const SUPPLY := Vector3(36, 0.9, 130)
const DOOR := Vector3(41.7, 1.5, 38)

var main: Node3D
var people: Dictionary = {}
var met_scout := false
var supply_choice := "none"
var read_letter := false
var supply_taken := false
var recruited := false
var door_open := false
var bandages := 1
var speaker_id := ""
var speaker := ""
var speech := ""
var choices: Array = []
var revision := 0
var door: StaticBody3D
var parcel: Node3D
var dialog_yaw := 0.0
var dialog_pitch := 0.0
var moments: Node3D

func initialize(owner_node: Node3D) -> void:
	main = owner_node
	_add_person("scout", "姜岚 · 抗联侦察员", "scout", SCOUT)
	_add_person("logger", "林守义 · 林工", "logger", LOGGER)
	_add_person("lu", "陆山 · 交通员", "wounded", WOUNDED)
	door = main.world.box("电报房木门", DOOR, Vector3(0.18, 3, 3.65), "wood")
	parcel = main.world.box("医药包", SUPPLY, Vector3(0.6, 0.24, 0.4), "sandbag", false)
	main.world.box("补给矮箱", SUPPLY - Vector3(0, 0.48, 0), Vector3(0.9, 0.72, 0.65), "wood")
	main.world.navigation.set_point_solid(main.world.cell_at(SUPPLY))
	main.world.box("未寄出的家书", LETTER, Vector3(0.5, 0.025, 0.36), "paper", false)
	main.world.box("案边木架", LETTER - Vector3(0, 0.63, 0), Vector3(2.1, 1.0, 0.5), "wood")
	reset()
	moments = StoryMoments.new()
	main.add_child(moments)
	moments.initialize(main)

func _add_person(id: String, title: String, role: String, at: Vector3) -> void:
	var npc := Friendly.new()
	npc.initialize(main, id, title, role, at)
	main.add_child(npc)
	people[id] = npc

func reset() -> void:
	met_scout = false
	supply_choice = "none"
	read_letter = false
	supply_taken = false
	recruited = false
	bandages = 1
	speaker_id = ""
	people.scout.reset(SCOUT)
	people.logger.reset(LOGGER)
	people.lu.reset(WOUNDED)
	_set_door(false)
	parcel.visible = true
	if is_instance_valid(moments):
		moments.reset()

func candidate() -> Dictionary:
	var items: Array = [
		{"id": "scout", "at": people.scout.position + Vector3.UP * 1.3, "text": "E  与姜岚交谈"},
		{"id": "logger", "at": people.logger.position + Vector3.UP * 1.3, "text": "E  与林守义交谈"},
		{"id": "lu", "at": people.lu.position + Vector3.UP * 1.3, "text": "E  与陆山交谈"},
		{"id": "door", "at": DOOR, "text": "E  关闭木门" if door_open else "E  推开木门"},
		{"id": "letter", "at": LETTER, "text": "E  阅读家书"}]
	if not supply_taken:
		items.append({"id": "supply", "at": SUPPLY, "text": "E  拿取医药包"})
	var nearest: Dictionary = {}
	var best := 2.8
	for item in items:
		var distance: float = (main.player.position + Vector3.UP * 1.2).distance_to(item.at)
		if distance < best and main.can_reach(item.at, 2.8):
			nearest = item
			best = distance
	return nearest

func interact() -> bool:
	var item := candidate()
	if item.is_empty():
		return false
	match item.id:
		"door":
			if door_open and (_in_doorway(main.player.position) or _in_doorway(people.lu.position)):
				main.notify("门口有人，先离开门扇范围再关门。", 2)
				return true
			_set_door(not door_open)
			main.play_world_sound("door_open" if door_open else "door_close", DOOR)
			main.notify("木门已打开。" if door_open else "木门已关闭。", 2)
		"letter":
			read_letter = true
			show_dialog("letter", "未寄出的家书", "娘：山里的霜早了，棉衣还够。林场来了搜山的人，我把去密营的小路留在了老地方。见到陆山，替我问他伤好了没有。\n—— 信没有署名。纸角夹着一片干桦叶。", [{"label": "收进记录，继续行动", "action": "close_save"}])
		"supply":
			supply_taken = true
			bandages += 1
			parcel.visible = false
			main.notify("获得绷带 ×1。Q 为自己包扎，也可留给陆山。", 4)
			main._save_checkpoint()
		_:
			talk(item.id)
	return true

func talk(id: String) -> void:
	match id:
		"scout":
			if not met_scout:
				show_dialog(id, "姜岚", "沈砚，林场的电报房扣下了搜山名册。陆山送信时受了伤，也被关在那里。名单关系着密营和山下接济我们的乡亲。\n先问问前面木棚里的林师傅，再进电报房。我守住回山的路，你把人和名单带回来。", [
					{"label": "知道了。名单和陆山，都带回来。", "action": "brief"},
					{"label": "问清楚电报房和撤离路线", "action": "route"}])
			else:
				show_dialog(id, "姜岚", "穿过木墙缺口，先突破检查口，再沿木料巷往北。清掉守卫才能打开栅门。取名单、拉总闸，接上陆山绕电报房北侧去渡口。别丢下他。", [{"label": "继续行动", "action": "close"}])
		"logger":
			if supply_choice == "none":
				show_dialog(id, "林守义", "陆山在电报房西北角，腿上有伤。昨晚他还替我捎话，说山上的孩子缺棉衣……今天就没能走出那扇门。\n我这儿有一卷干净布，还有藏下的十发步枪弹。你先带哪一样？剩下的留给接应的人。", [
					{"label": "拿绷带，给陆山治伤", "action": "medicine"},
					{"label": "拿十发步枪弹", "action": "ammunition"},
					{"label": "先不拿，等会儿再来", "action": "close"}])
			else:
				show_dialog(id, "林守义", "电报房的门没上锁。桌后的总闸连着电话中继，拉下来能拖住他们。运材场矮箱上还有个医药包；别让陆山一个人留在里面。", [{"label": "谢谢。你也先隐蔽。", "action": "close"}])
		"lu":
			if not recruited:
				var options: Array = []
				if bandages > 0:
					options.append({"label": "消耗一卷绷带，包扎后一起走", "action": "rescue_treat"})
				options.append({"label": "先带你离开，慢慢跟着我", "action": "rescue"})
				options.append({"label": "先在这里隐蔽，我处理电报房", "action": "close"})
				show_dialog(id, "陆山", "名册就在桌上。第三页那个卖豆腐的，上回给我们多塞了两块……他还有两个孩子。别把名字落下。\n我还能走。你慢一点，到拐角等我一下。", options)
			else:
				var options: Array = [{"label": "跟紧我", "action": "follow"}, {"label": "在这里等候，我先探路", "action": "wait"}]
				if not people.lu.treated and bandages > 0:
					options.append({"label": "用绷带处理伤口", "action": "treat"})
				show_dialog(id, "陆山", "听你的。我的脚步可能慢一些，走到拐角时记得回头看看。" if not people.lu.treated else "伤口扎稳了，我能跟上。名单交回去，乡亲们就多一分转移的时间。", options)

func show_dialog(id: String, title: String, text: String, options: Array) -> void:
	if main.mode != "dialogue":
		dialog_yaw = main.player.rotation.y
		dialog_pitch = main.player.pitch
	speaker_id = id
	speaker = title
	speech = text
	choices = options
	revision += 1
	main.mode = "dialogue"
	main.player.fire_requested = false
	main.player.model.visible = true
	main.player.model.position = main.player.WeaponVisuals.SAFE_POSITION
	main.player.model.rotation = main.player.WeaponVisuals.SAFE_ROTATION
	if people.has(id):
		var offset: Vector3 = people[id].position + Vector3.UP * 1.05 - main.player.camera.global_position
		main.player.rotation.y = atan2(-offset.x, -offset.z)
		main.player.camera.rotation.x = atan2(offset.y, Vector2(offset.x, offset.z).length())
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_dialog() -> void:
	main.player.rotation.y = dialog_yaw
	main.player.pitch = dialog_pitch
	main.player.camera.rotation.x = dialog_pitch
	main.player.model.visible = true
	speaker_id = ""
	main.resume()

func choose(index: int) -> void:
	if main.mode != "dialogue" or index < 0 or index >= choices.size():
		return
	var action: String = choices[index].action
	if action == "route":
		show_dialog("scout", "姜岚", "从林道的木墙缺口进入，解决检查口三名岗哨，再打开栅门。木料巷还有四名守卫，清掉后继续开门向北。电报房里有四名日军，入口在右手边。拿名册、断电并接上陆山后，绕房子北侧去渡口；到船边掩护他解缆，守住三十秒。\n林师傅守在北面的木棚。和他当面说清楚，他会给你补给。", [{"label": "记住了，开始行动", "action": "brief"}])
		return
	close_dialog()
	match action:
		"brief":
			met_scout = true
			main.notify("行动记录已更新。J 查看记录；前方木棚可以向林师傅求助。", 6)
		"medicine":
			if supply_choice == "none":
				supply_choice = "medicine"
				bandages += 1
				main.notify("林守义递给你一卷干净布。绷带 +1。", 4)
		"ammunition":
			if supply_choice == "none":
				supply_choice = "ammunition"
				main.player.reserves[0] += 10
				main.notify("获得步枪弹 ×10。医药包还在运材场。", 4)
		"rescue", "rescue_treat":
			recruited = true
			people.lu.following = true
			if action == "rescue_treat":
				_treat()
			main.notify("陆山开始跟随。靠近他按 E 可让他等候或继续跟随。", 5)
		"follow":
			people.lu.following = true
		"wait":
			people.lu.following = false
		"treat":
			_treat()
		"finish":
			if ready_to_leave():
				main.village.depart()
	if action not in ["close", "finish"]:
		main._save_checkpoint()

func _treat() -> void:
	if bandages > 0 and not people.lu.treated:
		bandages -= 1
		people.lu.treated = true

func heal_player() -> void:
	if main.mode != "playing":
		return
	if bandages <= 0:
		main.notify("没有绷带了。", 2)
	elif main.player.health >= 100:
		main.notify("暂时不需要包扎。", 2)
	else:
		bandages -= 1
		main.player.health = minf(100, main.player.health + 40)
		main.player._play("reload")
		main.notify("已包扎，恢复 40 点生命。", 3)

func ready_to_leave() -> bool:
	return recruited and people.lu.position.distance_to(main.EVAC) < 5.5 and main.stage == 2 and main.linear.can_evacuate()

func ending() -> void:
	if recruited and main.linear.enabled and not main.linear.can_evacuate():
		main.notify("带陆山靠近船边，并在渡口掩护他解缆。", 4)
		return
	if not ready_to_leave():
		main.notify("等陆山一起到渡口。靠近他按 E，确认他正在跟随。", 4)
		return
	show_dialog("lu", "陆山", "过河就是松岭屯。名单上几户乡亲还在那里，日军已经进村了。姜岚绕山路先到对岸接应。\n把船靠到南岸，我先守着名册。你和姜岚沿村道往北，把乡亲撤离的路打通。", [{"label": "登船，去松岭屯与姜岚会合。", "action": "finish"}, {"label": "稍等，我再检查一下四周。", "action": "close"}])

func journal_text() -> String:
	var lines: Array[String] = ["1938 年深秋 · 东南满林区 · 青岚林场（虚构）", "我们是东北抗联的一支小分队。此次行动：带回搜山名册，救出交通员陆山。"]
	lines.append("✓ 已与姜岚接头。林师傅在木墙外的北侧木棚。" if met_scout else "• 先与林道上的姜岚当面交谈。")
	if supply_choice != "none":
		lines.append("✓ 林守义提供了%s，并告知总闸与渡口的位置。" % ("绷带" if supply_choice == "medicine" else "十发步枪弹"))
	if read_letter:
		lines.append("家书：没有署名的人仍在为密营传递消息。纸角夹着干桦叶，他惦记着陆山的伤。")
	lines.append("✓ 名册已取得。" if main.stage >= 1 else "• 名册在电报房桌上。")
	lines.append("✓ 电话中继电源已切断，渡口方向有追兵。" if main.stage >= 2 else "• 取回名册后拉下总闸。")
	if recruited:
		lines.append("陆山记得名册第三页的豆腐摊。我们要带回去的是名字，也是还来得及转移的人。")
		lines.append("陆山：%s · %s" % ["伤口已包扎" if people.lu.treated else "受伤，移动较慢", "跟随中" if people.lu.following else "原地等候"])
	else:
		lines.append("• 陆山在电报房西北角。撤离需要他一起到达。")
	if main.linear.enabled:
		lines.append("路线：检查口 → 木料巷 → 电报房 → 渡口 → 顺流过河 → 林间土路 → 松岭屯村口 → 主街 → 北院。到船边照应陆山解缆，和陆山登船过河，再与姜岚沿林间土路进村。")
	if main.village.entered:
		lines.append("松岭屯：陆山在岸边保管名册。先沿浅色土路穿过密林，到村口听取姜岚的接应情报，再沿村道分段清敌、打开院门，肃清全村12名日军后到北侧会合点。")
	return "\n\n".join(lines)

func _set_door(value: bool) -> void:
	door_open = value
	door.position.z = DOOR.z - 3.7 if value else DOOR.z
	door.collision_layer = 0 if value else 1
	main.world.set_office_door(value)

func _in_doorway(at: Vector3) -> bool:
	return absf(at.x - DOOR.x) < 0.7 and absf(at.z - DOOR.z) < 2.1

func snapshot() -> Dictionary:
	var lu: CharacterBody3D = people.lu
	return {"briefed": met_scout, "choice": supply_choice, "letter": read_letter, "supply": supply_taken, "recruited": recruited, "door": door_open, "bandages": bandages, "lu_position": [lu.position.x, lu.position.y, lu.position.z], "following": lu.following, "treated": lu.treated, "moments_seen": moments.seen.duplicate() if is_instance_valid(moments) else []}

func valid(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	if not StoryMoments.valid_flags(data.get("moments_seen", [])):
		return false
	for key in ["briefed", "letter", "supply", "recruited", "door", "following", "treated"]:
		if not data.get(key) is bool:
			return false
	if (data.following or data.treated) and not data.recruited:
		return false
	if data.get("choice") not in ["none", "medicine", "ammunition"] or not main._whole_number(data.get("bandages"), 0, 3):
		return false
	if not data.get("lu_position") is Array or data.lu_position.size() != 3:
		return false
	for value in data.lu_position:
		if not main._number_between(value,-.1,1290): return false
	return main.Layout.contains(Vector3(data.lu_position[0],data.lu_position[1],data.lu_position[2])) or main.VillageDirector.VillageWorld.contains(Vector3(data.lu_position[0],data.lu_position[1],data.lu_position[2]))

func restore(data: Dictionary) -> void:
	reset()
	met_scout = data.briefed
	supply_choice = data.choice
	read_letter = data.letter
	supply_taken = data.supply
	parcel.visible = not supply_taken
	recruited = data.recruited
	bandages = int(data.bandages)
	_set_door(data.door)
	people.lu.position = Vector3(data.lu_position[0], data.lu_position[1], data.lu_position[2])
	people.lu.reset_physics_interpolation()
	people.lu.following = data.following
	people.lu.treated = data.treated
	moments.restore(data.get("moments_seen", []))

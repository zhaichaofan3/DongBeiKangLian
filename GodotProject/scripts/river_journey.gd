extends Node3D
## Boarding, a downstream passage and a matched landing into the playable forest.

const Human = preload("res://scripts/human_model.gd")
const Forest = preload("res://scripts/forest_approach.gd")
const DURATION := 38.0
const CAPTIONS := [
	[1.0,5.7,"陆山：名册在我怀里。你先稳住船，我慢慢下来。"],
	[7.0,11.5,"沈砚：坐稳。借着水流走，别让岸上的人发现。"],
	[16.0,21.5,"陆山：松岭屯就在那片林子后头。名单上的乡亲，还不知道日军进了村。"],
	[29.0,34.5,"姜岚：这边！林子里暂时安全，顺着土路走就到村口。"],
	[34.5,37.5,"沈砚：陆山，你护住名册，留在岸边等我们。"]]
var main: Node3D
var director: Node
var stage: Node3D
var boat: Node3D
var rower: Node3D
var courier: Node3D
var greeter: Node3D
var camera: Camera3D
var ui: CanvasLayer
var caption: Label
var water_audio: AudioStreamPlayer
var route := Curve3D.new()
var hidden_nodes: Array[Node3D] = []
var shot_id := ""
var boat_distance := 0.0

func initialize(owner_node: Node3D, owner_director: Node) -> void:
	main = owner_node
	director = owner_director
	name = "双人渡河演出"
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	stage = Node3D.new()
	stage.position = Vector3(600,0,600)
	add_child(stage)
	var river: Node3D = main.world.build_supplied_river(Vector3(-17,0,-35))
	river.reparent(stage,false)
	river.scale.z = 2
	var dock: Node3D = main.world.build_supplied_dock(Vector3(-28,0,0))
	dock.reparent(stage,false)
	boat = (load("res://assets/user_expansion_20261015/boat.glb") as PackedScene).instantiate() as Node3D
	boat.name = "行进中的原木船"
	stage.add_child(boat)
	rower = Human.new()
	rower.build("scout")
	rower.set_armed(true)
	stage.add_child(rower)
	courier = Human.new()
	courier.build("wounded")
	courier.set_motion_context(main.story.people.lu.treated)
	stage.add_child(courier)
	greeter = Human.new()
	greeter.build("scout")
	greeter.set_armed(true)
	stage.add_child(greeter)
	greeter.global_position = Forest.SCOUT
	_build_banks()
	for point in [Vector3(-18.9,0,12.7),Vector3(-16,0,-20),Vector3(-20,0,-48),Vector3(-21,0,-77)]:
		route.add_point(point,Vector3(-1.2,0,5),Vector3(1.2,0,-5))
	camera = Camera3D.new()
	camera.fov = 58
	camera.environment = main.world.village_world.environment
	add_child(camera)
	ui = CanvasLayer.new()
	ui.layer = 39
	add_child(ui)
	for top in [true,false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.anchor_right = 1
		bar.anchor_top = 0 if top else .92
		bar.anchor_bottom = .065 if top else 1
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(bar)
	caption = Label.new()
	caption.anchor_left = .12
	caption.anchor_right = .88
	caption.anchor_top = .78
	caption.anchor_bottom = .91
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_size_override("font_size",20)
	caption.add_theme_color_override("font_shadow_color",Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x",2)
	caption.add_theme_constant_override("shadow_offset_y",2)
	ui.add_child(caption)
	water_audio = AudioStreamPlayer.new()
	water_audio.stream = load("res://assets/audio/user_sfx_20261015/river.mp3").duplicate()
	water_audio.stream.loop = true
	water_audio.volume_db = -18
	add_child(water_audio)
	main.audio_mix.register_player(water_audio,&"Ambience","transition")
	for node in main.guards+main.story.people.values():
		if is_instance_valid(node) and node.visible:
			hidden_nodes.append(node)
			node.visible = false
	for node in main.get_children():
		if node is Node3D and node.get_meta("user_waterfront","")=="boat" and node.position.x>900:
			hidden_nodes.append(node)
			node.visible = false
	main.player.sound.stop()
	main.player.bolt_sound.stop()
	main.player.footsteps.stop()
	main.enemy_audio.stop()
	water_audio.play()
	main.player.model.visible = false
	main.player.velocity = Vector3.ZERO
	sample(0,0)
	camera.make_current()

func _build_banks() -> void:
	for side in [-1,1]:
		var body: Node3D = main.world.box("渡河镜头林岸",Vector3(side*41-17,-.8,-55),Vector3(32,1.2,320),"mud",false)
		body.reparent(stage,false)
		for i in 84:
			var tree := (load("res://assets/environment/landscape/far_pine.glb") as PackedScene).instantiate() as Node3D
			tree.position = Vector3(side*(29+i%4*3)-17,-.2,40-i*3.1)
			tree.scale = Vector3.ONE*(1.6+(i%5)*.18)
			tree.rotation.y = i*2.1
			stage.add_child(tree)

func sample(time: float, delta: float) -> void:
	var at := clampf(time,0,DURATION)
	var t := clampf((at-8)/19.0,0,1)
	boat_distance = route.get_baked_length()*t
	var location := route.sample_baked(boat_distance,true)
	var next := route.sample_baked(minf(route.get_baked_length(),boat_distance+.6),true)
	var direction := next-location
	if direction.length_squared()<.001: direction = Vector3(0,0,-1)
	boat.position = location+Vector3(0,-1.7+sin(at*1.7)*.018,0)
	boat.rotation = Vector3(sin(at*.8)*.012,atan2(-direction.x,-direction.z),sin(at*1.3)*.018)
	greeter.visible = at>=27.7
	if at>=27.7:
		var arriving := smoothstep(27.7,31,at)
		boat.global_position = Vector3(1220,-1.7,452).lerp(Vector3(1214,-1.7,439.6),arriving)
		boat.rotation.y = lerp_angle(-.5,0,arriving)
	_board_actor(courier,at,1,5.5,Vector3(-19,.06,6.8),Vector3(.15,.2,-.72),delta)
	_board_actor(rower,at,3,7.7,Vector3(-19,.06,4.9),Vector3(-.15,.2,.65),delta)
	if at>=31:
		_unboard(rower,at,31,36.5,Forest.LANDING,Vector3(-.15,.2,.65),delta)
		_unboard(courier,at,32,37.3,Forest.REST,Vector3(.15,.2,-.72),delta)
	greeter.animate(delta,0,at>=29 and at<34.5)
	greeter.rotation.y = PI
	if at<8:
		shot_id = "boarding"
		_camera(stage.to_global(Vector3(-9,3.4,20)),stage.to_global(Vector3(-19,-.1,10)),58)
	elif at<17:
		shot_id = "river-wide"
		_camera(boat.global_position+Vector3(11,6.3,12),boat.global_position+Vector3(0,.8,-2),55)
	elif at<27.7:
		shot_id = "river-onboard"
		_camera(boat.global_position+Vector3(4.4,2.1,3.5),boat.global_position+Vector3(0,1.1,-.35),59)
	else:
		shot_id = "landing"
		_camera(Vector3(1222,3.6,445),Vector3(1214,.3,433),59)
	caption.text = ""
	for cue in CAPTIONS:
		if at>=cue[0] and at<cue[1]: caption.text = cue[2]
	var blackout := 1.0-smoothstep(0,.7,at)
	blackout = maxf(blackout,smoothstep(27.1,27.65,at)*(1.0-smoothstep(27.8,28.35,at)))
	blackout = maxf(blackout,smoothstep(37.4,38,at))
	director.fade.color.a = blackout
	caption.visible = blackout<.7

func _camera(at: Vector3, target: Vector3, fov: float) -> void:
	camera.global_position = at
	camera.look_at(target)
	camera.fov = fov

func _board_actor(actor: Node3D, time: float, start: float, end: float, from: Vector3, seat: Vector3, delta: float) -> void:
	var t := clampf((time-start)/(end-start),0,1)
	var seated := smoothstep(.76,1,t)
	var destination := boat.global_transform*seat
	var origin := stage.to_global(from)
	var edge := stage.to_global(Vector3(-18.9,.06,9.8))
	if time<8 and t<.58:
		actor.global_position = origin.lerp(edge,t/.58)
	elif time<8:
		actor.global_position = edge.lerp(destination,smoothstep(.58,.92,t))
		actor.global_position.y += sin(clampf((t-.58)/.34,0,1)*PI)*.22
	else: actor.global_position = destination
	actor.rotation.y = lerp_angle(PI,boat.rotation.y,smoothstep(.58,1,t))
	actor.animate(delta,1.65 if t>0 and t<.82 else 0)
	_pose_seated(actor,seated)
	_sling(actor)

func _unboard(actor: Node3D, time: float, start: float, end: float, target: Vector3, seat: Vector3, delta: float) -> void:
	var t := clampf((time-start)/(end-start),0,1)
	var origin := boat.global_transform*seat
	# Step onto the pier before walking along it, rather than sliding across the water.
	var pier := Vector3(1214,.28,437)
	if t<.35:
		actor.global_position = origin.lerp(pier,smoothstep(0,.35,t))
	else:
		actor.global_position = pier.lerp(target,(t-.35)/.65)
	actor.rotation.y = 0
	actor.animate(delta,2.4 if t>.08 and t<.99 else 0)
	_pose_seated(actor,1.0-smoothstep(0,.2,t))
	_sling(actor)

func _pose_seated(actor: Node3D, weight: float) -> void:
	actor.hips.position.y = lerpf(actor.hips.position.y,.56,weight)
	for i in 2:
		actor.legs[i].rotation.x = lerpf(actor.legs[i].rotation.x,1.35,weight)
		actor.knees[i].rotation.x = lerpf(actor.knees[i].rotation.x,-1.35,weight)
		actor.feet[i].rotation.x *= 1.0-weight
		actor.arms[i].rotation.x = lerpf(actor.arms[i].rotation.x,.5,weight)
		actor.elbows[i].rotation.x = lerpf(actor.elbows[i].rotation.x,.8,weight)
	actor._sync_detailed_model()

func _sling(actor: Node3D) -> void:
	if actor.rifle==null: return
	actor.rifle.position = Vector3(.15,.04,.36)
	actor.rifle.rotation = Vector3(1.4,0,.18)
	actor._sync_detailed_model()

func set_paused(value: bool) -> void:
	ui.visible = not value
	water_audio.stream_paused = value

func release() -> void:
	water_audio.stream_paused = false
	water_audio.stop()
	for node in hidden_nodes:
		if is_instance_valid(node): node.visible = true
	hidden_nodes.clear()
	ui.visible = false
	visible = false

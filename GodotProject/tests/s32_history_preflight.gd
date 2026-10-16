extends SceneTree

var main: Node3D
var checks: Array[Dictionary] = []
var evidence := ""

func _initialize() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(2); return
	evidence = OS.get_environment("FENGHUO_S32_EVIDENCE")
	if evidence.is_empty(): quit(2); return
	_run.call_deferred()

func check(value: bool, description: String) -> void:
	checks.append({"passed":value,"description":description})
	print("PASS: " if value else "FAIL: ",description)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(evidence)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.save_path = "user://s32_history_%d.json" % OS.get_process_id()
	main.start_with_opening()
	var opening = main.opening
	opening.set_process(false)
	main.set_process(false)
	var shots: Array = opening.data.shots.filter(func(item): return item.part == "A")
	var counts := {}
	for shot in shots: counts[shot.segment] = int(counts.get(shot.segment,0))+1
	check(shots.size()==12,"History preflight contains 12 authored A shots including the telegraph insert")
	check(counts=={"A1":1,"A2":1,"A3":5,"A4":2,"A5":2,"A6":1},"A1-A6 shot coverage matches the storyboard")
	check(opening.data.durations_ms.A==68180 and opening.data.cues.A.size()==17,"Historical duration and original narration plus two new cues are present")
	check(opening.voice_streams.size()==8 and opening.HISTORY_AUDIO.get_length()>68,"Full history track and eight supplied B dialogue recordings are available")
	check(opening.blasts.size()==4 and opening.data.events.any(func(item): return item.id=="A_TITLE"),"The history climax has four authored artillery effects and a closing title event")
	var before: Dictionary = main._snapshot()
	opening.preview_at("A",33.5)
	check(opening.shot.segment=="A4" and opening.effects.visible and opening.blasts[0].visible,"A4 preview activates authored fireline and first barrage impact")
	opening.preview_at("A",40.5)
	check(opening.shot_id=="A-14" and opening.blasts[3].visible,"A14 keeps the final distant blast in frame after its look-at correction")
	# N15 continues through the tail of A5; sample before A6 begins at 75.7s.
	opening.preview_at("A",50.0)
	check(opening.shot.segment=="A5" and opening.current_cue=="N15","A5 carries the last narration into the spiritual close before handoff")
	opening.preview_at("A",62.0)
	check(opening.shot.segment=="A6" and opening.shot_id=="A-18" and not opening.lake.visible,"A6 shows the added continuous building panorama")
	check(main._snapshot().player==before.player and main._snapshot().story==before.story and main._snapshot().kills==before.kills,"History previews never mutate gameplay resources or mission state")
	opening.skip("A")
	check(opening.part=="B" and opening.active and not main.story.met_scout,"History skip enters the separate task prologue boundary")
	opening.last_skip_ms = -1000
	opening.skip("B")
	check(main.mode=="playing" and main.story.met_scout and opening.handoff_count==1,"Both opening parts share one gameplay handoff")
	var passed:=true
	for item in checks: passed=passed and item.passed
	var report={"step":"S32","status":"preflight_in_progress","all_passed":passed,"checks":checks,"shots_A":shots.size(),"voice":"user_supplied_full_mix","music":"embedded_history_global_suppressed","sfx_listening":"pending"}
	FileAccess.open(evidence.path_join("history-preflight.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("S32 HISTORY PREFLIGHT: ","PASS" if passed else "FAIL"," | checks=",checks.size())
	for kind in ["AudioStreamPlayer","AudioStreamPlayer3D"]:
		for sound in main.find_children("*",kind,true,false): sound.stop()
	await create_timer(.1).timeout
	main.queue_free()
	await process_frame
	quit(0 if passed else 1)

extends SceneTree
## Independent pose captures and hand-resource checks. Uses unique save paths.
var main: Node3D
var capture_dir := "C:/GameMake/AssetReview/previews/gameplay_hands"
var temporary_save := ""
var temporary_settings := ""
var findings: Array = []
func _initialize() -> void:
    if "--qa" not in OS.get_cmdline_user_args():
        quit(2)
        return
    temporary_save="user://fp_hands_review_%s.json" % OS.get_process_id()
    temporary_settings="user://fp_hands_review_%s.cfg" % OS.get_process_id()
    if not OS.get_environment("FENGHUO_HANDS_REVIEW_DIR").is_empty():
        capture_dir = OS.get_environment("FENGHUO_HANDS_REVIEW_DIR")
    call_deferred("run")
func shot(label: String, gun: int, reload_progress: float, fire_age: float, aim: bool=false) -> void:
    main.player.switch_weapon(gun)
    main.player.switch_age=1.0
    main.player.aiming=aim
    main.player.aim_blend=1.0 if aim else 0.0
    main.player.camera.fov=54.0 if aim else 78.0
    main.player.visual_fire_age=fire_age
    main.player.reload_timer=(1.0-reload_progress)*main.player.WEAPONS[gun].reload if reload_progress>=0 else 0.0
    if reload_progress>=0: main.player.WeaponVisuals.prepare_reload(main.player.weapon_rigs[gun],5 if gun==0 else 10)
    main.player.model.position=main.player.WeaponVisuals.AIM_POSITIONS[gun] if aim else main.player.WeaponVisuals.HIP_POSITIONS[gun]
    main.player.model.rotation=Vector3.ZERO if aim else main.player.WeaponVisuals.HIP_ROTATION
    if reload_progress>=0:
        main.player.model.position+=Vector3(-0.055,-0.022,-0.005)
        main.player.model.rotation+=Vector3(-0.10,-0.25,0.29)
    main.player._animate_mechanism(1.0)
    await process_frame
    for i in 120:
        if main.world.is_world_ready(): break
        await process_frame
    await process_frame
    var rig: Dictionary=main.player.weapon_rigs[gun]
    var frame_points := {}
    var landmarks := {"muzzle":rig.muzzle,"receiver":Vector3(0,.065,-.04),"support_wrist":rig.left.position}
    for landmark in landmarks:
        var local_point: Vector3 = landmarks[landmark]
        var screen: Vector2 = main.player.camera.unproject_position(rig.root.to_global(local_point)) / Vector2(root.size)
        frame_points[landmark] = [screen.x,screen.y]
    var right_joints := {}
    for bone_name in ["f_index_02_R", "f_index_03_R", "f_middle_02_R", "f_middle_03_R", "thumb_02_R", "thumb_03_R"]:
        var bone_index: int = rig.right.skeleton.find_bone(bone_name)
        if bone_index >= 0:
            var joint_at: Vector3 = rig.right.skeleton.to_global(rig.right.skeleton.get_bone_global_pose(bone_index).origin)
            right_joints[bone_name] = str(rig.root.to_local(joint_at))
    findings.append({"pose":label,"weapon":gun,"left_bones":rig.left.skeleton.get_bone_count(),"right_bones":rig.right.skeleton.get_bone_count(),"left_position":str(rig.left.position),"right_position":str(rig.right.position),"clip_visible":rig.clip.visible,"right_joints":right_joints,"bolt_knob":str(rig.bolt.transform * Vector3(0.078,0.01,0.035))})
    findings[-1]["screen_points_uv"] = frame_points
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(capture_dir.path_join(label+".png"))
func run() -> void:
    DirAccess.make_dir_recursive_absolute(capture_dir)
    main=load("res://main.tscn").instantiate()
    main.save_path=temporary_save
    root.add_child(main)
    await process_frame
    main.presentation.settings_path=temporary_settings
    main.start_new()
    for guard in main.guards: guard.set_physics_process(false)
    main.player.position=Vector3(16, 0.08, 278)
    main.player.rotation.y=-0.4
    main.player.pitch=-0.035
    main.player.reset_physics_interpolation()
    await create_timer(0.5).timeout
    main.player.set_physics_process(false)
    main.player.set_process(false)
    main.player.camera.rotation.x=-0.035
    await shot("rifle_hold",0,-1,2.0)
    await shot("rifle_aim",0,-1,2.0,true)
    await shot("rifle_bolt",0,-1,0.39)
    await shot("rifle_load_present",0,0.35,2.0)
    await shot("rifle_load_press",0,0.57,2.0)
    await shot("rifle_load_inserted",0,0.65,2.0)
    await shot("rifle_load_empty_clip",0,0.73,2.0)
    await shot("pistol_hold",1,-1,2.0)
    await shot("pistol_aim",1,-1,2.0,true)
    await shot("pistol_load",1,0.49,2.0)
    main.start_with_opening()
    main.set_process(false)
    main.opening.set_process(false)
    for sample in [["opening_talk",3.1],["opening_handoff",79.5]]:
        main.opening.preview_at("B",sample[1])
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(capture_dir.path_join(sample[0]+".png"))
    main.opening.abort()
    var f:=FileAccess.open(capture_dir.path_join("pose_resources.json"),FileAccess.WRITE)
    f.store_string(JSON.stringify(findings,"  "))
    f.close()
    main.mode="paused"
    for audio in [main.ambience, main.enemy_audio, main.player.sound, main.player.footsteps, main.story.moments.river_audio, main.story.moments.radio_audio, main.story.moments.switch_audio]:
        audio.stop()
    main.queue_free()
    await process_frame
    await create_timer(0.15).timeout
    DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_save))
    if FileAccess.file_exists(temporary_settings): DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_settings))
    print("FP_HANDS_REVIEW_COMPLETE ",findings.size())
    quit()

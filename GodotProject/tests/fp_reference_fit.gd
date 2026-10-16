extends "res://tests/fp_hands_review.gd"
## Offline pose fitting contact sheet; never loaded by the game.
func run() -> void:
    DirAccess.make_dir_recursive_absolute(capture_dir)
    main = load("res://main.tscn").instantiate()
    main.save_path = temporary_save
    root.add_child(main)
    await process_frame
    main.presentation.settings_path = temporary_settings
    main.start_new()
    for guard in main.guards: guard.set_physics_process(false)
    main.player.position = Vector3(16, 0.08, 278)
    main.player.rotation.y = -0.4
    main.player.pitch = -0.035
    main.player.reset_physics_interpolation()
    await create_timer(0.5).timeout
    main.player.set_physics_process(false)
    main.player.set_process(false)
    main.player.camera.rotation.x = -0.035
    for turn in [-40.0, -70.0, -130.0, -160.0]:
        var fitted := Basis(Vector3.BACK, deg_to_rad(70.0)) * Basis(Vector3.BACK, Vector3.RIGHT, Vector3.UP) * Basis(Vector3.UP, deg_to_rad(turn))
        main.player.hand_rest[0].left_rotation = fitted.get_euler()
        await shot("turn_%d" % absi(int(turn)),0,-1,2.0)
    var f := FileAccess.open(capture_dir.path_join("pose_resources.json"),FileAccess.WRITE)
    f.store_string(JSON.stringify(findings,"  "))
    f.close()
    main.mode = "paused"
    for audio in [main.ambience, main.enemy_audio, main.player.sound, main.player.footsteps]: audio.stop()
    main.queue_free()
    await process_frame
    await create_timer(0.15).timeout
    DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_save))
    if FileAccess.file_exists(temporary_settings): DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary_settings))
    print("REFERENCE_FIT_COMPLETE ",findings.size())
    quit()

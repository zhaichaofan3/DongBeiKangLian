# 项目代码与工具入口索引

只静态提取当前游戏scripts/tests、根启动器、tools顶层及continuation自有代码；第三方运行库不逐函数展开。行号是本次扫描位置，之后修改会变化。函数存在不代表运行验收通过。

## Auto-Resume.vbs

新自动接续面板入口，默认停止，用户点击后才授权逐步执行。

定义：入口脚本，无可提取的函数/类定义。

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## Build-Game.ps1

Godot 源工程构建与发布包原子替换入口。

定义：入口脚本，无可提取的函数/类定义。

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## GodotProject/scripts/asset_dressing.gd

环境视觉布景；S11 的 D05-D09 生活/生产道具在此构建。

定义：`pbr`（第20行）；`material_for`（第38行）；`build`（第50行）；`build_s11`（第61行）；`_mark_s11`（第102行）；`_wood_box`（第109行）；`_log_bundle`（第114行）；`_ground_surfaces`（第128行）；`_forest_edge`（第163行）；`_shelter`（第181行）；`_office`（第193行）；`_spawn`（第205行）；`_bounds`（第251行）；`_meshes`（第263行）；`_visual`（第271行）；`_ground_patch`（第284行）；`_quad`（第298行）；`_fixture`（第302行）；`set_power`（第326行）；`apply_quality`（第332行）

资源引用：`res://assets/environment/`；`res://assets/environment/models/s11/chinese_screen_panels/chinese_screen_panels_2k.gltf`；`res://assets/environment/models/s11/chinese_tea_table/chinese_tea_table_2k.gltf`；`res://assets/environment/models/s11/market_stalls/market_stalls.glb`；`res://assets/environment/models/s11/village_market/village_market.glb`；`res://assets/environment/models/s11/wicker_basket_01/wicker_basket_01_2k.gltf`

## GodotProject/scripts/audio_factory.gd

运行时生成/管理环境、枪声、开关和音频节点。

定义：`make_sound`（第7行）；`make_wind`（第42行）

资源引用：`res://assets/audio/forest_wind_loop.wav`；`res://assets/audio/rifle_arisaka_01.wav`；`res://assets/audio/step_grass_01.wav`

## GodotProject/scripts/field_character_rig.gd

四类东北抗联/守卫人物的连续蒙皮骨架与运行时姿态。

定义：`prepare`（第20行）；`bind`（第37行）；`sync_pose`（第53行）；`_global_pose`（第67行）；`_relative_transform`（第74行）；`_find_skeleton`（第82行）；`_prepare_role`（第89行）

资源引用：`res://assets/characters/field_character.glb`

## GodotProject/scripts/fp_hands.gd

第一人称左右手、握枪、拉栓、装填和手部动作。

定义：`create`（第21行）；`_build`（第29行）；`_find_skeleton`（第62行）；`_prepare_skin`（第69行）；`pose`（第78行）；`bolt_contact`（第113行）；`_cuff_mesh`（第125行）；`_cuff_details`（第144行）；`update_sleeve`（第177行）

资源引用：`res://assets/first_person/hand_left.glb`；`res://assets/first_person/hand_right.glb`；`res://scripts/fp_hands.gd`

## GodotProject/scripts/fps_player.gd

玩家移动、视角、射击、瞄准、换弹、互动和输入。

定义：`initialize`（第47行）；`_unhandled_input`（第80行）；`_physics_process`（第99行）；`_process`（第144行）；`_animate_mechanism`（第199行）；`_envelope`（第263行）；`_can_stand`（第266行）；`fire`（第271行）；`start_reload`（第300行）；`switch_weapon`（第306行）；`take_damage`（第318行）；`restore`（第327行）；`snapshot`（第377行）；`_play`（第380行）；`_build_weapons`（第384行）

资源引用：`res://scripts/audio_factory.gd`；`res://scripts/weapon_visuals.gd`

## GodotProject/scripts/friendly.gd

友方侦察员、林工和陆山的互动、跟随、等候与护送逻辑。

定义：`initialize`（第15行）；`_physics_process`（第41行）；`reset`（第80行）

资源引用：`res://scripts/human_model.gd`

## GodotProject/scripts/guard.gd

敌人巡逻、感知、瞄准、开火、受击和死亡逻辑。

定义：`initialize`（第23行）；`_physics_process`（第42行）；`can_see_player`（第111行）；`hear_shot`（第126行）；`take_damage`（第135行）；`encounter_snapshot`（第148行）；`restore_encounter`（第154行）；`valid_encounter`（第168行）；`_valid_number`（第183行）；`_build_model`（第186行）

资源引用：`res://scripts/human_model.gd`

## GodotProject/scripts/hud.gd

中文 HUD、目标、对白选择、暂停、菜单和提示。

定义：`initialize`（第32行）；`_process`（第126行）；`_build_menu`（第175行）；`show_menu`（第202行）；`_show_settings`（第263行）；`_build_conversation`（第337行）；`_refresh_dialogue`（第356行）；`_button`（第373行）；`_label`（第380行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## GodotProject/scripts/human_model.gd

第三人称人物模型、骨骼姿态、服装材质和动画驱动。

定义：`build`（第34行）；`_build_detailed_model`（第148行）；`_sync_detailed_model`（第181行）；`_build_rifle`（第184行）；`set_motion_context`（第195行）；`fire`（第200行）；`flinch`（第203行）；`fall`（第206行）；`animate_death`（第209行）；`animate`（第235行）；`_pose_guard_grip`（第306行）；`_limb_basis`（第337行）；`_joint`（第346行）；`_surface`（第353行）；`_triangle`（第360行）；`_box`（第369行）；`_loft`（第389行）；`_oval`（第425行）；`_flush_meshes`（第432行）

资源引用：`res://scripts/field_character_rig.gd`

## GodotProject/scripts/linear_director.gd

线性关卡区段、栅门、追兵、检查点和路线状态。

定义：`initialize`（第14行）；`reset`（第18行）；`set_enabled`（第26行）；`_sync_gates`（第30行）；`gate_ready`（第34行）；`_near_gate`（第43行）；`_needs_ammo`（第50行）；`interact`（第53行）；`interaction_prompt`（第74行）；`can_guard_act`（第88行）；`update`（第98行）；`can_evacuate`（第118行）；`status_text`（第121行）；`objective_text`（第134行）；`target_name`（第149行）；`target_position`（第160行）；`snapshot`（第169行）；`restore`（第173行）；`valid_snapshot`（第185行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## GodotProject/scripts/mission.gd

任务状态、取册、断电、救援、解缆和胜利条件。

定义：`_ready`（第63行）；`_process`（第111行）；`_unhandled_input`（第126行）；`start_new`（第158行）；`start_with_opening`（第181行）；`_ensure_opening`（第189行）；`retry_opening_save`（第195行）；`return_to_menu`（第202行）；`resume`（第207行）；`lose`（第215行）；`interact`（第219行）；`interaction_prompt`（第252行）；`can_reach`（第272行）；`objective_text`（第284行）；`target_name`（第294行）；`target_position`（第304行）；`notify`（第313行）；`hear_shot`（第317行）；`guard_shot`（第322行）；`impact`（第338行）；`alive_guard_count`（第349行）；`_spawn_guard`（第356行）；`_spawn_initial_guards`（第368行）；`_reset_guards`（第373行）；`_update_reinforcements`（第387行）；`_reinforcement_entry_safe`（第410行）；`register_guard_defeat`（第427行）；`_snapshot`（第436行）；`_save_checkpoint`（第445行）；`has_save`（第465行）；`_read_save`（第468行）；`_valid_opening_snapshot`（第514行）；`_valid_encounter`（第524行）；`_number_between`（第553行）；`_whole_number`（第556行）；`continue_checkpoint`（第559行）；`elapsed_text`（第616行）；`_configure_input`（第619行）；`_capture_views`（第636行）

资源引用：`res://captures`；`res://scripts/audio_factory.gd`；`res://scripts/fps_player.gd`；`res://scripts/guard.gd`；`res://scripts/hud.gd`；`res://scripts/linear_director.gd`；`res://scripts/opening_director.gd`；`res://scripts/presentation.gd`；`res://scripts/story.gd`；`res://scripts/world.gd`

## GodotProject/scripts/opening_director.gd

S07 双段开场草案、字幕、镜头控制、暂停/跳过和交接。

定义：`initialize`（第48行）；`_build_stage`（第57行）；`_audio`（第129行）；`_set_visual_layer`（第136行）；`_box`（第140行）；`_sphere`（第145行）；`_mesh`（第155行）；`_build_ui`（第166行）；`_label`（第212行）；`start`（第225行）；`_enter_part`（第247行）；`_process`（第258行）；`advance`（第262行）；`_update_view`（第274行）；`_update_effects`（第343行）；`_speaker_at`（第367行）；`_update_captions`（第373行）；`_update_sound`（第392行）；`skip`（第408行）；`set_paused`（第414行）；`handle_input`（第422行）；`finish`（第433行）；`abort`（第448行）；`preview_at`（第463行）；`_v`（第471行）

资源引用：`res://assets/opening/opening.json`；`res://assets/opening/tianchi_reference.glb`；`res://scripts/audio_factory.gd`；`res://scripts/human_model.gd`；`res://scripts/weapon_visuals.gd`

## GodotProject/scripts/presentation.gd

标题页、画质/性能、帧率、声音、灵敏度和显示设置。

定义：`initialize`（第16行）；`load_preferences`（第25行）；`_number`（第39行）；`_boolean`（第45行）；`save_preferences`（第49行）；`apply_all`（第57行）；`set_quality`（第67行）；`change`（第75行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## GodotProject/scripts/route_blockout.gd

S09 简化路线体块、碰撞、导航保留和 S10/S11 占位替换。

定义：`overlaps_slot`（第21行）；`retain`（第26行）；`build`（第31行）；`_piece`（第77行）；`_building`（第86行）；`_reviewed_model`（第97行）；`_reviewed_building`（第112行）；`_reviewed_collision`（第116行）；`set_enabled`（第130行）；`hide_s11_slot_visuals`（第156行）；`restore_position`（第177行）

资源引用：`res://assets/environment/buildings/`

## GodotProject/scripts/story.gd

故事状态、简报、对白和任务阶段保存/恢复。

定义：`initialize`（第32行）；`_add_person`（第48行）；`reset`（第54行）；`candidate`（第70行）；`interact`（第88行）；`talk`（第112行）；`show_dialog`（第143行）；`close_dialog`（第161行）；`choose`（第169行）；`_treat`（第211行）；`heal_player`（第216行）；`ready_to_leave`（第229行）；`ending`（第232行）；`journal_text`（第241行）；`_set_door`（第259行）；`_in_doorway`（第265行）；`snapshot`（第268行）；`valid`（第272行）；`restore`（第288行）

资源引用：`res://scripts/friendly.gd`；`res://scripts/story_moments.gd`

## GodotProject/scripts/story_moments.gd

任务内短对白、人物互动、补给、包扎和故事提示。

定义：`initialize`（第18行）；`_spatial_loop`（第31行）；`reset`（第45行）；`sync_stage`（第52行）；`restore`（第63行）；`valid_flags`（第69行）；`_process`（第77行）；`_say`（第125行）

资源引用：`res://assets/audio/power_switch_off.wav`；`res://assets/audio/radio_room_loop.wav`；`res://assets/audio/river_bank_loop.wav`

## GodotProject/scripts/weapon_visuals.gd

枪械外观、枪口火焰、烟气、弹壳和视觉反馈。

定义：`build`（第9行）；`_hand`（第85行）；`_clip_geometry`（第88行）；`_ensure_materials`（第95行）；`_append`（第131行）；`_bake`（第138行）；`_box`（第147行）；`_ellipsoid`（第152行）；`_rod`（第160行）；`_loop`（第172行）；`_loft`（第178行）；`_triangle`（第199行）

资源引用：`res://scripts/fp_hands.gd`

## GodotProject/scripts/world.gd

世界场景、导航网格、环境、建筑、布景和资源装配入口。

定义：`build`（第30行）；`cell_position`（第122行）；`cell_at`（第125行）；`path`（第128行）；`relocate_to_walkable`（第138行）；`set_route_gate`（第158行）；`_build_route_gate`（第170行）；`_build_linear_route`（第201行）；`_route_sign`（第226行）；`_block`（第232行）；`_build_office`（第253行）；`_build_yard`（第277行）；`_build_river`（第302行）；`_build_reeds`（第322行）；`_build_distant_scene`（第347行）；`_build_lamps`（第358行）；`_setup_environment`（第370行）；`_material`（第404行）；`set_power`（第475行）；`cylinder`（第483行）；`_pitched_roof`（第497行）；`_tree`（第519行）；`_canopy_mesh`（第535行）；`_triangle`（第576行）；`_strip`（第582行）；`_build_ground_cover`（第589行）；`_is_dock_deck`（第623行）；`_build_forest`（第627行）；`_build_mountain_ridges`（第645行）；`_build_details`（第670行）；`_foliage_material`（第721行）；`_build_boat`（第730行）；`_build_close_details`（第759行）；`_build_atmosphere`（第809行）；`_batch_static_visuals`（第876行）；`apply_quality`（第923行）；`update`（第945行）；`_collision_only_box`（第951行）；`box`（第956行）；`visual`（第974行）；`_sign`（第983行）

资源引用：`res://assets/environment/hdris/kloofendal_overcast_puresky/kloofendal_overcast_puresky_2k.hdr`；`res://scripts/asset_dressing.gd`；`res://scripts/route_blockout.gd`；`res://shaders/forest_foliage.gdshader`；`res://shaders/river.gdshader`

## GodotProject/tests/character_model.gd

四类人物模型、骨骼、材质和比例检查。

定义：`_initialize`（第20行）；`check`（第28行）；`_run`（第36行）；`_build_stage`（第175行）；`_focus`（第224行）；`_settle`（第230行）；`_find_skeleton`（第237行）；`_collect_meshes`（第246行）；`_binding_bone`（第252行）；`_validate_skin_bindings`（第258行）；`_skin_bounds`（第296行）；`_finite_aabb`（第334行）；`_bone_snapshot`（第337行）；`_changed_bones`（第343行）；`_bone_position`（第350行）；`_guard_grip_error`（第355行）；`_death_arms_converge`（第373行）；`_capture`（第392行）；`_finish`（第404行）

资源引用：`res://scripts/human_model.gd`

## GodotProject/tests/combat_performance_monitor.gd

正常 AI 交火帧时间和射击计数。

定义：`initialize`（第35行）；`_player_ammo`（第54行）；`_track_shots`（第60行）；`_flag`（第76行）；`_check_render_target`（第79行）；`_check_configuration`（第95行）；`_process`（第111行）；`_summary`（第151行）；`finish`（第164行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## GodotProject/tests/combat_route.gd

敌人、射击、任务路线和撤离回归。

定义：`_initialize`（第9行）；`_run`（第16行）；`_clear_gate`（第93行）；`_combat`（第111行）；`_route`（第134行）；`_walk`（第146行）

资源引用：`res://main.tscn`

## GodotProject/tests/environment_v04.gd

早期环境资源导入和场景检查。

定义：`_initialize`（第7行）；`_run`（第14行）

资源引用：`res://main.tscn`

## GodotProject/tests/fp_hands_review.gd

第一人称双手导入、网格和姿态检查。

定义：`_initialize`（第8行）；`shot`（第15行）；`run`（第42行）

资源引用：`res://main.tscn`

## GodotProject/tests/linear_route.gd

线性栅门、护送、检查点和完整通关回归。

定义：`_initialize`（第9行）；`check`（第16行）；`_run`（第24行）；`_test_extraction`（第116行）；`_test_save_compatibility`（第146行）；`_defeat`（第172行）；`_frames`（第178行）；`_write_save`（第185行）

资源引用：`res://main.tscn`

## GodotProject/tests/opening.gd

开场状态、字幕、跳过和交接断言。

定义：`_initialize`（第8行）；`check`（第14行）；`_run`（第19行）；`_check_handoff`（第151行）；`_without_pose`（第156行）；`_write_save`（第162行）；`_capture_shots`（第167行）

资源引用：`res://main.tscn`

## GodotProject/tests/opening_live.gd

真实渲染开场播放和截图。

定义：`_initialize`（第5行）；`_run`（第11行）

资源引用：`res://main.tscn`

## GodotProject/tests/performance.gd

固定场景性能采样。

定义：`_initialize`（第7行）；`_run`（第14行）

资源引用：`res://main.tscn`

## GodotProject/tests/s09_geometry.gd

S09 几何、碰撞、导航、门格和旧档迁移。

定义：`_initialize`（第7行）；`check`（第13行）；`_hits`（第17行）；`_contains_body`（第26行）；`_run`（第31行）

资源引用：`res://main.tscn`

## GodotProject/tests/s09_overview.gd

S09 结构观察机位截图。

定义：`_initialize`（第3行）；`_run`（第9行）

资源引用：`res://main.tscn`

## GodotProject/tests/s09_route.gd

S09 三入口及救援顺序实走。

定义：`check`（第12行）；`_run`（第18行）；`choose`（第139行）；`_wait_for_lu`（第147行）；`_combat`（第155行）；`_capture`（第164行）

资源引用：`res://main.tscn`；`res://tests/combat_route.gd`

## GodotProject/tests/s10_buildings.gd

D01-D05 建筑网格、碰撞、尺度和导入。

定义：`_initialize`（第6行）；`check`（第12行）；`_run`（第17行）

资源引用：`res://main.tscn`

## GodotProject/tests/s11_dressing.gd

S11 五类资源、五个槽位、占位替换和六段静态路线。

定义：`_initialize`（第7行）；`check`（第13行）；`_run`（第18行）；`_capture`（第86行）

资源引用：`res://main.tscn`

## GodotProject/tests/smoke.gd

基础启动、节点和场景烟测。

定义：`_initialize`（第7行）；`check`（第14行）；`_run`（第22行）；`_guard`（第268行）；`_test_encounter_boundaries`（第274行）；`_write_save`（第387行）；`_key`（第392行）；`_freeze_guards`（第406行）；`_frames`（第411行）；`_follow_route`（第416行）；`_walk_to`（第426行）

资源引用：`res://main.tscn`

## GodotProject/tests/story_moments.gd

人物互动、补给、包扎、跟随和等候检查。

定义：`_initialize`（第6行）；`check`（第12行）；`_run`（第18行）

资源引用：`res://main.tscn`

## GodotProject/tests/visual_motion.gd

人物动作、武器接触和视觉运动观察。

定义：`_initialize`（第22行）；`check`（第38行）；`_run`（第46行）；`_sample_bolt_cycle`（第218行）；`_finger_in_weapon`（第252行）；`_segment_distance`（第260行）；`_nearest_index_surface`（第265行）；`_aim_recovered`（第310行）；`_tap`（第313行）；`_seconds`（第325行）；`_sequence_capture`（第329行）；`_capture`（第333行）；`_finish`（第345行）

资源引用：`res://main.tscn`

## Start-Blender.cmd

启动本地 Blender 工作环境。

定义：入口脚本，无可提取的函数/类定义。

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## Start-Game.cmd

启动 Godot 游戏源码的快捷入口。

定义：入口脚本，无可提取的函数/类定义。

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## Start-Game.ps1

启动游戏或编辑器的 PowerShell 入口。

定义：入口脚本，无可提取的函数/类定义。

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## Stop-Auto-Resume.cmd

停止 Auto-Resume 面板及其派发的工作进程。

定义：入口脚本，无可提取的函数/类定义。

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## Test-CombatPerformance.ps1

正常 AI 与实际渲染交火帧时间测试入口。

定义：入口脚本，无可提取的函数/类定义。

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## Test-Game.ps1

源码或 Release 的综合功能、剧情、动作和路线回归入口。

定义：`Invoke-GameCheck`（第26行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## Test-Opening.ps1

双段开场播放、跳过、暂停、恢复和截图验证入口。

定义：入口脚本，无可提取的函数/类定义。

资源引用：`res://tests/opening.gd`；`res://tests/opening_live.gd`

## Test-Performance.ps1

暂停 AI 的固定机位性能测试；数值不能替代正常交火性能。

定义：入口脚本，无可提取的函数/类定义。

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## Test-RouteBlockout.ps1

S09 路线体块 direct/full/skip 实走验证入口。

定义：入口脚本，无可提取的函数/类定义。

资源引用：`res://tests/s09_route.gd`

## tools/asset_geometry_audit.py

资源几何、尺寸和复杂度审计。

定义：`identity`（第11行）；`multiply`（第15行）；`transform`（第19行）；`dimensions`（第35行）；`read_gltf`（第41行）；`measure_gltf`（第66行）；`bounds`（第79行）；`visit`（第116行）；`measure_obj`（第150行）；`measure_dae`（第168行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/audit_s03_interfaces.py

S03 叙事/任务接口与源码常量核对。

定义：`read_json`（第24行）；`sha`（第28行）；`write_json`（第32行）；`narration`（第36行）；`main`（第40行）；`check`（第61行）；`vector`（第64行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/auto_resume.py

新自动接续面板、停止、历史导出、回执和恢复入口。

定义：`load_config`（第16行）；`gate`（第30行）；`main`（第44行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/blender_setup_check.py

建模、资源检查、验证、日志或辅助工具文件。

定义：入口脚本，无可提取的函数/类定义。

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/build_field_character.py

由 Blender 源生成四类连续蒙皮人物游戏 GLB。

定义：`xyz`（第26行）；`godot`（第29行）；`material`（第32行）；`fabric`（第42行）；`mesh_obj`（第62行）；`rigid`（第85行）；`add`（第88行）；`loft`（第92行）；`box`（第116行）；`ellipsoid`（第130行）；`cord`（第140行）；`weights_coat`（第153行）；`weights_leg`（第167行）；`w`（第168行）；`smooth_apply`（第174行）；`join_part`（第186行）；`reweight`（第196行）；`source_parts`（第211行）；`outfit`（第296行）；`rig`（第385行）；`main`（第403行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/build_s02_inventory.py

生成 S02 资源清单、目录和去向数据。

定义：`read`（第28行）；`write`（第32行）；`relative`（第36行）；`digest`（第43行）；`fingerprint`（第54行）；`load_plans`（第59行）；`main`（第72行）；`check_file`（第96行）；`inspect`（第111行）；`game_use`（第131行）；`size_summary`（第298行）；`cost_summary`（第316行）；`render`（第328行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/build_s04_narration.py

生成旁白字幕/节奏结构。

定义：`read_json`（第12行）；`write_json`（第16行）；`stamp`（第20行）；`short`（第27行）；`main`（第31行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/build_s05_dialogue.py

生成原创任务序幕对白结构。

定义：`read`（第12行）；`write`（第16行）；`digest`（第20行）；`timecode`（第24行）；`main`（第28行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/build_s06_storyboard.py

生成双段开场分镜数据和验证。

定义：`read`（第15行）；`digest`（第19行）；`write_json`（第23行）；`tc`（第27行）；`main`（第270行）；`res`（第281行）；`inv`（第291行）；`check`（第397行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/build_s07_opening_data.py

生成 S07 开场草案数据。

定义：`read`（第11行）；`actor`（第14行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/build_s08_plan.py

生成 S08 路线与资源去向规划。

定义：`read`（第18行）；`write`（第22行）；`digest`（第26行）；`zones_for`（第81行）；`font`（第134行）；`text`（第135行）；`pt`（第136行）；`rect`（第137行）；`point_box_distance`（第218行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/build_s09_evidence.py

生成 S09 路线证据和画面索引。

定义：`digest`（第14行）；`read`（第19行）；`write`（第23行）；`sheet`（第27行）；`main`（第40行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/build_s10_buildings.py

加工 D01-D05 建筑源、GLB、碰撞和清单。

定义：`bounds`（第15行）；`load`（第19行）；`meshes`（第35行）；`transform`（第37行）；`material`（第41行）；`texture_mat`（第58行）；`cube`（第63行）；`roof`（第81行）；`collisions_box`（第100行）；`finish`（第103行）；`copy_panel`（第184行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/continuation/__init__.py

自动接续/断线恢复实现、协议和本地通信模块。

定义：入口脚本，无可提取的函数/类定义。

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/continuation/control.py

唯一自动续接控制门、暂停锁、步骤领取和重复派发保护。

定义：`read_json`（第16行）；`atomic_json`（第20行）；`file_lock`（第31行）；`Controller`（第48行）；`__init__`（第49行）；`event`（第54行）；`pulse`（第59行）；`pause`（第63行）；`live_control`（第68行）；`candidate`（第79行）；`check`（第129行）；`claim`（第135行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/continuation/history.py

自动接续/断线恢复实现、协议和本地通信模块。

定义：`stamp`（第17行）；`normalized`（第21行）；`atomic_json`（第26行）；`read_json`（第37行）；`codex_home`（第41行）；`HistoryStore`（第45行）；`__init__`（第46行）；`discover`（第51行）；`seed_settings`（第85行）；`seed_running`（第102行）；`_blob`（第118行）；`export`（第147行）；`iter_lines`（第228行）；`sha256`（第233行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/continuation/panel.py

自动接续/断线恢复实现、协议和本地通信模块。

定义：`ResumePanel`（第15行）；`__init__`（第16行）；`on_status`（第65行）；`hotkey_loop`（第68行）；`pulse`（第86行）；`start`（第92行）；`pause`（第105行）；`open_thread`（第113行）；`open_history`（第121行）；`tick`（第126行）；`close`（第160行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/continuation/protocol.py

自动接续/断线恢复实现、协议和本地通信模块。

定义：`ProtocolError`（第15行）；`Stopped`（第19行）；`ProcessJob`（第23行）；`__init__`（第25行）；`Basic`（第30行）；`Io`（第35行）；`Extended`（第38行）；`close`（第60行）；`find_codex`（第66行）；`AppServer`（第77行）；`__init__`（第78行）；`_stderr`（第112行）；`_read`（第117行）；`send`（第134行）；`call`（第144行）；`interrupt`（第171行）；`close`（第181行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/continuation/save_interruption.ps1

自动接续/断线恢复实现、协议和本地通信模块。

定义：入口脚本，无可提取的函数/类定义。

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/continuation/supervisor.py

自动接续/断线恢复实现、协议和本地通信模块。

定义：`NeedsAttention`（第19行）；`Retryable`（第23行）；`checked_state`（第27行）；`choose_work`（第42行）；`verify_step_finished`（第70行）；`file_inventory`（第91行）；`save_interruption`（第102行）；`recovery_prompt`（第132行）；`work_prompt`（第143行）；`TurnWatch`（第155行）；`__init__`（第156行）；`observe`（第164行）；`expired`（第179行）；`Supervisor`（第184行）；`__init__`（第185行）；`record`（第205行）；`report`（第210行）；`request_stop`（第215行）；`close_server`（第219行）；`open_server`（第226行）；`new_thread`（第231行）；`turn`（第245行）；`recover`（第291行）；`run`（第322行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/diagnose_model_connection.py

开发接口连接问题诊断；离线游戏不依赖。

定义：`endpoint_metadata`（第19行）；`inspect_switch`（第38行）；`NoRedirect`（第68行）；`redirect_request`（第69行）；`probe`（第74行）；`main`（第138行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/Find-Godot.ps1

建模、资源检查、验证、日志或辅助工具文件。

定义：入口脚本，无可提取的函数/类定义。

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/generate_handover_catalog.py

本次交接文档使用的逐文件目录生成器。

定义：`human_size`（第112行）；`is_catalog_file`（第122行）；`base_description`（第131行）；`archive_summary`（第209行）；`main`（第229行）；`raise_scan_error`（第240行）；`render`（第413行）

资源引用：`res://[^\s`；`res://字面量；可能由其他模块/路径变量取得。`

## tools/generate_handover_support.py

生成105条资源交接、完整对话定位与S12–S36执行分册；只写docs/handover。

定义：`read`（第14行）；`write`（第18行）；`link`（第22行）；`flat`（第26行）；`resources`（第32行）；`history`（第83行）；`next_steps`（第185行）；`main`（第219行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/inspect-character-import.gd

建模、资源检查、验证、日志或辅助工具文件。

定义：`_initialize`（第2行）；`inspect`（第8行）

资源引用：`res://assets/characters/field_character.glb`

## tools/inspect_character_source.py

建模、资源检查、验证、日志或辅助工具文件。

定义：入口脚本，无可提取的函数/类定义。

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/inspect_grip.gd

建模、资源检查、验证、日志或辅助工具文件。

定义：`_initialize`（第3行）；`_run`（第6行）

资源引用：`res://scripts/weapon_visuals.gd`

## tools/inspect_s10_sources.py

检查 S10 来源建筑尺寸、网格和部件。

定义：入口脚本，无可提取的函数/类定义。

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/refine_fp_hands.py

由 Blender 双手源生成细分、袖口和姿态改进输出。

定义：`read_glb`（第23行）；`values`（第32行）；`node_matrix`（第43行）；`create_hand`（第51行）；`append`（第116行）；`world`（第154行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/s02_blend_measure.py

建模、资源检查、验证、日志或辅助工具文件。

定义：入口脚本，无可提取的函数/类定义。

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/Save-WorkCheckpoint.ps1

调用 work_checkpoint.py 保存和校验工作检查点。

定义：入口脚本，无可提取的函数/类定义。

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/summarize_hand_release.py

建模、资源检查、验证、日志或辅助工具文件。

定义：`collect`（第38行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/survey_s08_route.gd

S08 路线调查和布景槽位采样。

定义：`_initialize`（第5行）；`xy`（第11行）；`_run`（第14行）

资源引用：`res://main.tscn`

## tools/test_auto_resume.py

新自动接续单元/隔离测试。

定义：`Workspace`（第20行）；`__init__`（第21行）；`commit`（第36行）；`GateTests`（第65行）；`setUp`（第66行）；`test_claim_is_once_only`（第71行）；`test_recovery_reuses_exact_receipt`（第77行）；`test_pending_after_network_failure_also_resumes_same_step`（第84行）；`test_changed_receipt_fails_closed`（第89行）；`test_pause_wins_over_recovery`（第95行）；`test_blocked_step_is_never_retried`（第101行）；`test_partial_checkpoint_record_blocks_dispatch`（第107行）；`test_outside_checkpoint_path_rejected`（第112行）；`test_finished_step_evidence_and_hashes_required`（第117行）；`test_success_after_disconnect_does_not_redo_step`（第125行）；`test_edited_evidence_after_checkpoint_blocks_next_step`（第130行）；`test_unrequested_later_step_change_blocks_next_step`（第137行）；`test_worker_gate_requires_matching_live_receipt`（第144行）；`test_external_model_and_release_changes_are_tracked`（第151行）；`test_duplicate_panel_lock_rejected`（第160行）；`WatchTests`（第167行）；`setUp`（第168行）；`test_no_output_timeout`（第172行）；`test_real_output_resets_idle_timer`（第176行）；`test_running_tool_has_longer_window`（第182行）；`test_finished_tool_restores_normal_timeout`（第189行）；`test_network_retry_noise_does_not_mask_stall`（第196行）；`PanelTests`（第203行）；`setUp`（第204行）；`test_panel_opens_paused_without_worker`（第219行）；`test_stop_button_interrupts_worker_and_prevents_restart_race`（第226行）；`HistoryTests`（第239行）；`setUp`（第240行）；`write`（第257行）；`test_archived_conversation_complete_and_checksum_valid`（第260行）；`test_other_project_excluded`（第270行）；`test_missing_seed_fails_instead_of_claiming_full_history`（第275行）；`test_identical_history_reuses_immutable_copy`（第279行）；`test_corrupt_existing_blob_detected`（第284行）；`test_source_model_inherited`（第291行）；`test_active_source_waits_until_completed`（第294行）；`test_pause_during_export_produces_no_complete_manifest`（第302行）；`test_windows_long_path_normalized`（第309行）；`FakeHistory`（第313行）；`__init__`（第314行）；`seed_running`（第317行）；`seed_settings`（第320行）；`export`（第323行）；`RecoveryTests`（第328行）；`simulate`（第329行）；`FakeServer`（第337行）；`__init__`（第338行）；`call`（第343行）；`interrupt`（第366行）；`close`（第369行）；`send`（第371行）；`test_single_network_failure_migrates_then_resumes_same_step`（第379行）；`test_continuing_outage_retries_same_recovery_chat`（第389行）；`test_stop_interrupts_without_migrating_or_advancing`（第396行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/test_auto_resume_live.py

新自动接续真实只读通信和停止路径测试。

定义：`main`（第12行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/test_work_checkpoint.py

检查点工具的复制、校验和记录测试。

定义：`CheckpointTests`（第19行）；`setUp`（第20行）；`tearDown`（第39行）；`put`（第43行）；`arguments`（第49行）；`save`（第56行）；`test_planning_snapshot_and_history`（第62行）；`test_project_assets_release_and_extra_sources`（第74行）；`test_done_requires_existing_evidence`（第82行）；`test_copy_failure_keeps_previous_checkpoint`（第89行）；`test_tampered_file_is_detected`（第99行）；`test_interrupted_publication_and_record_recovery`（第105行）；`fail_progress`（第108行）；`test_outside_workspace_cannot_be_copied`（第125行）；`test_existing_lock_is_preserved`（第129行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/verify_handover.py

只读核对路径、资源、历史对象哈希、S11快照与固定原文；只写交接验收报告，不运行游戏。

定义：`read`（第14行）；`digest`（第18行）；`main`（第26行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

## tools/work_checkpoint.py

检查点复制、SHA-256、状态记录、LATEST 和历史追加工具。

定义：`digest`（第33行）；`json_text`（第41行）；`atomic_write`（第45行）；`inside_root`（第56行）；`select_files`（第65行）；`verify`（第86行）；`render_progress`（第101行）；`save`（第143行）；`recover_records`（第261行）；`main`（第281行）

资源引用：未直接出现res://字面量；可能由其他模块/路径变量取得。

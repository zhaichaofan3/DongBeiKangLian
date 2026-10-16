# S12–S36 后续执行清单

以下25步在本交接基准均未开始；这是执行设计，不是新增完成状态。目标/判断/完成标准来自 production_plan.md，实际状态继续只读 production_state.json。

每步统一流程：①核对前置成果和用户当前范围；②用本步in_progress保存开工检查点；③实施最小可验收部分并留中间检查点；④运行匹配的检查和画面/声音/人工审阅；⑤更新实际资源去向与限制；⑥证据已存在后才done并保存，最后明确下一步。失败仍in_progress或blocked，不跨步。

S12首先读取S08路线安排、S11实际布景和S01性能基线。当前任务只交接，不能因阅读本清单自动执行S12。S14/S20是调查设计；S28/S29先下载试听。其余多数改游戏，按project备份；纯文档用planning，工程外源和素材始终显式ExtraPaths，S36加IncludeRelease。

## S12 · 树林山体与远景

- 开始前读：[docs/level/S08/route_plan.json](../../docs/level/S08/route_plan.json)；[docs/level/S11/dressing-validation.md](../../docs/level/S11/dressing-validation.md)；[GodotProject/scripts/world.gd](../../GodotProject/scripts/world.gd)；[GodotProject/scripts/asset_dressing.gd](../../GodotProject/scripts/asset_dressing.gd)。
- 前置：S11现场与S08路线；S01性能基线。
- 总计划工作：完善山体、树林、地面与远景轮廓，统一材质、光照和年代细节。
- 依赖／判断：近景细、远景简；与镜头方向和关卡视线配合。
- 具体执行：先固定检查口、木料巷、电报房、渡口及开场朝向机位；对比S11现场，近中远分层安排树木、山体、地表。先挑资源再分批接入，避免树林遮挡路牌和敌人入口。
- 完成标准：固定机位对照与主要路线观感记录，无明显悬空、比例混乱。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S12 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S13，先读取本步验收与限制。

## S13 · 碰撞通行与 AI 路线

- 开始前读：[docs/S09-route-blockout.md](../../docs/S09-route-blockout.md)；[docs/level/S11/resource-destinations.md](../../docs/level/S11/resource-destinations.md)；[GodotProject/scripts/route_blockout.gd](../../GodotProject/scripts/route_blockout.gd)；[GodotProject/scripts/linear_director.gd](../../GodotProject/scripts/linear_director.gd)。
- 前置：S12的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：检查人物通行、碰撞、敌人路线、掩体、救援与撤离位置。
- 依赖／判断：建筑布置后再次检查；AI 与玩家路径都覆盖。
- 具体执行：重点核对S11隐藏体块仍有碰撞的边缘、小道具没有独立碰撞、陆山慢速西门回绕及北侧护送。跑direct/full/skip与不同救援顺序，检查门、射线、掩体、追兵和伤员。
- 完成标准：通行与任务检查记录，穿墙／堵路／卡住问题清单归零或明确登记。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S13 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S14，先读取本步验收与限制。

## S14 · 逐角色骨骼与动作清单

- 开始前读：[GodotProject/scripts/field_character_rig.gd](../../GodotProject/scripts/field_character_rig.gd)；[GodotProject/scripts/human_model.gd](../../GodotProject/scripts/human_model.gd)；[AssetLibrary/characters/manifest.json](../../AssetLibrary/characters/manifest.json)；[docs/v06_production.md](../../docs/v06_production.md)。
- 前置：S13的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：逐角色核对骨骼、蒙皮、现有动作、下载动作的适配成本。
- 依赖／判断：当前 NPC 13 骨、程序动画；通用动作不能直接假定兼容。
- 具体执行：逐类列侦察员、林工、陆山、守卫的骨骼/蒙皮/动作和现状。对比13骨程序人物与65关节通用动作，先做样本决定重定向或继续程序方案，不能直接批量套用。
- 完成标准：每类角色动画清单、重定向或保留程序动作的决定与样本验证。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S14 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：planning（本步如改游戏则project），所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S15，先读取本步验收与限制。

## S15 · 待机转身起步停止

- 开始前读：[GodotProject/scripts/human_model.gd](../../GodotProject/scripts/human_model.gd)；[GodotProject/scripts/field_character_rig.gd](../../GodotProject/scripts/field_character_rig.gd)；[GodotProject/scripts/friendly.gd](../../GodotProject/scripts/friendly.gd)；[GodotProject/scripts/guard.gd](../../GodotProject/scripts/guard.gd)。
- 前置：S14的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：完善站立、呼吸、转身、起步、停止和状态过渡。
- 依赖／判断：先消除瞬间转向、漂移和突然切姿态。
- 具体执行：依S14决定校准骨盆重心、脚底、转向速度、呼吸、开始/停止时的姿势过渡；四类人物都留近景连续演示。
- 完成标准：角色近景连续演示；动作过渡与接地问题记录。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S15 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S16，先读取本步验收与限制。

## S16 · 行走跑步与转换

- 开始前读：[GodotProject/scripts/human_model.gd](../../GodotProject/scripts/human_model.gd)；[GodotProject/scripts/friendly.gd](../../GodotProject/scripts/friendly.gd)；[GodotProject/scripts/guard.gd](../../GodotProject/scripts/guard.gd)。
- 前置：S15的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：完善走路、跑步、加减速、变向和脚步时序。
- 依赖／判断：步幅、动作速度与实际位移共同校准。
- 具体执行：动作节拍匹配真实位移和加减速；测试平地、坡道、变向、追赶、等候后继续跟随，陆山伤情速度必须保留。
- 完成标准：每角色走跑与转换演示，平地／坡道观察，滑步明显减少。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S16 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S17，先读取本步验收与限制。

## S17 · 持枪移动与武器动作

- 开始前读：[GodotProject/scripts/fp_hands.gd](../../GodotProject/scripts/fp_hands.gd)；[GodotProject/scripts/weapon_visuals.gd](../../GodotProject/scripts/weapon_visuals.gd)；[GodotProject/scripts/fps_player.gd](../../GodotProject/scripts/fps_player.gd)；[docs/v061_hands.md](../../docs/v061_hands.md)。
- 前置：S16的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：完善持枪移动、瞄准、开火、装填和受扰后的恢复。
- 依赖／判断：保留手部成果，检查手—枪接触及上下半身协调。
- 具体执行：保留0.6.1双手细分、袖口和向上抬栓修正；步枪/驳壳枪分别验双手抓握、枪机、装填、回握和第三人称枪托/肘部接触，正常速度与慢放都观察。
- 完成标准：第一／第三人称动作演示，武器状态与动作检查通过。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S17 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S18，先读取本步验收与限制。

## S18 · 受击倒地与恢复

- 开始前读：[GodotProject/scripts/human_model.gd](../../GodotProject/scripts/human_model.gd)；[GodotProject/scripts/field_character_rig.gd](../../GodotProject/scripts/field_character_rig.gd)；[GodotProject/scripts/guard.gd](../../GodotProject/scripts/guard.gd)；[GodotProject/scripts/friendly.gd](../../GodotProject/scripts/friendly.gd)。
- 前置：S17的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：完善受击、踉跄、倒地、倒地停留；需要时制作起身。
- 依赖／判断：动作与伤亡状态一致，地形接触和释放持枪约束正确。
- 具体执行：不同方向受击与坡面/障碍边倒地，解绑持枪约束与死亡状态一致；倒地不继续走跑，起身只按实际任务需要制作。
- 完成标准：不同方向、坡面与障碍附近的倒地演示；无明显浮空或倒地后继续走跑。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S18 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S19，先读取本步验收与限制。

## S19 · 角色行为差异

- 开始前读：[GodotProject/scripts/friendly.gd](../../GodotProject/scripts/friendly.gd)；[GodotProject/scripts/guard.gd](../../GodotProject/scripts/guard.gd)；[docs/S03-narrative-and-mission.md](../../docs/S03-narrative-and-mission.md)。
- 前置：S18的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：调整侦察员、伐木工、陆山、守卫的速度、姿态和动作差异。
- 依赖／判断：角色差异服务身份与伤情，避免仅随机播放。
- 具体执行：分别设置侦察员警戒、林工生活感、陆山受伤步态、守卫持枪和警觉；包扎前后、等候/跟随、战斗切换连贯，避免只随机动画。
- 完成标准：逐角色验收表，伤员和敌人行为符合任务状态。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S19 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S20，先读取本步验收与限制。

## S20 · 艺术化天池构图

- 开始前读：[docs/narrative/S06/storyboard.json](../../docs/narrative/S06/storyboard.json)；[AssetLibrary/environment/china_northeast_20261013/terrain/source.json](../../AssetLibrary/environment/china_northeast_20261013/terrain/source.json)；[docs/S05-task-prologue-dialogue.md](../../docs/S05-task-prologue-dialogue.md)。
- 前置：S19的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：制作艺术化天池构图草案，确定火山口、湖面、山脊、岩台和人物视线。
- 依赖／判断：真实高程仅作参考；用户明确不要求 1:1。
- 具体执行：先画火山口湖大远景、双人站位与离开方向，镜头需求决定艺术比例；DEM作参考，不要求原高程尺寸，给S21选定布局。
- 完成标准：至少包含大远景与双人站位构图，选定可执行布局。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S20 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：planning（本步如改游戏则project），所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S21，先读取本步验收与限制。

## S21 · 天池山体与湖面模型

- 开始前读：[AssetLibrary/environment/china_northeast_20261013/terrain/tianchi_display.blend](../../AssetLibrary/environment/china_northeast_20261013/terrain/tianchi_display.blend)；[docs/S06-opening-storyboard.md](../../docs/S06-opening-storyboard.md)。
- 前置：S20的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：新建或重塑天池山体与湖面，强化环形山壁和深蓝湖面。
- 依赖／判断：服务观众对火山口湖的想象；与已有高程样板分目录保存。
- 具体执行：根据S20另建艺术化源目录，制作环形山壁/深蓝湖面/远山，分远近精度与LOD；保留原DEM与原包，输出.blend、游戏模型和尺寸记录。
- 完成标准：可编辑 Blender 工程、游戏用模型、远近景预览与尺度说明。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S21 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S22，先读取本步验收与限制。

## S22 · 谈话岩台与路径

- 开始前读：[docs/S05-task-prologue-dialogue.md](../../docs/S05-task-prologue-dialogue.md)；[GodotProject/scripts/opening_director.gd](../../GodotProject/scripts/opening_director.gd)；[docs/narrative/S06/storyboard.json](../../docs/narrative/S06/storyboard.json)。
- 前置：S21的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：制作站立岩台、到达／离开路线、近景岩石植被及碰撞。
- 依赖／判断：谈话站位、镜头和人物移动共同决定地形。
- 具体执行：根据对白站位布置避风岩台、近景石、植被和到达离开路径，做真实站立/行走和相机穿插检查，碰撞与可见地面一致。
- 完成标准：人物站立与行进可用，镜头内地面接触自然，没有穿插与路径卡点。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S22 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S23，先读取本步验收与限制。

## S23 · 天池水雾光照与层次

- 开始前读：[GodotProject/scripts/opening_director.gd](../../GodotProject/scripts/opening_director.gd)；[GodotProject/scripts/world.gd](../../GodotProject/scripts/world.gd)；[docs/narrative/S07/issues.md](../../docs/narrative/S07/issues.md)。
- 前置：S22的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：完成天池水面、雾、光照、远山和环境层次。
- 依赖／判断：突出纵深与辨识度；避免效果遮蔽人物。
- 具体执行：统一独立天池照明、水、雾、山层次，保持人脸与手部可读；检查湖面闪烁、边界、远近景和接管环境连续性。
- 完成标准：不同镜头下人物清楚、湖面稳定，效果开销有记录。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S23 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S24，先读取本步验收与限制。

## S24 · 人物交谈表演

- 开始前读：[docs/narrative/S05/dialogue_script.json](../../docs/narrative/S05/dialogue_script.json)；[GodotProject/scripts/field_character_rig.gd](../../GodotProject/scripts/field_character_rig.gd)；[GodotProject/scripts/opening_director.gd](../../GodotProject/scripts/opening_director.gd)。
- 前置：S23的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：制作双人／小队交谈表演：注视、转头、手势、听话反应、重心变化。
- 依赖／判断：对照 S05 对白节拍；有可用配音后再同步嘴部或简化口型。
- 具体执行：按14句对白制作说话/听话双向反应、注视、重心与手势，脚不漂；有配音再对齐口型，动作不能机械同拍。
- 完成标准：连续对话演示；人物互相回应，脚部稳定、动作不机械同步。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S24 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S25，先读取本步验收与限制。

## S25 · 谈话镜头与玩家接管

- 开始前读：[docs/narrative/S03/interface_contract.json](../../docs/narrative/S03/interface_contract.json)；[GodotProject/scripts/opening_director.gd](../../GodotProject/scripts/opening_director.gd)；[GodotProject/scripts/fps_player.gd](../../GodotProject/scripts/fps_player.gd)。
- 前置：S24的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：完成谈话镜头、队伍起步、下山过渡和玩家视角接管。
- 依赖／判断：确保位置、武器、任务状态和操作权连续。
- 具体执行：对齐S05到S24的起步、下山、数日转场与林场简报；正常结束和跳过统一位置/FOV/手部/武器/任务和控制权，修RC09切换感。
- 完成标准：从对话完整进入可玩关卡；镜头无突跳、控制无遗留锁定。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S25 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S26，先读取本步验收与限制。

## S26 · 枪口火焰与烟气

- 开始前读：[GodotProject/scripts/weapon_visuals.gd](../../GodotProject/scripts/weapon_visuals.gd)；[GodotProject/scripts/fps_player.gd](../../GodotProject/scripts/fps_player.gd)；[GodotProject/scripts/guard.gd](../../GodotProject/scripts/guard.gd)。
- 前置：S25的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：增强枪口火焰、烟气、短时照明和开火视觉反馈。
- 依赖／判断：第一人称与远处开火均可读，效果与枪口位置同步。
- 具体执行：第一人称和远处开火都从实际枪口触发，短火光/烟气有寿命，连射不持续挡目标；明暗两条件记录画面和开销。
- 完成标准：日暗两种条件和连续开火演示；不持续遮挡目标，性能变化有记录。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S26 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S27，先读取本步验收与限制。

## S27 · 炮弹爆炸与战争氛围

- 开始前读：[GodotProject/scripts/opening_director.gd](../../GodotProject/scripts/opening_director.gd)；[GodotProject/scripts/weapon_visuals.gd](../../GodotProject/scripts/weapon_visuals.gd)；[docs/narrative/S06/storyboard.json](../../docs/narrative/S06/storyboard.json)。
- 前置：S26的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：制作炮弹落点、爆炸、土石、烟尘、远景火线和人物反应。
- 依赖／判断：区分过场演出与有伤害的游戏效果，控制活跃数量。
- 具体执行：炮弹、落点、土石、烟柱和人物反应分层；演出爆炸和实际伤害分开，控制活跃数量，检查伤害半径、音画时序和回收。
- 完成标准：宏大叙事战争镜头可用；伤害范围、音画时序和效果回收正确。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S27 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S28，先读取本步验收与限制。

## S28 · 网上音效搜集与试听

- 开始前读：[AssetLibrary/audio/manifest.json](../../AssetLibrary/audio/manifest.json)；[AssetLibrary/audio/ready_to_import.json](../../AssetLibrary/audio/ready_to_import.json)；[GodotProject/ASSET_SOURCES.md](../../GodotProject/ASSET_SOURCES.md)。
- 前置：S27的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：上网搜集并试听枪声、回声、林风、脚步、爆炸、动作声音。
- 依赖／判断：使用现有库补缺；保存原文件、来源、选择理由和加工记录。
- 具体执行：先试听既有510原音频/52派生是否补缺，再网上取得枪械机械、脚步、林风、爆炸等；逐项记录实际文件、来源、格式、试听结论与用途，失败单列。
- 完成标准：实际下载可解码的音效清单；失败链接单列，试听有结论。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S28 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：planning（本步如改游戏则project），所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S29，先读取本步验收与限制。

## S29 · 网上 BGM 搜集与试听

- 开始前读：[docs/S04-narration-and-subtitles.md](../../docs/S04-narration-and-subtitles.md)；[docs/S05-task-prologue-dialogue.md](../../docs/S05-task-prologue-dialogue.md)；[docs/narrative/S06/storyboard.json](../../docs/narrative/S06/storyboard.json)。
- 前置：S28的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：上网搜集并试听适合行军、探索、战斗、谈话与结尾的 BGM。
- 依赖／判断：尊重非商业筛选偏好；不直接抽取商业游戏音乐作成品。
- 具体执行：按行军/探索/战斗/谈话/结尾找音乐，下载后试听并记录循环、剪辑点和来源；个人非商业不等于缺省署名，不把商业游戏现成音乐抽取当成新原创成品。
- 完成标准：曲目候选与实际下载状态、来源、用途和可循环／剪辑位置记录。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S29 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：planning（本步如改游戏则project），所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S30，先读取本步验收与限制。

## S30 · 音画同步与分层混音

- 开始前读：[GodotProject/scripts/audio_factory.gd](../../GodotProject/scripts/audio_factory.gd)；[GodotProject/scripts/presentation.gd](../../GodotProject/scripts/presentation.gd)；[GodotProject/scripts/opening_director.gd](../../GodotProject/scripts/opening_director.gd)。
- 前置：S29的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：接入声音与音乐；同步脚步和枪声，调距离衰减、混响、淡入淡出与对白避让。
- 依赖／判断：音效与动作共同验收，旁白／对白可懂优先。
- 具体执行：将S28/S29选择接入事件和空间，脚步/枪口/弹壳与动作一致；对白避让、远近枪与室内外反射、切场淡入淡出，暂停/重试无叠播。
- 完成标准：各场景听感记录，切场景／重试时无重复叠播或突兀断音。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S30 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S31，先读取本步验收与限制。

## S31 · 旁白对白与字幕同步

- 开始前读：[docs/narrative/S04/narration_timeline.json](../../docs/narrative/S04/narration_timeline.json)；[docs/narrative/S05/dialogue_script.json](../../docs/narrative/S05/dialogue_script.json)；[docs/S04-narration-and-subtitles.md](../../docs/S04-narration-and-subtitles.md)。
- 前置：S30的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：确定配音方式，制作第一段旁白和第二段对白字幕，完成音画节拍。
- 依赖／判断：原文逐字核对，临时配音明确标记；字幕可读。
- 具体执行：确定可执行配音方式，临时声音明确标注。固定旁白逐字核对，按实际录音校准15字幕和14对白的停顿、动作、镜头和音乐，不强套80秒。
- 完成标准：完整旁白与对白对应表，字幕、停顿、音乐和表演同步。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S31 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S32，先读取本步验收与限制。

## S32 · 正式历史序章

- 开始前读：[docs/narrative/S06/storyboard.json](../../docs/narrative/S06/storyboard.json)；[docs/narrative/S07/issues.md](../../docs/narrative/S07/issues.md)；[GodotProject/scripts/opening_director.gd](../../GodotProject/scripts/opening_director.gd)。
- 前置：S31的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：用完成的场景、人物、战斗效果与声音制作 A1–A6 正式历史序章。
- 依赖／判断：替换 S07 占位内容；规模、情绪与文字一致。
- 具体执行：逐镜替换A1–A6场景/人物/战争/天池/声音占位，复核RC06构图；宏大层次服务固定旁白，记录每镜资源来源及正式连续播放。
- 完成标准：完整序章演示，地图／模型／交战／炮弹／天池均有叙事用途。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S32 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S33，先读取本步验收与限制。

## S33 · 正式任务序幕

- 开始前读：[docs/S05-task-prologue-dialogue.md](../../docs/S05-task-prologue-dialogue.md)；[docs/narrative/S03/interface_contract.json](../../docs/narrative/S03/interface_contract.json)；[GodotProject/scripts/opening_director.gd](../../GodotProject/scripts/opening_director.gd)。
- 前置：S32的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：制作 B1–B6 正式任务序幕，连接历史序章与第一场实际战斗。
- 依赖／判断：战友情感落到具体任务，参考节奏但保持原创。
- 具体执行：完成B1–B6正式双人表演、任务信息、危机与玩家接管，天池不能提前知道昨夜被扣；看两段连播到首次实际战斗，目标清楚且手部光照连贯。
- 完成标准：完整任务序幕演示，目标清楚、玩家接管自然，两段衔接完整。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S33 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S34，先读取本步验收与限制。

## S34 · 跳过暂停重试与存读档

- 开始前读：[GodotProject/scripts/mission.gd](../../GodotProject/scripts/mission.gd)；[GodotProject/scripts/opening_director.gd](../../GodotProject/scripts/opening_director.gd)；[GodotProject/tests/opening.gd](../../GodotProject/tests/opening.gd)；[docs/narrative/S03/interface_contract.json](../../docs/narrative/S03/interface_contract.json)。
- 前置：S33的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：完善分别跳过、暂停、重试、存读档及中途退出恢复。
- 依赖／判断：过场结束、跳过和读档应进入正确状态；保留旧档兼容。
- 具体执行：列正常播放/分别跳过/暂停/退出/死亡/读旧档/中断写盘的状态矩阵，测无重复敌人、目标丢失、音乐叠播和镜头控制锁；失败证据保留。
- 完成标准：状态矩阵检查：无重复敌人、目标遗漏、错误音乐或镜头锁死。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S34 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S35，先读取本步验收与限制。

## S35 · 实际场景性能优化

- 开始前读：[docs/S01-baseline.md](../../docs/S01-baseline.md)；[Test-CombatPerformance.ps1](../../Test-CombatPerformance.ps1)；[Test-Performance.ps1](../../Test-Performance.ps1)；[GodotProject/scripts/presentation.gd](../../GodotProject/scripts/presentation.gd)。
- 前置：S34的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：按实际交火、谈话和过场测量性能，优化 LOD、可见性、动画、粒子、音频与加载。
- 依赖／判断：对比 S01 基线与实际机器表现，不用固定机位代替交火数据。
- 具体执行：同条件采集实际双方交火、谈话和正式过场，记录渲染尺寸、画质、射击次数、P99与加载；依据瓶颈调整LOD、可见性、动画/粒子/音频，说明画质取舍。
- 完成标准：可复查的性能报告、瓶颈与改动记录；画面质量取舍有说明。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S35 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入。
- 下一步：S36，先读取本步验收与限制。

## S36 · 完整试玩打包与归档

- 开始前读：[Build-Game.ps1](../../Build-Game.ps1)；[Test-Game.ps1](../../Test-Game.ps1)；[GodotProject/ASSET_SOURCES.md](../../GodotProject/ASSET_SOURCES.md)；[Release/release_validation.json](../../Release/release_validation.json)。
- 前置：S35的实际输出和本步引用的更早成果。未满足依赖先记录，不能把占位当完成。
- 总计划工作：完整试玩与回归，修复问题，打包交付并归档来源、源工程、验证和备份。
- 依赖／判断：源码与发布包分别验证；程序检查不能替代真人观感。
- 具体执行：完整真人体验与回归、已知问题结论、版本统一，先保护旧Release再打新包；源码与源码目录外发布包分别验证，归档模型源、来源、证据、历史和最终完整检查点。
- 完成标准：可运行发布包、通关证据、已知限制、素材署名、最终完整检查点。
- 应留交付：本步说明、实际改动清单、资源来源/去向、必要运行日志与连续演示/截图、已知问题；建议新建 docs 下的 S36 证据目录。这些未来文件目前尚不存在，不能提前登记done。
- 保存范围：project，所有本步工程外源、工具、素材、试听与验证结果通过ExtraPaths纳入，发布文件通过IncludeRelease纳入。
- 下一步：交付已验证版本、已知限制及最终完整备份；后续新增目标另行记录，不自动循环回S01。

## 跨步骤不可漏项

- 原始旁白不改字；新配音时长可变，字幕/分镜/动作都跟随实录。
- 逐角色与两种武器分别验收；天池角色、陆山救援、旧档与玩家接管保持连续。
- 场景/布景/树木变动都需关注护送回绕和增援视线，静态导航不代替动态AI。
- 原模型、派生.blend、游戏GLB、来源和加工工具形成可回退链；候选、备用和未采用资源也保留去向。
- 正常播放、跳过与旧档都要回归；音频要试听、表演要连续观看，测试数字不能替代。
- 最后交付包与当前源码分别验证；新机器、新画质与新增烟尘场景需要新性能数据。

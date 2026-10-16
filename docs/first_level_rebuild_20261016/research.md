# 第一关整图重构：研究与实施记录

用户要求：保留第一关剧情，使用现有模型，整体重构地图，拉开区域间距并强化线性体验。保留实墙遮挡，约0.8米低铁丝网仅封无任务支路；保留手部、用户录音和第二关原村落成果。

本文件记录本轮实际阅读的公开资料、设计决定和验证。未完成的实现与验收不会记为完成。

## 实际阅读的网络资料（2026-10-16）

- [The Level Design Book: Critical Path](https://book.leveldesignbook.com/process/layout/criticalpath)：标记起点、终点和叙事节拍；主路以外内容控制规模。也提醒过度依赖任务清单会显得生硬。
- [Flow](https://book.leveldesignbook.com/process/layout/flow)：路线速度、方向与连接关系一起设计，必须通过实际移动检验。
- [Encounter](https://book.leveldesignbook.com/process/combat/encounter)：战斗有开始、发展、结束；先提供观察和立足点，避免玩家只能卡门射击。
- [Wayfinding](https://book.leveldesignbook.com/process/blockout/wayfinding)：道路、边界、地标与灯光共同提供信息；《使命召唤》的目标提示属于可用的直接引导方法。
- [Combat](https://book.leveldesignbook.com/process/combat)：射击距离与既有武器、移动速度共同决定场地；交替安排危险和恢复。

上述页面均已保存官方Markdown全文及前两页HTML，供离线复查。另尝试的WoLD旧地址返回404，未作为依据。资料是通用关卡方法，不宣称为《使命召唤》官方制作规范。

## 本轮执行布局

首关纵深从96米调整为304米，所有建筑保持原有米制尺度。路线为接头林道→检查口→转弯运输路→木料场→装卸林道→电报房→北路护送→渡口。两处前段栅门从间隔16米增加到76米；两段转场用折返道路遮挡后续敌人。

检查口为较开阔的正面射击，木料场提供箱堆与原木间的短距离推进，电报房继续保留原室内任务和刺刀战，渡口保留30秒掩护。主路有连续车辙，转弯有灯和木牌，支路才用低网。

实施入口：first_level_layout.gd集中管理锚点和旧档迁移；first_level_world.gd生成新地图，旧紧凑地图不再实例化。第二关原村落继续保留。

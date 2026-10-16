# 发布包启动异常记录

2026-10-16 11:35:20，第一次独立发布回归在combat_route启动时退出，返回-1073741819（0xc0000005）。此前基础任务108项、线性路线38项通过。combat-route.log只包含引擎标题，没有GDScript错误或战斗完成标记，本次失败不计作通过。

系统Application事件1000：故障程序与模块均为C:\GameMake\Release\FenghuoEcho.exe，版本4.7.2.0，模块时间戳0x6a826550，故障偏移0x00000000031d6c57，故障进程0x4968，Report Id为74a09a4e-bf9b-4bab-ac74-ec48a3cff6db。

初次失败日志保留于accepted-release-regression/combat-route.log。检查发现同命令的残留进程37784（父进程18792）已无线程、CPU为0，清理该具体残留进程后，开始release-combat-diagnostic单独复测。所有游戏验收均串行执行，使用独立QA存档。

单独复测release-combat-diagnostic已通过：37敌、生命100、任务时间318.75秒、state=won；渡口发出12名追兵，最后一批击倒2名，首次接敌时掩护剩28.83秒。随后另用accepted-release-regression-v2目录启动串行完整回归，保留初次失败目录。

## 再次发生与定位

11:41:51，accepted-release-regression-v2在线性路线撤离检查中再次访问异常；前26项通过，未到完成标记。系统事件故障偏移仍为0x31d6c57，Report Id为0d9ab519-a323-4e7f-aa52-1e227bb0a5bb。两份系统小型转储已保留到crash-data/，可离线继续分析。

读取转储异常上下文：故障线程38984，访问地址0x40，R8=0；指令为cmp dword ptr [r8+0x40], eax。结合程序.pdata函数边界和内嵌错误字符串，故障函数定位为AudioServer::_mix_step，调用链包含_driver_process。引擎在两次bus_map查询之间读取可变send，现有游戏apply_category_volumes每帧重复调用set_bus_send；该引擎setter未自行锁定音频线程。上游源码参考已离线保留于crash-data/upstream-audio-server.cpp，来源https://raw.githubusercontent.com/godotengine/godot/master/servers/audio/audio_server.cpp。该参考不等于当前程序带调试符号的源码映射。

## 修正与验证

audio_mix.gd增加_set_send：目标相同则跳过写入；实际更换路由时使用AudioServer.lock()/unlock()保护。初始化、每帧分类音量和退出时统一使用此入口，音频内容文件没有改动。

源码音频专项27项通过，包含混音播放持续前进时的512次交替路由切换。地图补景、两段旁白与录音仍保留。修正后重新构建，源码accepted-source-regression-v5与独立发布accepted-release-regression-v3各28组全部通过；两端音频专项均27项、512次实时路由切换。最终发布地图18机位、边界148项、有画面37敌通关与固定机位性能测量均正常结束，无新增原生崩溃或脚本错误。

本修正针对已定位的共享路由写入风险，不能据此保证所有其他硬件不再发生原生异常。系统转储、失败目录和修正后的验证分别保留，历史故障不从记录中删除。

# Windows安装程序

`FenghuoEcho.iss`为本项目安装定义，使用Inno Setup 6.7.3验证。默认按当前用户安装，固定AppId支持后续覆盖升级，提供游戏、说明、卸载入口及可选桌面快捷方式。安装与卸载均不写入或删除玩家存档目录。

从官方 [Inno Setup](https://jrsoftware.org/isdl.php) 安装编译器，以`ISCC_EXE`或根`Package-Game.ps1 -IsccPath`指定。编译器与下载文件放忽略目录，不入Git。运行游戏无需这些工具。

`ChineseSimplified.isl`原样取自官方源仓库的 [is-6_7_3 / Files/Languages/Unofficial](https://github.com/jrsoftware/issrc/blob/is-6_7_3/Files/Languages/Unofficial/ChineseSimplified.isl)，Git blob `d6a11c4490de07dad443ade668289fc954dfa1ed`；原文件保留Zhenghan Yang等维护者说明。Inno Setup版权与许可见同目录`INNO_LICENSE.txt`。

安装包不包含编译器。当前包无代码签名，文档明确告知玩家核对官方来源和SHA-256。

`distribution_motion.gd`用于安装版的固定步长功能检查，继承原`visual_motion.gd`，保留其模拟按键、游戏逻辑及全部断言。仅在QA模式过滤系统鼠标事件并限制每帧一个物理步，避免窗口捕获鼠标和物理追赶影响动作采样；不修改发行PCK，不用于评估真实帧率或低帧率表现。

0.7.3统一显示名称“东北抗联 烽火回声”。正常安装保留原AppId、安装目录与存档位置；验证脚本传入`/DeliveryVerification=isolated`和显式`/DIR`，同一安装EXE使用另一个QA AppId与快捷方式目录，保护正在使用的正式安装。此参数不出现在玩家向导中，缺少显式目录时拒绝验证安装。

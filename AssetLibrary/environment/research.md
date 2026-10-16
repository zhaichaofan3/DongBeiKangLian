# 东北抗联 FPS：环境资源搜集

检索日期：2026-10-12（Asia/Shanghai）。资源来源：Poly Haven 官方公开资源目录与文件 API、OpenGameArt 作者投稿页面。

最终取得 **45 项资源组、202 个下载文件、545,587,341 字节（约 520.3 MiB）**。下载哈希、图像可解码性、glTF 外部依赖、ZIP CRC 与补充包内容检查均通过；尚未在当前游戏中实机验收。

这批资源面向现有关卡的松林、林场、木栈桥、仓库、电报房和撤离路线。优先真实扫描/PBR、完整 glTF、2K 贴图和可核实的作者许可。下载清单覆盖环境样板的主要材料，不代表“互联网上所有可用资源”。

## 已选择的内容

- 林地：倒木、树桩、松根、蕨类、松苗、两类岩石，其中苔岩模型包含多个石块。
- 林场与仓库：普通木箱、两类军需箱、木桶、木水桶、梯子、斧、木工锯、模块木栈桥。
- 电报房：油灯、木桌、木凳、旧木书架、铁桶炉、二战风格野战电台。
- 2K PBR：泥土落叶、森林地面、泥车辙、两类树皮、圆木墙、风化木板、粗木墙、木屑、灰瓦、砖墙、锈铁、碎石路、雪。
- 2K HDRI：阴天纯天空、秋季森林。
- 补充树木：Dim's Arboretum（65 个网格，含成熟冷杉、山毛榉、植被和圆木堆）、JKM 的松树/阔叶树及多季节贴图、AnyRPG 白桦（页面标注 1776 三角）。
- 补充建筑：Daniel Andersson 水力锯木棚、Elegant Crow 带室内及独立门窗的圆木屋、mixxit 带室内的 DAE 圆木屋、Yughues/Nobiax 的 34 个工业建筑模块（各有 FBX/OBJ）。

## 使用条件与证据

前 38 项来自 Poly Haven，官方资产许可为 CC0-1.0。其余 7 组来自 OpenGameArt，分别为 CC0、CC-BY-3.0、CC-BY-SA-3.0 或 CC-BY-SA-4.0，作者和精确许可见 `manifest.json`。需要署名的资源应保留作者、来源、许可及修改说明；ShareAlike 要求应用于所修改的对应资产。没有把“仅个人使用”当成通用授权。

- 官方许可页面：<https://polyhaven.com/license>，本地证据 `evidence/polyhaven_license.html` 和 `evidence/polyhaven_license.txt`。
- CC0 正文：<https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt>，本地 `evidence/CC0-1.0.txt`。
- API 条款：`evidence/polyhaven_api_terms.md`；本次调用使用 `GameMakeAssetResearch/1.0` User-Agent。
- 每项资源保存作者元数据和官方文件清单。每个资源文件记录精确下载 URL、实际字节数、SHA256，并对照官方 MD5。

## 导入前仍需处理

1. glTF 与其 `.bin` 和 `textures/` 必须保留相对位置一起复制。这里仅搜集与校验文件，没有修改游戏，也没有实际证明在当前关卡内的视觉效果或运行帧率。
2. 近景模型的面数适合单件道具，但整片森林不能无条件密集摆放。倒木、松根和松苗等高面源需要 LOD、碰撞简化和实例化策略。
3. 已补进成熟树的低面源，但它们主要适合中远景和备用 LOD。JKM 松树实测 113 三角，Dim 的冷杉源网格 96 面；其透明枝叶卡和旧贴图不代表《战地 1》的近景树冠品质。白桦叶形也略风格化。接近新参考视频的近景成熟森林，仍需挑选/加工更好的树冠与树干，补自然风摆、遮挡和远景 impostor。官方 `pine_tree_01` 目录面数约 1743 万、`fir_tree_01` 约 785 万，不能直接密铺。
4. 野战电台是二战风格资产，军需箱可能有现成标记。要核对年代、型号及军队标识，必要时重绘标签。下载不等于历史考据通过。
5. 贴图选择 OpenGL 法线。Albedo 使用 sRGB；法线、粗糙度、AO 和高度按数据纹理处理。材质物理尺寸、UV/三平面映射、湿度和脏污混合仍需在场景中制作。
6. 叶片材质应保留 glTF 的 MASK/alpha cutout 设置。风摆、交互、音效和碰撞不是这些静态模型自带的能力。
7. HDRI 用于天空/环境照明；森林全景不是可行走场景几何。
8. JKM 的原始 OBJ 引用了未随包提供的 `.mtl`，需要补材质映射；树叶 TGA 与树皮 JPG 已在包内。不能把“源文件已经下载”理解为材质已修复。
9. Dim、白桦和锯木棚是 `.blend` 源，需用 Blender 转 glTF。已用只读 DNA 数据解析确认锯木棚有 `Sawing` 动作、18 个网格；这不等于已经验证动画播放或当前引擎兼容。源模型中的时代、地域风格还需改造。
10. Nobiax 模块每件约 12–154 三角，包有 4K 漫反射/法线/高光 TGA。OBJ 未绑定材质；可用 FBX 或补材质后接入。当前 PBR 流程中需要把旧高光材质转换或换为此次采集的 PBR。

## 文件说明

`manifest.json` 是最终资源登记表；`verification.json` 是下载文件复核报告。`supplement_verification.json`、`supplement_geometry.json`、`blend_metadata.json` 分别记录补充包解压内容、OBJ 面数、Blender 源元数据；`catalog.tsv` 便于快速查看。`download_plan.json` 保留 Poly Haven 下载前的官方预期字节和 MD5。这里的 Python 工具均为本次本地编写，未运行下载内容中的任何脚本。

## 排除项

[3TD Conifer Forest Pack](https://opengameart.org/content/3td-conifer-forest-pack-v11) 虽标 CC0，页面现明确显示文件因贴图许可争议而不可用，未下载、未计数。相关页面已保存证据。另一份 3TD Starter Pack 虽能看到下载链接，但同系列争议尚未能核实清楚，本批也未采用。

## 已调查但未下载的成年树

| 官方资源 | 官方目录面数 | 2K glTF 与依赖总大小 | 未直接采用原因 |
| --- | ---: | ---: | --- |
| [Pine Tree 01](https://polyhaven.com/a/pine_tree_01) | 17,427,094 | 982,149,009 字节 | 面数与几何体积过大，更适合离线源模型/烘焙素材 |
| [Fir Tree 01](https://polyhaven.com/a/fir_tree_01) | 7,853,731 | 510,242,724 字节 | 需要系统性降面、叶片卡和远景 LOD 制作 |

两者官方文件清单分别保留为 `evidence/pine_tree_01_candidate_files.json` 与 `evidence/fir_tree_01_candidate_files.json`，不计入“已下载资源”。

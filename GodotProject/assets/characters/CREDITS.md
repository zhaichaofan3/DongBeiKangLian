# 人物模型来源

头部、眉眼、双手基础：Quaternius，Universal Base Characters Standard，CC0 1.0。
作者页面：https://quaternius.itch.io/universal-base-characters
许可：https://creativecommons.org/publicdomain/zero/1.0/

使用已下载的 Superhero_Male_FullBody.gltf 及配套眼睛、头脸和手部贴图。重新裁接和塑造头颈，制作普通手与守卫握持手；棉衣、裤子、绑腿、靴子、帽子、钢盔、背包、皮带和布料纹理由本项目制作。未复用基础资源的现代服装，也未导入其骨架动作。

运行模型 field_character.glb 使用13骨游戏骨架，现有游戏动作驱动连续蒙皮；持枪使用双臂解算。原始工作文件保存在 AssetLibrary/characters/field_character/field_character.blend，可在 Blender 继续编辑。精确网格统计与SHA-256见 provenance.json。

2026-10-15按用户要求增加日军专用头盔红圈与八字胡，几何由本项目制作，绑定原Head骨。新增448个三角面；其他角色与开场友军隐藏。可编辑生成源为tools/guard_identity_geometry.py。

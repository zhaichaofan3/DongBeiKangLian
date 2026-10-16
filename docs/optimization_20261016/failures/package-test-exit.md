# 独立包首关检查退出提示

首次独立包`first_level_rebuild.gd`的125项功能断言通过，进程返回0。引擎关闭日志文件后，终端另出现以下提示，因此不能仅以run.log无ERROR断言整个退出过程没有提示。

```text
FIRST LEVEL REBUILD: PASS | checks=125
WARNING: 4 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
ERROR: 2 resources still in use at exit (run with --verbose for details).
   at: clear (core/io/resource.cpp:822)
```

后续首关源码详细退出重测125项通过，完整日志`../source-first-level-exit.log`无释放提示。新包快速枪械测试也在51项通过后出现同类提示，原始控制台输出保留于`package-visual-motion-exit.log`；两帧延迟与延后调用quit均未解决，而详细输出改变运行速度后未复现。首关包125项也复现，完整失败输出保留于`package-first-level-exit.log`。

两项测试清理现沿用实战测试的150ms真实时间等待，让场景删除后音频混音线程有时间释放播放资源；功能断言及游戏代码未为此改动。源码及新包复测均通过，新包9组完整控制台退出无ERROR，最终输出见`../release/visual_motion.log`和`../release/first_level_rebuild.log`。未将早先退出错误算作通过。根因判断为测试快速退出的异步释放时序，未取得泄漏对象名称，故不声称已定位到具体资源。

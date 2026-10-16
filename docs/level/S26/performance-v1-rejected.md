# 性能首次采样无效

performance-v1.log 存在测试脚本访问已释放实例的 SCRIPT ERROR。尽管脚本输出 PASS，本次 measurement_valid 不被验收采用。原因在测试自建效果数组；改为实际 mission.guard_shot 入口及其回收逻辑后重新采样。

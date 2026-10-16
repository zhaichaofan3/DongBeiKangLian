# cctq.ai / CC Switch 连接排查与恢复

日期：2026-10-12，时间均为北京时间（Asia/Shanghai）。

## 本轮结论

两次中断都发生在 `POST https://www.cctq.ai/v1/responses`，返回 HTTP 502 Bad Gateway。它表示网关没有拿到可用的上游响应；仅凭 502 不能确认是平台源站、上游模型通道、负载还是代理超时。Cloudflare 的 NRT Ray 标识也不能单独证明 Cloudflare 自身故障。

本轮实际请求已成功，属于**当前恢复可用，间歇故障根因仍需 cctq.ai 查服务端日志**。没有证据表明游戏工程导致 502。游戏可以离线运行。

## 已核实的配置

| 项目 | 实际值与含义 |
|---|---|
| 用户访问的网站 | `https://www.cctq.ai/dashboard/overview` 是管理页面，不能填进 API Base URL |
| Codex 生效文件 | `C:\Users\Administrator\.codex\config.toml` |
| API 根地址 | `https://www.cctq.ai/v1`，当前正确；客户端自动追加 `/responses` |
| 协议 | `wire_api = "responses"`，当前正确 |
| 文件中的模型/推理档位 | `gpt-6-astra` / `ultra`；聊天界面的单次选择可能另有覆盖 |
| CC Switch 当前供应商 | `CCRTQ`，也是同一个正确的 API 根地址 |
| CC Switch 代理状态 | Codex 的 `proxy_enabled`、`enabled`、`live_takeover_active` 均为 0 |
| CC Switch 自动切换 | `auto_failover_enabled = 0`；当前没有接管请求或自动备用线路 |
| CC Switch 保存的默认模型 | `gpt-5.6-sol` / `high`，与 Codex 当前文件不同；重新应用该配置可能覆盖模型选择 |
| 未启用配置 `CCTQ0.3` | `base_url` 错填为整段连接 JSON，不能作为备用项直接启用；不是本次正在使用的配置 |

这条链路是 **CC Switch 写配置 → Codex 直接请求 cctq.ai → 平台上游通道**。不能把 CC Switch 数据库中同步的历史 200 请求记录当成其代理正在工作，也不能把它的 60/120 秒代理超时设置当成本次请求的实际超时。

## 实际探测证据

沿用本机已有凭据，只向已配置的 cctq.ai 发送请求，没有向其他服务发送凭据，也未在报告中保存密钥、完整配置或模型正文。

| 北京时间 | 请求 | 结果 |
|---|---|---|
| 约 12:13 前后记录的第一次故障 | `/v1/responses` | 502，Ray `a493397fc8041323-NRT` |
| 约 12:56 前后记录的第二次故障 | `/v1/responses` | 502，Ray `a49392660bb5a5d6-NRT` |
| 13:16:16 开始 | GET `/v1/models` | 200，约 6.7 秒，列表含 `gpt-6-astra` |
| 13:16:23 开始 | POST `/v1/responses` | 200，约 7.8 秒，收到文本增量及 `response.completed`；Ray `a493a1f59b99d4c7-NRT` |
| 13:23:35 开始，验证复查工具 | POST `/v1/responses` | 200，约 8.5 秒，完整结束；Ray `a493ac848c7a99e9-NRT`；[原始脱敏报告](connection-latest.json) |
| 15:55:27 开始，复查工具 | POST `/v1/responses` | HTTP 200、SSE 已建立但约 20 秒内未收到 `response.completed`，随后超时；Ray `a4948b014d2f2624-NRT`；[原始脱敏报告](connection-latest.json) |

短流测试使用 `gpt-6-astra`、`reasoning.effort=low`、极短提示、输出上限 256。成功记录证明当前凭据和 Responses 基础链路曾可用；15:55 的 200/未完成记录说明网关仍有间歇性上游流停顿，**不等于复现了长上下文、ultra 推理、多工具或高并发请求的稳定性**。两次历史故障时间仅来自用户提供的聊天记录，不是精确服务端时间。

## 解决方案（按优先级）

1. **优先请 cctq.ai 查通道。** 把错误路径、北京时间、上面两个失败 Ray ID，以及“短流成功、持续开发间歇 502”的现象交给平台客服。请其查对应请求的上游状态、首包时间、网关超时和通道容量，并确认该模型支持 Codex 使用的 Responses 流式与工具调用。这里已准备材料，没有代发消息。
2. **在 CC Switch 核对配置。** Codex → 当前供应商 `CCRTQ` → 编辑：根地址保持 `https://www.cctq.ai/v1`、协议保持 `responses`，密钥放密钥字段。未启用的 `CCTQ0.3` 应先把错误 JSON 地址改成上述根地址，并核对密钥字段后才能测试/启用。不要填 dashboard 地址、重复的 `/v1/v1` 或完整的 `/v1/responses`。重新应用供应商前核对保存的模型，避免覆盖现有选择。
3. **短暂波动用有限重试。** Codex 默认 HTTP 重试 4 次、流中断重试 5 次、SSE 空闲超时 300000 毫秒。可在当前供应商的同一配置节内把 `request_max_retries` 调为 6；这只能容忍短故障，不能修复持续 502，也不应堆叠多层大量重试。客户端等待更久无法延长服务商自己的网关超时。
4. **长请求仍失败时做单变量比较。** 保留当前模型，临时比较 `high` 与 `ultra` 的成功率/首包时间；降低推理档位可能缩短处理时间，但本轮没有证据证明 ultra 就是根因。日常开发按可恢复的小批次保存进度。本次没有擅自更换模型或推理档位。
5. **需要可靠备用时使用独立通道。** 先用自己有访问权限的另一供应商/官方配置验证完整 Responses 工具调用，再考虑 CC Switch 的代理接管与自动切换。当前这两项都是关闭的，不能声称已经自动容灾；复制两份同域名配置也不构成独立备用。尚未验证现有 `OpenAI Official` 条目的可用性。

如决定使用第 3 项，在**已有的** `[model_providers.custom]` 节里添加/修改，不能重复创建同名节；若由 CC Switch 管理，应同步保存到其供应商配置，否则下一次切换可能覆盖：

```toml
request_max_retries = 6
stream_max_retries = 5
stream_idle_timeout_ms = 300000
```

本轮没有修改全局配置、CC Switch 数据库、密钥、模型或系统代理。故障已暂时恢复，继续游戏开发不依赖更换这些配置。

## 本地复查工具

在 `C:\GameMake` 执行（Python 3.11+，仅标准库）：

```powershell
# 只读检查；不联网、不计费、不输出密钥。
python .\tools\diagnose_model_connection.py

# 主动发送一次极短的模型流式请求，可能产生少量 API 费用。
python .\tools\diagnose_model_connection.py --probe --output .\docs\connection-latest.json
```

工具读取当前配置，不自动切换线路；网络超时/HTTP 错误、返回 200 但没有 `response.completed` 均会失败退出。输出仅含允许的元数据，错误的 JSON 地址不会原样写入报告。13:18 的只读快照见 [配置状态](connection-state-2026-10-12.json)。

## 游戏工作恢复

中断前的 0.3 视觉代码已保存，原 Release 仍是 0.2。本轮继续整合画质和模型动画、修复渡口遮挡与地表穿插、补入动作回归测试，并重新验证/打包。最终结果见 [游戏验证记录](../GodotProject/VERIFICATION.md)。测试与截图使用独立存档，打包先完成临时资源包再替换正式包。

参考本轮实际读取的 [OpenAI Docs：Codex 配置参考](https://developers.openai.com/codex/config-reference/) 和 [API 错误说明](https://developers.openai.com/api/docs/guides/error-codes)。它们支持重试参数及服务端故障处理原则，不能确认第三方网关的内部根因。

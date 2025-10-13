# 钉钉自定义机器人群消息 `send` 接口调用指南

- 来源文档：自定义机器人发送群消息（更新于 2025-06-24）、自定义机器人发送消息的消息类型（更新于 2025-06-05）。
- 适用范围：企业内部群与普通群内的自定义机器人。

## 调用频率限制

- 单个机器人每分钟最多向群里发送 20 条消息。
- 超限后会被限流 10 分钟，限流期间请求直接失败。
- 对于高频场景（如监控告警），官方建议整合信息，通过 markdown 摘要发送。

## 权限与安全要求

- 服务端 API 按应用维度授权，企业内部应用和第三方企业应用默认具备调用权限；第三方个人应用不支持。
- 调用使用机器人安装后分配的 webhook 中的 `access_token`，无需额外的应用 access_token。
- 如果机器人开启“加签”安全规则，请在请求 URL 追加 `timestamp`（当前毫秒级时间戳）与 `sign`（指定算法计算的签名）参数：  
  `https://oapi.dingtalk.com/robot/send?access_token=XXX&timestamp=XXX&sign=XXX`
- 若配置“关键词”或“IP 白名单”等安全策略，消息体需包含关键词且请求来源 IP 必须在白名单中。

## 请求说明

- 方法：`POST`
- URL：`https://oapi.dingtalk.com/robot/send`
- 建议请求头：`Content-Type: application/json;charset=utf-8`
- Query 参数：
  - `access_token`（必填）：Webhook 地址中的凭证。
  - 当安全加签开启时需额外拼接 `timestamp`、`sign`。

### 请求体结构

- `msgtype`（String，必填）：消息类型，取值见下方。
- `at`（Object，可选）：用于 @ 成员。
  - `atMobiles`（String 数组，可选）：被 @ 成员手机号；正文需包含 `@手机号` 文案，非群成员会被脱敏。
  - `atUserIds`（String 数组，可选）：被 @ 成员的 userId；正文需出现 `@userId`。
  - `isAtAll`（Boolean，可选）：`true` 表示 @ 所有人。
- 其余字段根据 `msgtype` 填写。

### 消息类型明细

| 类型 | 是否支持 @ 人 | 关键字段 | 说明 |
| --- | --- | --- | --- |
| `text` 文本 | ✅ | `text.content` | 纯文本消息，支持 @ 功能。 |
| `link` 链接 | ❌ | `link.title`、`link.text`、`link.messageUrl`、`link.picUrl`(可选) | 点击跳转到指定链接，移动端内置打开，PC 侧默认侧边栏，若需外部浏览器需按“消息链接说明”配置。 |
| `markdown` | ✅ | `markdown.title`、`markdown.text` | 支持 Markdown 子集（标题、引用、加粗、斜体、链接、图片等），正文可插入 @ 信息。图片建议不超过 20 张。 |
| `actionCard` 整体跳转 | ✅ | `actionCard.title`、`actionCard.text`、`actionCard.singleTitle`、`actionCard.singleURL`、`actionCard.btnOrientation`(可选) | 单按钮跳转卡片，`btnOrientation` 为 `0`（竖排）或 `1`（横排）。 |
| `actionCard` 独立跳转 | ✅ | `actionCard.title`、`actionCard.text`、`actionCard.btns`（数组，包含 `title`、`actionURL`）、`actionCard.btnOrientation`(可选) | 多按钮卡片，每个按钮可配置独立跳转链接。 |
| `feedCard` | ❌ | `feedCard.links`（数组，每项含 `title`、`messageURL`、`picURL`） | 多条图文摘要，适合信息流展示。 |

> 发送链路需确保 Markdown、ActionCard 文本中包含被 @ 成员的 userId，否则 @ 不生效。

## 响应与错误处理

- 成功返回 JSON：`{"errcode":0,"errmsg":"ok"}`。
- 常见错误码：
  - `40035`：缺少消息 JSON；检查请求体是否为合法 JSON 且 `Content-Type` 为 `application/json`。
  - `43004`：`Content-Type` 非法；确保使用 `application/json`。
  - `400101`：`access_token` 不存在；确认 webhook 是否正确。
  - `400102`：机器人已停用；联系群管理员启用。
  - `400105`：消息类型不受支持；核对 `msgtype`。
  - `410100`：发送过快被限流；降低发送频率。
  - `400013`：群已解散；改用其他群。
  - `430101` ~ `430104`：内容违规（外链/文本/图片/其他）；核查消息合规性。
- 安全校验失败 `310000`：
  - 关键词缺失、timestamp 无效、签名不匹配或来源 IP 不在白名单。需逐项排查对应安全设置。

## 实施建议

- 通用流程：获取 webhook → 准备消息体 JSON → 计算并附加安全参数（如需）→ `POST` 发送 → 根据返回码重试或告警。
- 建议在代码中对 `errcode` 进行集中处理，区分重试型（如 `-1`、`410100`）与配置型错误（如 `400101`、`430101`）。
- 对高并发场景加入队列或限速器，防止命中 20 条/分钟限制。
- Markdown 内容需严格遵守支持的语法子集，超出部分会被过滤。


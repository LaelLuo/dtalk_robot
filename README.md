# dtalk_robot

`dtalk_robot` 是一个轻量级 Dart 封装，帮助你使用钉钉自定义机器人向群聊发送消息。它内置签名计算、请求发送逻辑，并提供面向对象的消息体构造能力，让你可以专注在业务内容本身。

## 特性
- 支持钉钉官方文档中的全部消息类型：`text`、`markdown`、`link`、`actionCard`（整体跳转与独立跳转）、`feedCard`
- 统一的 `DTalkMessage` 抽象，保证消息字段校验、JSON 构造逻辑一致
- 对 `text`、`markdown`、`actionCard` 等支持 @ 成员的消息类型提供 `DTalkAt` 配置
- 内置签名计算与 HTTP 调用，只需提供 `token`、`secret` 即可发送

更多使用细节可参考项目文档 `docs/dingtalk_custom_robot_send.md`。

## 安装
在你的 `pubspec.yaml` 中加入依赖：
```yaml
dependencies:
  dtalk_robot:
    git:
      url: https://github.com/LaelLuo/dtalk_robot.git
```

## 快速开始
```dart
import 'package:dtalk_robot/dtalk_robot.dart';

Future<void> main() async {
  final robot = DTalk(token: 'your_token', secret: 'your_secret');
  await robot.sendText('系统已部署完成 ✅');
}
```

## 消息类型示例
### 文本消息（支持 @ 成员）
```dart
await robot.sendText(
  '上线完成 @18800001111',
  at: const DTalkAt(mobiles: ['18800001111']),
);
```

### Markdown
```dart
await robot.sendMessage(
  DTalkMarkdownMessage(
    title: '部署报告',
    text: '''
## ✅ 成功
- 版本: v1.2.0
- 时间: 2025-10-13 10:30
''',
    at: const DTalkAt(isAtAll: true),
  ),
);
```

### Link
```dart
await robot.sendMessage(
  DTalkLinkMessage(
    title: '查看部署日志',
    text: '点击可查看本次部署的详细执行记录',
    messageUrl: 'https://example.com/logs/123',
    picUrl: 'https://example.com/static/log-icon.png',
  ),
);
```

### ActionCard（整体跳转）
```dart
await robot.sendMessage(
  DTalkActionCardMessage.single(
    title: '服务异常告警',
    text: '### 服务异常\n> CPU 使用率持续超过 90%',
    singleTitle: '立即处理',
    singleUrl: 'https://example.com/alert/456',
  ),
);
```

### ActionCard（独立跳转）
```dart
await robot.sendMessage(
  DTalkActionCardMessage.multi(
    title: '选择处理方式',
    text: '请根据需要执行操作：',
    buttons: const [
      DTalkActionCardButton(
        title: '查看监控',
        actionUrl: 'https://example.com/dashboard',
      ),
      DTalkActionCardButton(
        title: '创建工单',
        actionUrl: 'https://example.com/ticket/new',
      ),
    ],
    at: const DTalkAt(isAtAll: true),
  ),
);
```

### FeedCard
```dart
await robot.sendMessage(
  DTalkFeedCardMessage(
    links: const [
      DTalkFeedCardLink(
        title: '巡检日报',
        messageUrl: 'https://example.com/report/1',
        picUrl: 'https://example.com/static/report-1.png',
      ),
      DTalkFeedCardLink(
        title: '巡检周报',
        messageUrl: 'https://example.com/report/7',
        picUrl: 'https://example.com/static/report-7.png',
      ),
    ],
  ),
);
```

## 示例
完整示例位于 `example/dtalk_robot_example.dart`，可直接运行体验。

## 参考
- 钉钉官方文档：自定义机器人发送消息类型与调用规范
- 本仓库文档：`docs/dingtalk_custom_robot_send.md`
